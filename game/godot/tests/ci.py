#!/usr/bin/env python3
"""Run actual Godot processes. Errors, missing completion and timeouts fail CI."""
import json, os, pathlib, re, subprocess, time
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = pathlib.Path(os.environ.get('UCMAK_REPORTS', str(ROOT / 'test-results'))).resolve()
OUT.mkdir(parents=True, exist_ok=True)
GODOT = os.environ.get('GODOT', 'godot')
FORBIDDEN = ('ERROR:', 'above the MTU', 'Parse Error:', 'FAIL_UI ', 'NET_FAIL', 'NET_HOST_FAIL', 'FAIL ')
VIEWPORTS = [('portrait','480x960'), ('landscape','1200x800'), ('compact','360x640'), ('phone-wide','844x390')]

def run(name, args, seconds=90):
    result = subprocess.run(args, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=seconds)
    (OUT / (name + '.log')).write_text(result.stdout, encoding='utf-8')
    print(result.stdout, flush=True)
    if result.returncode or any(s in result.stdout for s in FORBIDDEN):
        raise RuntimeError(f'{name} failed, exit={result.returncode}')
    return result.stdout

def network():
    processes, handles = [], []
    try:
        for i in range(4):
            handle = (OUT / f'network-{i}.log').open('w', encoding='utf-8'); handles.append(handle)
            args = [GODOT, '--headless', '--path', str(ROOT), '--', '--test-host' if i == 0 else '--test-client', '--port=24649']
            processes.append(subprocess.Popen(args, stdout=handle, stderr=subprocess.STDOUT, cwd=ROOT))
            if i == 0: time.sleep(2)
        for proc in processes: proc.wait(timeout=40)
        for i, proc in enumerate(processes):
            handles[i].flush()
            log = (OUT / f'network-{i}.log').read_text()
            print(log, flush=True)
            expected = 'NET_HOST_PASS' if i == 0 else 'NET_CLIENT_PASS'
            if proc.returncode or expected not in log or any(s in log for s in FORBIDDEN):
                raise RuntimeError(f'network peer {i} failed: {proc.returncode}')
    finally:
        for proc in processes:
            if proc.poll() is None: proc.kill()
            proc.wait()
        for handle in handles: handle.close()

def main():
    run('import', [GODOT,'--headless','--editor','--path',str(ROOT),'--quit'], 90)
    core = run('core', [GODOT,'--headless','--path',str(ROOT),'--script','res://tests/core_test.gd'], 120)
    match = re.search(r'CORE_RESULT passed=(\d+) failed=(\d+)', core)
    if not match or int(match[2]): raise RuntimeError('Core test completion not observed')
    network()
    startup_results = {}
    for label, size in VIEWPORTS:
        start = run('start-'+label, ['xvfb-run','-a',GODOT,'--audio-driver','Dummy','--path',str(ROOT),'--resolution',size,'--','--startup-test'] + (['--mobile-lod'] if label in ('compact','phone-wide') else []), 45)
        probe = re.search(r'STARTUP_RESULT passed=(\d+) failed=(\d+)', start)
        if not probe or int(probe[2]): raise RuntimeError('Training start did not finish')
        startup_results[size] = int(probe[1])
    ui_results = {}
    for label, size in VIEWPORTS:
        log = run('ui-'+label, ['xvfb-run','-a',GODOT,'--audio-driver','Dummy','--path',str(ROOT),'--resolution',size,'--','--ui-test'], 90)
        ui = re.search(r'UI_RESULT passed=(\d+) failed=(\d+)', log)
        if not ui or int(ui[2]): raise RuntimeError('UI test completion not observed')
        ui_results[size] = int(ui[1])
        capture = str(OUT / (label + '.png'))
        run('visual-'+label, ['xvfb-run','-a',GODOT,'--audio-driver','Dummy','--path',str(ROOT),'--resolution',size,'--','--visual-test','--capture='+capture] + (['--mobile-lod'] if label in ('compact','phone-wide') else []), 90)
        if pathlib.Path(capture).stat().st_size < 1000: raise RuntimeError('Empty screenshot')
    summary = {'commit':os.environ.get('GITHUB_SHA'), 'core_passed':int(match[1]), 'core_failed':int(match[2]), 'enet_peers':4, 'ui_passed':ui_results, 'startup_passed':startup_results, 'native_phone':False, 'gpu':'CI software renderer', 'internet_matchmaking':False}
    (OUT/'acceptance.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    print('ACCEPTANCE_PASS: '+json.dumps(summary),flush=True)
if __name__ == '__main__': main()

#!/usr/bin/env python3
"""Run the actual Godot binary; every error and every timeout is a failing gate."""
import argparse, json, os, pathlib, subprocess, time
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = pathlib.Path(os.environ.get('UCMAK_REPORTS', str(ROOT / 'test-results'))).resolve()
OUT.mkdir(parents=True, exist_ok=True)
GODOT = os.environ.get('GODOT', 'godot')
FORBIDDEN = ('ERROR:', 'above the MTU', 'Parse Error:', 'FAIL_UI ', 'NET_FAIL', 'NET_HOST_FAIL', 'FAIL ')

def run(name, args, seconds=90):
    result = subprocess.run(args, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=seconds)
    (OUT / (name + '.log')).write_text(result.stdout, encoding='utf-8')
    print(result.stdout)
    if result.returncode or any(s in result.stdout for s in FORBIDDEN):
        raise RuntimeError(f'{name} failed, exit={result.returncode}')
    return result.stdout

def network():
    processes = []
    handles = []
    try:
        for i in range(4):
            path = OUT / f'network-{i}.log'
            handle = path.open('w', encoding='utf-8'); handles.append(handle)
            args = [GODOT, '--headless', '--path', str(ROOT), '--', '--test-host' if i == 0 else '--test-client', '--port=24649']
            processes.append(subprocess.Popen(args, stdout=handle, stderr=subprocess.STDOUT, cwd=ROOT))
            if i == 0: time.sleep(2)
        for proc in processes:
            proc.wait(timeout=40)
        for i, proc in enumerate(processes):
            handles[i].flush()
            log = (OUT / f'network-{i}.log').read_text()
            print(log)
            expected = 'NET_HOST_PASS' if i == 0 else 'NET_CLIENT_PASS'
            if proc.returncode or expected not in log or any(s in log for s in FORBIDDEN):
                raise RuntimeError(f'network peer {i} failed: {proc.returncode}')
    finally:
        for proc in processes:
            if proc.poll() is None: proc.kill()
        for handle in handles: handle.close()

def main():
    run('import', [GODOT,'--headless','--editor','--path',str(ROOT),'--quit'], 90)
    core = run('core', [GODOT,'--headless','--path',str(ROOT),'--script','res://tests/core_test.gd'], 120)
    if 'CORE_RESULT' not in core: raise RuntimeError('Core test completion not observed')
    network()
    for label, size in [('portrait','480x960'),('landscape','1200x800')]:
        log = run('ui-'+label, ['xvfb-run','-a',GODOT,'--audio-driver','Dummy','--path',str(ROOT),'--resolution',size,'--','--ui-test'], 90)
        if 'UI_RESULT' not in log: raise RuntimeError('UI test completion not observed')
        capture = str(OUT / (label + '.png'))
        run('visual-'+label, ['xvfb-run','-a',GODOT,'--audio-driver','Dummy','--path',str(ROOT),'--resolution',size,'--','--visual-test','--capture='+capture], 90)
        if pathlib.Path(capture).stat().st_size < 1000: raise RuntimeError('Empty screenshot')
    (OUT/'acceptance.json').write_text(json.dumps({'core':True,'enet_peers':4,'ui_viewports':['480x960','1200x800'],'native_phone':False,'gpu':'CI software renderer'},indent=2))
    print('ACCEPTANCE_PASS: core, four ENet peers, UI, screenshots')
if __name__ == '__main__': main()

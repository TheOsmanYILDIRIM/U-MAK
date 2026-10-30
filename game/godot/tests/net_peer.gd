extends Node
var elapsed=0.0
var sent=false
var acknowledged=false
var host_mode=false
var port=24649
var start_at=-1.0
var checked=false
func _ready():
    var args=OS.get_cmdline_user_args()
    host_mode=args.has("--test-host")
    for arg in args:
        if arg.begins_with("--port="): port=int(arg.trim_prefix("--port="))
    var err=Session.host(port) if host_mode else Session.join("127.0.0.1",port)
    if err!=OK: printerr("NET_FAIL cannot open peer ",err); get_tree().quit(1)
func _process(dt):
    elapsed+=dt
    if elapsed>28: printerr("NET_FAIL timeout ",Session.phase); get_tree().quit(1); return
    if host_mode:
        if Session.phase=="lobby" and Session.players.size()==4:
            Session.start_match(); start_at=elapsed
        if start_at>0 and elapsed-start_at>9 and not checked:
            checked=true
            var ok=Session.receipts.size()==3 and Session.battle.metrics.orders>=3 and Session.battle.metrics.rejected>=3 and Session.max_chunk>0 and Session.max_chunk<=900
            for p in Session.receipts: ok=ok and bool(Session.receipts[p].get("safe",false))
            Session.battle.winner=0
            ok=ok and not Session.send({"type":"hold","wings":[0]})
            print("NET_HOST_", "PASS" if ok else "FAIL", " peers=",Session.players.size()," receipts=",Session.receipts.size()," accepted=",Session.battle.metrics.orders," rejected=",Session.battle.metrics.rejected," max_chunk=",Session.max_chunk)
            get_tree().quit(0 if ok else 1)
    else:
        if Session.phase=="battle" and not Session.view.is_empty():
            if start_at<0: start_at=elapsed
            if not sent and Session.view.tick>5 and not Session.owned.is_empty():
                sent=true
                Session.send({"type":"hold","wings":[Session.owned[0]]})
                # Deliberate unauthorized intent: server must reject, never execute.
                Session._command.rpc_id(1,{"type":"hold","wings":[0 if Session.team==1 else 3]},Session.match_id)
            if sent and not acknowledged and elapsed-start_at>3:
                acknowledged=true
                var safe=Session.view.units.all(func(u):return u.team==Session.team or not u.has("xp"))
                safe=safe and Session.view.wings.all(func(w):return w.team==Session.team)
                Session._test_receipt.rpc_id(1,{"safe":safe,"tick":Session.view.tick,"owned":Session.owned})
                print("NET_CLIENT_PASS team=",Session.team," tick=",Session.view.tick," owned=",Session.owned," safe=",safe)
        if acknowledged and Session.phase=="menu": get_tree().quit(0)

extends Node
## ENet authority. Clients submit intents, never positions, damage or resource totals.
signal changed
signal notice(text: String)
const Battle = preload("res://core/battle.gd")
const Wire = preload("res://core/wire.gd")
const PORT = 24642
const PROTOCOL = 6
var battle = Battle.new()
var view: Dictionary={}
var players: Dictionary={}
var mode="idle"
var phase="menu"
var team=0
var seat=0
var owned: Array=[0,1,2]
var accumulator=0.0
var broadcast_timer=0.0
var paused=false
var last_tick=-1
var match_id=0
var rates: Dictionary={}
var receipts: Dictionary={}
var last_error=""
var wire=Wire.new()
var max_chunk=0

func _ready():
    multiplayer.peer_connected.connect(_peer_connected)
    multiplayer.peer_disconnected.connect(_peer_disconnected)
    multiplayer.connected_to_server.connect(_connected)
    multiplayer.connection_failed.connect(_failed)
    multiplayer.server_disconnected.connect(_server_left)

func stop():
    if multiplayer.multiplayer_peer: multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
    mode="idle"; phase="menu"; paused=false; view={}; players={}; rates={}; receipts={}
    accumulator=0; last_tick=-1; wire.clear(); max_chunk=0
    changed.emit()

func offline():
    stop(); mode="local"; phase="battle"; team=0; seat=0; owned=[0,1,2]
    battle.reset(); battle.ai_teams=[1]; match_id+=1
    view=battle.snapshot(0)
    changed.emit()

func host(port:int=PORT) -> Error:
    stop()
    var peer=ENetMultiplayerPeer.new()
    var error=peer.create_server(port,3)
    if error!=OK:
        last_error="Oda açılamadı; bağlantı noktası kullanılıyor olabilir."; notice.emit(last_error)
        return error
    multiplayer.multiplayer_peer=peer
    mode="host"; phase="lobby"; players={1:0}; team=0; seat=0
    changed.emit()
    return OK

func join(address:String,port:int=PORT) -> Error:
    stop()
    var peer=ENetMultiplayerPeer.new()
    var error=peer.create_client(address.strip_edges(),port)
    if error!=OK: notice.emit("Sunucu adresi geçersiz."); return error
    multiplayer.multiplayer_peer=peer
    mode="client"; phase="connecting"
    changed.emit()
    return OK

func _connected():
    _hello.rpc_id(1,PROTOCOL)

func _peer_connected(_id:int):
    pass # Team ownership is assigned by the host, never supplied by a client.

@rpc("any_peer","call_remote","reliable")
func _hello(protocol:int):
    if mode!="host": return
    var sender=multiplayer.get_remote_sender_id()
    if phase!="lobby" or protocol!=PROTOCOL or players.size()>=4:
        _refused.rpc_id(sender,"Maç başladı, oda dolu veya sürüm uyumsuz.")
        return
    if not players.has(sender):
        for s in range(4):
            if not s in players.values(): players[sender]=s; break
    _lobby.rpc(players)
    changed.emit()

@rpc("authority","call_remote","reliable")
func _lobby(roster:Dictionary):
    players=roster
    seat=int(players.get(multiplayer.get_unique_id(),0)); team=seat%2
    phase="lobby"
    changed.emit()

@rpc("authority","call_remote","reliable")
func _refused(reason:String):
    last_error=reason; stop(); notice.emit(reason)

func _peer_disconnected(id:int):
    if mode!="host": return
    var old_seat=int(players.get(id,-1))
    players.erase(id); rates.erase(id)
    if phase=="lobby": _lobby.rpc(players)
    elif phase=="battle" and old_seat>=0:
        var t=old_seat%2
        var remains=players.values().any(func(s): return int(s)%2==t)
        if not remains and not t in battle.ai_teams: battle.ai_teams.append(t)
        battle.log_message(t,"BAĞLANTI","Komutan ayrıldı. Kalan müttefik veya AI komutayı devraldı.")
    changed.emit()

func _failed():
    stop(); last_error="Bağlantı kurulamadı. Aynı Wi-Fi / erişilebilir sunucu ve UDP 24642 gerekli."
    notice.emit(last_error)

func _server_left():
    stop(); last_error="Ev sahibi bağlantısı kesildi. Maç sonlandırıldı."
    notice.emit(last_error)

func ownership(peer_id:int) -> Array:
    if mode=="local": return [0,1,2]
    if not players.has(peer_id): return []
    var s=int(players[peer_id])
    var t=s%2
    var allied: Array=[]
    for p in players:
        if int(players[p])%2==t: allied.append(int(players[p]))
    allied.sort()
    if allied.size()==1: return [t*3,t*3+1,t*3+2]
    return [t*3,t*3+1] if s==allied[0] else [t*3+2]

func start_match() -> bool:
    if mode!="host" or phase!="lobby" or players.size()<2: return false
    battle.reset(); battle.ai_teams=[]; match_id+=1
    accumulator=0; broadcast_timer=0; phase="battle"; last_tick=-1
    team=0; owned=ownership(1)
    _started.rpc(match_id)
    view=battle.snapshot(team)
    changed.emit()
    return true

@rpc("authority","call_remote","reliable")
func _started(id:int):
    match_id=id; phase="battle"; last_tick=-1; view={}
    changed.emit()

func send(order:Dictionary) -> bool:
    if phase!="battle": return false
    if mode!="client" and (battle.winner>=0 or battle.queue.size()>=128): return false
    if mode=="client" and int(view.get("winner",-1))>=0: return false
    if mode=="client":
        _command.rpc_id(1,order,match_id)
        return true
    var accepted=battle.submit(order,ownership(1))
    if not accepted: notice.emit(battle.last_rejection)
    return accepted

@rpc("any_peer","call_remote","reliable")
func _command(order:Dictionary,id:int):
    if mode!="host" or phase!="battle" or id!=match_id or battle.winner>=0 or battle.queue.size()>=128: return
    var sender=multiplayer.get_remote_sender_id()
    if not players.has(sender): return
    var now=Time.get_ticks_msec()
    var rate=rates.get(sender,{"at":now,"n":0})
    if now-int(rate.at)>1000: rate={"at":now,"n":0}
    rate.n+=1; rates[sender]=rate
    if rate.n>20 or var_to_bytes(order).size()>4096: return
    var accepted=battle.submit(order,ownership(sender))
    if not accepted: _order_error.rpc_id(sender,battle.last_rejection)

@rpc("authority","call_remote","reliable")
func _order_error(reason:String):
    notice.emit(reason)

func send_snapshot(peer:int,packet:Dictionary,permissions:Array):
    var parts=Wire.pack(packet,permissions)
    for i in range(parts.size()):
        max_chunk=maxi(max_chunk,parts[i].size())
        _state_chunk.rpc_id(peer,match_id,int(packet.tick),i,parts.size(),parts[i])

@rpc("authority","call_remote","unreliable",1)
func _state_chunk(id:int,sequence:int,index:int,total:int,chunk:PackedByteArray):
    if id!=match_id or phase!="battle" or sequence<=last_tick: return
    var message=wire.consume(sequence,index,total,chunk)
    if message.is_empty(): return
    last_tick=sequence; owned=message.owned; view=message.state
    changed.emit()

func _process(delta:float):
    if not mode in ["local","host"] or phase!="battle": return
    if mode=="local" and paused: return
    accumulator+=minf(delta,0.25)
    while accumulator>=0.05:
        battle.step(0.05); accumulator-=0.05
    broadcast_timer+=delta
    if broadcast_timer>=0.1:
        broadcast_timer=0
        owned=ownership(1)
        view=battle.snapshot(team)
        if mode=="host":
            for p in players:
                if p!=1: send_snapshot(p,battle.snapshot(int(players[p])%2),ownership(p))
        changed.emit()

@rpc("any_peer","call_remote","reliable")
func _test_receipt(value:Dictionary):
    # Diagnostic receipts cannot change simulation. Used by the CI integration harness.
    if mode=="host" and OS.get_cmdline_user_args().has("--test-host"):
        var sender=multiplayer.get_remote_sender_id()
        if players.has(sender): receipts[sender]=value

extends SceneTree
const Battle=preload("res://core/battle.gd")
const Terrain=preload("res://core/terrain.gd")
const Wire=preload("res://core/wire.gd")
var passed=0
var failed=0
func check(value:bool,name:String):
    if value: passed+=1; print("PASS ",name)
    else: failed+=1; printerr("FAIL ",name)
func advance(b,seconds:float):
    for i in range(ceili(seconds/0.05)): b.step(0.05)
func _init():
    call_deferred("run")
func run():
    var b=Battle.new(1402); b.ai_teams=[]
    check(b.units.size()==36 and b.wings.size()==6,"36 companies / six wings")
    check(b.units[0].xp.size()==10,"ten independent skills retained")
    check(b.units.all(func(u):return Terrain.walkable(u.pos)),"spawns are walkable")
    var u=b.units[6]; var reserve=b.units[11]; var before=reserve.pos; var old_slot=u.slot
    check(b.submit({"type":"mission","unit":6,"kind":"attack","point":Vector2(880,860)},[0,1,2]),"individual mission accepted")
    advance(b,0.8)
    check(not u.mission.is_empty(),"individual mission is active")
    check(b.wings[1].slots.get(old_slot,-1)==11,"existing reserve fills vacated slot")
    check(reserve.pos.distance_to(before)<50,"reserve walks, never teleports")
    check(b.submit({"type":"line","wings":[1],"points":[Vector2(560,940),Vector2(840,940)]},[0,1,2]),"valid persistent line")
    advance(b,0.8)
    check(not u.mission.is_empty(),"new line preserves special mission")
    b.submit({"type":"return","unit":6},[0,1,2]); advance(b,0.8)
    check(u.mission.is_empty() and b.wings[1].slots.get(old_slot,-1)==11,"return does not evict reserve")
    b.execute({"type":"hold","wings":[1],"seq":999})
    b.execute({"type":"advance","wings":[1],"point":Vector2(700,500),"seq":998})
    check(b.wings[1].mode=="hold","stale plan cannot override newer intent")
    check(not b.submit({"type":"hold","wings":[4]},[0,1,2]),"enemy ownership rejected")
    check(not b.submit({"type":"mission","unit":999,"kind":"attack","point":Vector2(10,10)},[0,1,2]),"invalid company rejected")
    check(not b.submit({"type":"advance","wings":[1],"point":Vector2(NAN,50)},[0,1,2]),"non-finite point rejected")
    check(not b.submit({"type":"line","wings":[1],"points":[Vector2(100,600),Vector2(200,650)]},[0,1,2]),"river line rejected")
    check(Terrain.validate_line([Vector2(400,850),Vector2(600,1050),Vector2(400,1050),Vector2(600,850)])!="","self crossing rejected")
    check(Terrain.validate_line([Vector2(400,850),Vector2(420,850)])!="","short line rejected")
    var path=b.terrain.path(Vector2(500,830),Vector2(500,430))
    var origin=Vector2(500,830); var clear=not path.is_empty()
    for p in path: clear=clear and Terrain.clear(origin,p); origin=p
    check(clear and origin.distance_to(Vector2(500,430))<1,"river routed through a crossing")
    var hidden=Battle.new(42); hidden.ai_teams=[]
    var view=hidden.snapshot(0)
    check(view.units.all(func(x):return x.team==0 or not x.has("xp")),"enemy snapshots never reveal skills")
    check(view.wings.size()==3,"enemy plans are not replicated")
    check(view.units.filter(func(x):return x.team==1).size()<18,"unseen enemy units omitted")
    hidden.units[0].morale=10; hidden.step(0.05)
    check(hidden.units[0].state=="routed","low morale routes a company")
    var med=Battle.new(); med.ai_teams=[]
    med.units[0].pos=Vector2(700,1180); med.units[0].men=70; med.units[0].wounded=10
    med.logistics()
    check(med.units[0].men>70 and med.units[0].wounded<10,"camp treatment preserves personnel accounting")
    med.units[1].pos=Vector2(260,1015); med.units[1].water=10
    med.units[1].mission={"kind":"supply","point":Vector2(260,1015)}
    med.logistics()
    check(med.units[1].water>10,"physical well supplies selected company")
    var a=Battle.new(85); var c=Battle.new(85)
    advance(a,30); advance(c,30)
    check(a.units==c.units and a.control==c.control,"fixed step replay is deterministic for same seed")
    var battle=Battle.new(); battle.ai_teams=[0,1]
    var initial=0.0
    for x in battle.units: initial+=x.men
    var started=Time.get_ticks_msec()
    advance(battle,180)
    var stable=battle.units.all(func(x):return x.pos.is_finite() and x.men>=0 and x.morale>=0 and x.morale<=100 and Terrain.walkable(x.pos))
    check(stable,"three minute simulation stays finite and on walkable terrain")
    check(battle.metrics.hits>0,"AI armies engage in real combat")
    var remaining=0.0
    for x in battle.units: remaining+=x.men
    check(remaining<initial,"combat produces casualties")
    check(battle.metrics.ai>10,"enemy reevaluates plans repeatedly")
    var victory=Battle.new(); victory.ai_teams=[]; victory.control=99.99
    for x in victory.units:
        if x.team==0: x.pos=Vector2(700,605); x.home=x.pos
    victory.step(0.05)
    check(victory.winner==0,"objective control ends match")
    var over=Battle.new(); over.match_limit=0.01; over.step(0.05)
    check(over.winner==2,"time limit resolves a tied match")
    var transport=Wire.new()
    var snap=battle.snapshot(0)
    var chunks=Wire.pack(snap,[0,1,2])
    check(chunks.all(func(part):return part.size()<=900),"snapshot chunks stay below MTU")
    var decoded={}
    for i in range(chunks.size()-1,-1,-1):
        var out=transport.consume(snap.tick,i,chunks.size(),chunks[i])
        if not out.is_empty(): decoded=out
    check(decoded.get("state",{})==snap and decoded.get("owned",[])==[0,1,2],"out of order chunks reassemble exact snapshot")
    check(transport.consume(snap.tick,0,chunks.size(),chunks[0]).is_empty(),"old snapshot is ignored")
    regressions()
    print("CORE_RESULT passed=",passed," failed=",failed," stress_ms=",Time.get_ticks_msec()-started)
    quit(0 if failed==0 else 1)

func regressions():
    var b=Battle.new(); b.ai_teams=[]
    check(not b.submit({"type":"hold","wings":[1,1]},[0,1,2]),"duplicate wing IDs rejected")
    check(not b.submit({"type":"mission","unit":6,"wings":[0],"kind":"attack","point":Vector2(700,900)},[0,1,2]),"mission cannot stamp another wing plan")
    check(b.submit({"type":"hold","wings":[0],"seq":999,"at":-900.0,"damage":999},[0,1,2]),"valid intent canonicalized")
    check(b.queue[0].seq==1 and b.queue[0].at>0 and not b.queue[0].has("damage"),"client authority fields discarded")
    b.reset(); b.ai_teams=[]
    check(b.submit({"type":"advance","wings":[0,1,2],"point":Vector2(850,800)},[0,1,2]),"whole army translation accepted")
    advance(b,0.5)
    check(b.wings[0].goal.is_equal_approx(Vector2(500,800)) and b.wings[1].goal.is_equal_approx(Vector2(850,800)) and b.wings[2].goal.is_equal_approx(Vector2(1200,800)),"whole army keeps lateral spacing rather than stacking")
    b.reset(); b.ai_teams=[]
    b.execute({"type":"advance","wings":[0,1,2],"point":Vector2(1400,1320),"seq":1})
    check(is_equal_approx(b.wings[2].goal.x-b.wings[0].goal.x,700.0) and b.wings[2].goal.x+132<=1364 and b.wings[2].goal.y<=1284,"group boundary clamp preserves formation width")
    b.reset(); b.ai_teams=[]
    b.submit({"type":"mission","unit":6,"kind":"scout","point":Vector2(500,900)},[0,1,2]); advance(b,0.8)
    b.submit({"type":"advance","wings":[0,1,2],"point":Vector2(700,800)},[0,1,2]); advance(b,0.5)
    check(b.units[6].mission.get("kind","")=="scout","army order preserves detached scout mission")
    b.reset(); b.ai_teams=[]
    b.submit({"type":"hold","wings":[1]},[0,1,2]); advance(b,0.3)
    b.submit({"type":"flip","wings":[1]},[0,1,2]); advance(b,0.5)
    check(b.wings[1].pending and b.queue.size()==1,"pending remains while second message is in transit")
    advance(b,0.3)
    check(not b.wings[1].pending,"pending clears only after all messages arrive")
    b.reset(); b.ai_teams=[]
    b.submit({"type":"mission","unit":6,"kind":"move","point":Vector2(700,950)},[0,1,2]); b.units[6].morale=0
    advance(b,0.8)
    check(b.units[6].mission.is_empty() and not b.wings[1].pending,"unexecutable routed-company order does not stick pending")
    b.reset(); b.ai_teams=[]
    check(not b.submit({"type":"mission","unit":0,"kind":"supply","point":Vector2(500,1050)},[0,1,2]) and b.last_rejection.contains("su kaynağı"),"dry supply target rejected with useful reason")
    check(b.submit({"type":"mission","unit":0,"kind":"supply","point":Vector2(260,1015)},[0,1,2]),"well supply target accepted")
    check(b.submit({"type":"mission","unit":1,"kind":"supply","point":Vector2(520,Terrain.river_y(520)+55)},[0,1,2]),"riverbank supply target accepted")
    b.units[0].pos=Vector2(260,1015); b.units[0].water=10; b.units[0].engaged=true
    b.units[0].mission={"kind":"supply","point":Vector2(260,1015)}
    b.logistics()
    check(b.units[0].water<=10 and b.units[0].xp["ikmal"]==0,"combat interrupts water collection")
    var scout=Battle.new(); scout.ai_teams=[]
    for x in scout.units:
        if x.team==0: x.pos=Vector2(60,1220)
        else: x.pos=Vector2(1320,60)
    scout.units[0].mission={"kind":"scout","point":scout.units[0].pos}
    for i in range(8): scout.logistics()
    check(scout.units[0].xp["keşif"]==0,"empty waypoint cannot farm scouting XP")
    scout.units[18].pos=Vector2(200,1180); scout.logistics()
    var xp=scout.units[0].xp.duplicate()
    check(is_equal_approx(xp["keşif"],0.8) and is_equal_approx(xp["gizlilik"],0.15) and is_equal_approx(xp["manevra"],0.05),"new contact shares action XP across three skills")
    for i in range(8): scout.logistics()
    check(scout.units[0].xp==xp,"known contact does not repeatedly grant XP")
    var secret=Battle.new(); secret.ai_teams=[]
    for x in secret.units:
        if x.team==0: x.pos=Vector2(60,1220)
        else: x.men=0
    secret.units[18].men=100; secret.units[18].pos=Vector2(700,880)
    secret.plan()
    check(not secret.sees(0,secret.units[18]) and secret.wings[1].pressure==0,"hidden enemy cannot leak through wing pressure")
    for i in range(105): secret.log_message(0,"TEST","bounded")
    var ids=[]
    for r in secret.reports: ids.append(r.id)
    var unique={}
    for id in ids: unique[id]=true
    check(ids.size()==100 and unique.size()==100,"bounded report ring retains unique IDs")
    secret.weather="Yağmur"; secret.reset()
    check(secret.weather=="Açık","new match resets previous weather")
    secret.winner=0
    check(not secret.submit({"type":"hold","wings":[0]},[0,1,2]),"finished match cannot accept commands")

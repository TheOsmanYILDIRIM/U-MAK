extends RefCounted
## Authoritative fixed-step company simulation. Visual soldiers never own state.
const Terrain = preload("res://core/terrain.gd")
const SKILLS = ["keşif","hücum","savunma","manevra","baskın","gizlilik","menzilli","kuşatma","ikmal","sağlık"]
const ROLE = {
    "spear":{"name":"Mızraklı","speed":34.0,"range":46.0,"power":2.5,"def":1.24},
    "inf":{"name":"Piyade","speed":36.0,"range":44.0,"power":3.0,"def":1.08},
    "archer":{"name":"Okçu","speed":34.0,"range":205.0,"power":2.5,"def":0.76},
    "cav":{"name":"Süvari","speed":60.0,"range":48.0,"power":3.5,"def":1.0}}
const NAMES = ["Sol kanat","Merkez","Sağ kanat"]
const COMMANDERS = [
    {"name":"Ali Bey","trait":"Disiplinli","risk":0.82,"delay":0.4},
    {"name":"Yunus Bey","trait":"Temkinli","risk":0.66,"delay":0.7},
    {"name":"Boran Bey","trait":"Atılgan","risk":1.2,"delay":0.3}]
var terrain = Terrain.new()
var units: Array=[]
var wings: Array=[]
var reports: Array=[]
var effects: Array=[]
var queue: Array=[]
var time=0.0
var tick=0
var sequence=0
var winner=-1
var control=0.0
var ai_teams: Array=[1]
var metrics={"orders":0,"rejected":0,"reserves":0,"hits":0,"ai":0,"paths":0}
var rng=RandomNumberGenerator.new()
var next_plan=0.0
var next_ai=4.0
var next_logistics=0.0
var contacts=[{},{}]
var wells=[{"pos":Vector2(260,1015),"name":"Güney kuyusu"},{"pos":Vector2(1140,295),"name":"Kuzey kuyusu"}]
var weather="Açık"
var match_limit=600.0

func _init(seed_value:int=1402):
    reset(seed_value)

func reset(seed_value:int=1402):
    units.clear(); wings.clear(); reports.clear(); effects.clear(); queue.clear()
    time=0; tick=0; sequence=0; winner=-1; control=0
    next_plan=0; next_ai=4; next_logistics=0
    contacts=[{},{}]; rng.seed=seed_value
    metrics={"orders":0,"rejected":0,"reserves":0,"hits":0,"ai":0,"paths":0}
    for team in range(2):
        for wi in range(3):
            var x=350.0+wi*350.0
            var y=390.0 if team==1 else 880.0
            var w={"id":team*3+wi,"team":team,"index":wi,"name":NAMES[wi],"commander":COMMANDERS[wi].duplicate(),
                "points":[Vector2(x-132,y),Vector2(x,y),Vector2(x+132,y)],"members":[],"slots":{},
                "mode":"hold","goal":Vector2(x,y),"initiative":"balanced","flipped":false,"pressure":0.0,
                "gaps":0,"pending":false,"intents":{}}
            wings.append(w)
            for j in range(6):
                var role=["spear","inf","spear","cav","archer","inf"][j]
                var men=80.0 if role=="cav" else 100.0
                var xp={}
                for skill in SKILLS: xp[skill]=0.0
                var u={"id":units.size(),"team":team,"wing":w.id,"name":"%d. %s" % [wi*6+j+1,ROLE[role].name],
                    "role":role,"pos":Vector2(x,y),"spawn":Vector2(x,y),"home":Vector2(x,y),
                    "men":men,"max_men":men,"wounded":0.0,"morale":90.0+rng.randf()*5,
                    "stamina":95.0,"water":100.0,"food":100.0,"angle":PI/2 if team==1 else -PI/2,
                    "state":"line","reason":"Kayıtlı mevzisini koruyor","slot":"","mission":{},
                    "path":[],"path_goal":Vector2(-999,-999),"next_path":0.0,"cool":rng.randf(),
                    "charge_cool":0.0,"speed":0.0,"engaged":false,"hit":0.0,"away":0.0,"seq":0,"xp":xp}
                units.append(u); w.members.append(u.id)
            var specs=slots_for(w)
            for j in range(6):
                var u=units[w.members[j]]
                w.slots[specs[j].id]=u.id; u.slot=specs[j].id
                u.pos=specs[j].pos; u.home=u.pos; u.spawn=u.pos
    log_message(0,"KOMUTA","Kanadı seç, hattı çiz. Tek bölüğe görev verirsen yedek boşluğu kapatır.")
    log_message(1,"KOMUTA","Geçidi kontrol et; birliklerini ve ikmalini koru.")
    plan()

func log_message(team:int,source:String,text:String,p:Vector2=Vector2(-1,-1)):
    reports.push_front({"team":team,"source":source,"text":text,"pos":p,"time":time,"id":tick*100+reports.size()})
    if reports.size()>100: reports.resize(100)

func facing(w:Dictionary) -> Vector2:
    var d=w.points.back()-w.points.front()
    var n=Vector2(-d.y,d.x).normalized()
    if n.y*(1 if w.team==1 else -1)<0: n=-n
    if w.flipped: n=-n
    return n

func slots_for(w:Dictionary) -> Array:
    var result: Array=[]
    var n=facing(w)
    var specs=[["f0",0.1,0.0,"front"],["f1",0.36,0.0,"front"],["f2",0.64,0.0,"front"],
        ["f3",0.9,0.0,"front"],["b0",0.5,76.0,"support"],["r0",0.5,140.0,"reserve"]]
    for s in specs:
        result.append({"id":s[0],"kind":s[3],"pos":Terrain.safe(Terrain.along(w.points,s[1])-n*s[2]),"angle":n.angle()})
    return result

func eligible(u:Dictionary) -> bool:
    return u.men>14 and u.state!="routed" and u.mission.is_empty()

func reject() -> bool:
    metrics.rejected+=1
    return false

func submit(order:Dictionary,allowed_wings:Array) -> bool:
    # Strict whitelist at the authority boundary, also used for local play.
    var type=order.get("type","")
    if not type in ["line","advance","hold","withdraw","flip","initiative","mission","return"]: return reject()
    var ids=order.get("wings",[])
    if not ids is Array or ids.size()>3: return reject()
    var uid=order.get("unit",-1)
    if not uid is int: return reject()
    if type in ["mission","return"]:
        if uid<0 or uid>=units.size() or not units[uid].wing in allowed_wings: return reject()
        if units[uid].men<=5 or units[uid].state=="routed": return reject()
        ids=[units[uid].wing]
    elif ids.is_empty(): return reject()
    for id in ids:
        if not id is int or not id in allowed_wings or id<0 or id>=wings.size(): return reject()
    if type in ["advance","mission"]:
        var p=order.get("point",null)
        if not p is Vector2 or not p.is_finite() or p.x<0 or p.y<0 or p.x>1400 or p.y>1320: return reject()
    if type=="line":
        var points=order.get("points",[])
        if not points is Array or ids.size()!=1 or Terrain.validate_line(points)!="": return reject()
    if type=="initiative" and not order.get("value","") in ["strict","balanced","free"]: return reject()
    if type=="mission" and not order.get("kind","") in ["attack","move","retreat","supply","scout"]: return reject()
    var o=order.duplicate(true)
    sequence+=1
    o.seq=sequence; o.at=time+wings[ids[0]].commander.delay
    queue.append(o); metrics.orders+=1
    for id in ids: wings[id].pending=true
    log_message(wings[ids[0]].team,"EMİR","Ulak yola çıktı; emir iletiliyor.",Terrain.along(wings[ids[0]].points,0.5))
    return true

func execute(o:Dictionary):
    var type=o.type
    var channel="initiative" if type=="initiative" else "facing" if type=="flip" else "plan"
    var ids=o.get("wings",[])
    for id in ids:
        var w=wings[id]
        if int(w.intents.get(channel,0))>o.seq: continue
        w.intents[channel]=o.seq; w.pending=false
        match type:
            "line":
                w.points=o.points.duplicate(); w.mode="hold"
            "advance":
                w.goal=Terrain.safe(o.point); w.mode="advance"
            "hold": w.mode="hold"
            "withdraw":
                w.goal=Terrain.safe(Terrain.along(w.points,0.5)-facing(w)*180); w.mode="withdraw"
            "flip": w.flipped=not w.flipped
            "initiative": w.initiative=o.value
        log_message(w.team,"ULAK",w.name+": emir alındı. Özel bölük görevleri korunuyor.",Terrain.along(w.points,0.5))
    if type in ["mission","return"]:
        var u=units[o.unit]
        if u.seq>o.seq or u.state=="routed" or u.men<=5: return
        u.seq=o.seq; wings[u.wing].pending=false
        if type=="return":
            u.mission={}; u.state="line"
        else:
            u.mission={"kind":o.kind,"point":Terrain.safe(o.point),"start":time,"arrival":-1.0,"deadline":time+90.0}
            u.state="special"
        u.path_goal=Vector2(-999,-999)
        log_message(u.team,"ULAK",u.name+(": kanat komutasına döndü." if type=="return" else ": bağımsız görev alındı."),u.pos)
    plan()

func plan():
    for w in wings:
        var specs=slots_for(w)
        for slot in w.slots.keys():
            var u=units[w.slots[slot]]
            if not eligible(u):
                u.slot=""; w.slots.erase(slot)
        for s in specs:
            if s.kind=="front" and not w.slots.has(s.id) and w.slots.has("r0"):
                var rid=w.slots.r0
                w.slots.erase("r0"); w.slots[s.id]=rid; units[rid].slot=s.id
                metrics.reserves+=1
                log_message(w.team,"KOMUTAN",w.name+": yedek boşluğu devralıyor.",s.pos)
        var free: Array=[]
        for id in w.members:
            if eligible(units[id]) and not id in w.slots.values(): free.append(id)
        for s in specs:
            if not w.slots.has(s.id) and not free.is_empty():
                var best=free[0]
                var score=INF
                for id in free:
                    var u=units[id]
                    var penalty=-250.0 if s.kind=="support" and u.role=="archer" else 220.0 if s.kind=="front" and u.role=="archer" else 0.0
                    var value=u.pos.distance_to(s.pos)+penalty
                    if value<score: best=id; score=value
                free.erase(best); w.slots[s.id]=best; units[best].slot=s.id
            if w.slots.has(s.id):
                var u=units[w.slots[s.id]]
                u.home=s.pos; u.home_angle=s.angle
        for id in free:
            units[id].home=Terrain.safe(Terrain.along(w.points,0.5)-facing(w)*180)
            units[id].slot="extra"
        w.gaps=0
        for s in specs:
            if s.kind=="front" and (not w.slots.has(s.id) or units[w.slots[s.id]].pos.distance_to(s.pos)>85): w.gaps+=1
        var c=Terrain.along(w.points,0.5)
        var strength=[0.0,0.0]
        for u in units:
            if u.men>5 and u.state!="routed" and u.pos.distance_to(c)<280:
                strength[u.team]+=u.men*(0.35+u.morale/150.0)
        w.pressure=clampf(strength[1-w.team]/maxf(20,strength[w.team]),0,3)

func sees(team:int,u:Dictionary) -> bool:
    if u.team==team: return true
    for own in units:
        if own.team!=team or own.men<=5 or own.state=="routed": continue
        var sight=480.0 if own.role=="cav" else 390.0
        if Terrain.kind(own.pos)=="hill": sight+=80
        if Terrain.kind(u.pos)=="forest": sight*=0.65
        if weather=="Yağmur": sight*=0.82
        if own.pos.distance_to(u.pos)<sight: return true
    return false

func enemy_brain():
    metrics.ai+=1
    for team in ai_teams:
        for w in wings:
            if w.team!=team: continue
            var c=Terrain.along(w.points,0.5)
            var avg=0.0
            for id in w.members: avg+=units[id].morale
            avg/=6
            w.mode="withdraw" if avg<35 else "advance"
            var y=270.0 if team==1 else 1050.0
            if avg>=35: y=790.0 if team==1 else 450.0
            var goal=Vector2(350.0+w.index*350.0,y)
            var weakest={}
            var score=INF
            for u in units:
                if u.team==team or not sees(team,u) or u.men<=14 or u.state=="routed": continue
                var value=u.men*(0.4+u.morale/100)+u.pos.distance_to(c)*0.08
                if value<score: score=value; weakest=u
            if not weakest.is_empty() and avg>=35: goal=weakest.pos
            w.goal=Terrain.safe(goal)
            if time>16 and not weakest.is_empty():
                for id in w.members:
                    var u=units[id]
                    if u.role=="cav" and u.mission.is_empty() and u.morale>60 and u.stamina>50:
                        var flank=Vector2(-140 if w.index==0 else 140,55 if team==1 else -55)
                        u.mission={"kind":"attack","point":Terrain.safe(weakest.pos+flank),"start":time,"arrival":-1.0,"deadline":time+50}
                        u.path_goal=Vector2(-999,-999)

func nearest(u:Dictionary,r:float) -> Dictionary:
    var best={}
    for v in units:
        if v.team==u.team or v.men<=5 or v.state=="routed": continue
        var d=u.pos.distance_to(v.pos)
        if d<r and sees(u.team,v): r=d; best=v
    return best

func move_unit(u:Dictionary,goal:Vector2,dt:float):
    u.speed=0.0
    if u.pos.distance_to(goal)<6: return
    if time>=u.next_path and (u.path_goal.distance_to(goal)>35 or u.path.is_empty()):
        u.path=terrain.path(u.pos,goal); u.path_goal=goal; u.next_path=time+0.7; metrics.paths+=1
    while not u.path.is_empty() and u.pos.distance_to(u.path[0])<7: u.path.pop_front()
    if u.path.is_empty(): return
    var speed=ROLE[u.role].speed*(0.45+0.55*u.stamina/100.0)/Terrain.cost(u.pos)
    if weather=="Yağmur": speed*=0.86 if u.role=="cav" else 0.94
    if u.state=="routed": speed*=1.18
    if u.water<12: speed*=0.7
    var d=u.path[0]-u.pos
    var next=u.pos+d.normalized()*minf(d.length(),speed*dt)
    if Terrain.walkable(next) and Terrain.clear(u.pos,next):
        u.pos=next; u.speed=speed
        u.angle=lerp_angle(u.angle,d.angle(),minf(1,dt*4))
        u.stamina=maxf(0,u.stamina-dt*(0.23 if u.role=="cav" else 0.16))
    else:
        u.path=[]; u.next_path=time+0.2

func route(u:Dictionary):
    if u.state=="routed": return
    u.state="routed"; u.mission={}; u.path=[]; u.away=time
    log_message(u.team,"ACİL",u.name+": düzen çözüldü, güvenli alana çekiliyor.",u.pos)

func logistics():
    weather="Yağmur" if int(time/120)%3==1 else "Açık"
    for u in units:
        if u.men<=5: continue
        u.water=maxf(0,u.water-(0.055 if u.speed>0 else 0.025))
        u.food=maxf(0,u.food-0.014)
        if u.water<=0: u.stamina=maxf(0,u.stamina-0.18); u.morale=maxf(0,u.morale-0.08)
        var at_camp=u.pos.distance_to(Vector2(700,1180 if u.team==0 else 150))<200
        if at_camp and not u.engaged:
            u.water=minf(100,u.water+1.5); u.food=minf(100,u.food+0.8)
            var healed=minf(u.wounded,0.16+u.xp["sağlık"]*0.0002)
            u.wounded-=healed; u.men=minf(u.max_men,u.men+healed); u.xp["sağlık"]+=healed
        if not u.mission.is_empty():
            var m=u.mission
            if u.pos.distance_to(m.point)<45:
                if m.kind=="supply":
                    var water=false
                    for well in wells:
                        if u.pos.distance_to(well.pos)<80: water=true
                    if absf(u.pos.y-Terrain.river_y(u.pos.x))<85: water=true
                    if water:
                        u.water=minf(100,u.water+4); u.xp["ikmal"]+=0.1
                        if u.water>=99: u.mission={}; u.state="line"
                if m.kind=="scout": u.xp["keşif"]+=0.08; u.xp["gizlilik"]+=0.02
        for team in range(2):
            if u.team!=team and sees(team,u):
                if not contacts[team].has(u.id): log_message(team,"KEŞİF","Düşman "+ROLE[u.role].name.to_lower()+" birliği görüldü.",u.pos)
                contacts[team][u.id]={"pos":u.pos,"time":time,"role":u.role}

func step(dt:float):
    if winner!=-1: return
    time+=dt; tick+=1
    var due: Array=[]
    for o in queue:
        if o.at<=time: due.append(o)
    for o in due: queue.erase(o); execute(o)
    if time>=next_ai: enemy_brain(); next_ai=time+3.5
    for w in wings:
        if not w.mode in ["advance","withdraw"]: continue
        var c=Terrain.along(w.points,0.5)
        var delta=w.goal-c
        if delta.length()<8: w.mode="hold"; continue
        var lag=0.0
        var touching=false
        for id in w.members:
            var u=units[id]
            if eligible(u):
                lag=maxf(lag,u.pos.distance_to(u.home)); touching=touching or u.engaged
        var speed=23.0
        if lag>125: speed=4.0
        if touching and w.mode!="withdraw": speed=0.0
        var shift=delta.normalized()*minf(delta.length(),speed*dt)
        for i in range(w.points.size()): w.points[i]=(w.points[i]+shift).clamp(Vector2(36,36),Vector2(1364,1284))
    if time>=next_plan: plan(); next_plan=time+0.5
    if time>=next_logistics: logistics(); next_logistics=time+1
    var hits: Array=[]
    for u in units:
        if u.men<=5: u.state="lost"; continue
        u.cool-=dt; u.charge_cool-=dt; u.hit=maxf(0,u.hit-dt); u.engaged=false
        if u.morale<18 or u.men<14: route(u)
        if u.state=="routed":
            var safe=Vector2(clampf(u.spawn.x,80,1320),100 if u.team==1 else 1220)
            move_unit(u,safe,dt)
            if u.pos.distance_to(safe)<60:
                u.stamina=minf(100,u.stamina+dt*2); u.morale=minf(100,u.morale+dt*1.2)
                if time-u.away>18 and u.morale>50 and u.men>=30: u.state="line"
            continue
        var w=wings[u.wing]
        var goal=u.home
        var enemy=nearest(u,320)
        var m=u.mission
        var reason="Yedekte; boşluk için hazır" if u.slot=="r0" else "Kanat düzeninde"
        u.state="line" if w.mode=="hold" else w.mode
        if not m.is_empty():
            goal=m.point; u.state="special"; reason="Özel görev: "+m.kind
            if u.pos.distance_to(goal)<35:
                if m.arrival<0: m.arrival=time
                if m.kind=="retreat":
                    u.stamina=minf(100,u.stamina+dt*2); u.morale=minf(100,u.morale+dt)
                if (m.kind=="attack" and enemy.is_empty() and time-m.arrival>6) or (m.kind=="retreat" and u.morale>80 and u.stamina>85):
                    u.mission={}; goal=u.home
            if time>m.deadline and m.kind=="attack": u.mission={}; goal=u.home
        var retreating=(not m.is_empty() and m.kind=="retreat") or w.mode=="withdraw"
        if not enemy.is_empty() and not retreating:
            var distance=u.pos.distance_to(enemy.pos)
            var leash=(25.0 if w.initiative=="strict" else 170.0 if w.initiative=="free" else 95.0)*w.commander.risk
            var in_leash=enemy.pos.distance_to(goal)<leash+ROLE[u.role].range
            if not m.is_empty(): in_leash=m.kind=="attack" and distance<170
            if distance<ROLE[u.role].range and (u.role=="archer" or Terrain.clear(u.pos,enemy.pos)):
                u.engaged=true; reason="Yaylım ateşi" if u.role=="archer" else "Yakın temas"
                if m.is_empty(): u.state="contact"
                if u.cool<=0:
                    var dot=Vector2.from_angle(enemy.angle).dot((u.pos-enemy.pos).normalized())
                    var flank=1.32 if dot< -0.15 else 1.0
                    var charge=u.role=="cav" and u.speed>22 and u.charge_cool<=0
                    var defense=ROLE[enemy.role].def
                    if u.role=="cav" and enemy.role=="spear" and dot>0.15: defense*=1.6
                    var skill="menzilli" if u.role=="archer" else "hücum" if not m.is_empty() else "savunma"
                    var damage=ROLE[u.role].power*(u.men/u.max_men)*(0.45+u.stamina/170)*(0.6+u.morale/220)*flank/defense
                    damage*=1.0+minf(0.16,u.xp[skill]/1500.0)
                    if charge: damage+=3.8; u.charge_cool=14.0
                    if u.role=="archer" and distance<60: damage*=0.35
                    if u.role=="archer" and Terrain.kind(enemy.pos)=="forest": damage*=0.78
                    hits.append({"id":enemy.id,"damage":damage,"morale":damage*0.8+(4.0 if charge else 0.0)})
                    u.cool=1.8 if u.role=="archer" else 1.1
                    u.xp[skill]+=0.3; u.xp["manevra"]+=0.04
                    metrics.hits+=1
                    effects.append({"a":u.pos,"b":enemy.pos,"age":0.0,"life":0.55,"kind":"arrow" if u.role=="archer" else "hit","team":u.team})
                u.angle=lerp_angle(u.angle,(enemy.pos-u.pos).angle(),minf(1,dt*3))
            elif in_leash: goal=enemy.pos
        if u.engaged:
            u.stamina=maxf(0,u.stamina-dt*0.55); u.speed=0
        else:
            move_unit(u,goal,dt)
            if u.speed<1:
                u.stamina=minf(100,u.stamina+dt*0.8); u.morale=minf(100,u.morale+dt*0.14)
                if m.is_empty(): u.angle=lerp_angle(u.angle,u.get("home_angle",u.angle),minf(1,dt*1.5))
        u.reason=reason
    for hit in hits:
        var u=units[hit.id]
        var loss=minf(u.men,hit.damage)
        u.men-=loss; u.wounded+=loss*0.3; u.morale=maxf(0,u.morale-hit.morale); u.hit=0.25
    for i in range(units.size()):
        var a=units[i]
        if a.men<=5: continue
        for j in range(i+1,units.size()):
            var b=units[j]
            if b.men<=5: continue
            var d=a.pos.distance_to(b.pos)
            if d>0.01 and d<30:
                var push=(a.pos-b.pos)/d*(30-d)*0.2
                if Terrain.walkable(a.pos+push): a.pos+=push
                if Terrain.walkable(b.pos-push): b.pos-=push
    for f in effects: f.age+=dt
    effects=effects.filter(func(f): return f.age<f.life)
    if effects.size()>100: effects=effects.slice(-100)
    var bridge=Vector2(700,Terrain.river_y(700))
    var power=[0.0,0.0]
    var alive=[0,0]
    for u in units:
        if u.men>14 and u.state!="routed":
            alive[u.team]+=1
            if u.pos.distance_to(bridge)<160: power[u.team]+=u.men
    if absf(power[0]-power[1])>40:
        control=clampf(control+signf(power[0]-power[1])*dt*0.65,-100,100)
    if absf(control)>=100: winner=0 if control>0 else 1
    if time>40 and (alive[0]==0 or alive[1]==0): winner=0 if alive[0]>0 else 1 if alive[1]>0 else 2
    if time>=match_limit and winner<0: winner=0 if control>5 else 1 if control< -5 else 2

func snapshot(team:int,omniscient:bool=false) -> Dictionary:
    var visible: Array=[]
    for u in units:
        if u.team==team:
            var copy=u.duplicate(true)
            copy.erase("path"); copy.erase("next_path"); copy.erase("path_goal")
            visible.append(copy)
        elif omniscient or sees(team,u):
            visible.append({"id":u.id,"team":u.team,"wing":u.wing,"name":ROLE[u.role].name,"role":u.role,
                "pos":u.pos,"angle":u.angle,"men":roundf(u.men/20)*20,"max_men":u.max_men,"state":u.state,
                "speed":u.speed,"hit":u.hit,"engaged":u.engaged})
    var own_wings: Array=[]
    for w in wings:
        if w.team==team or omniscient: own_wings.append(w.duplicate(true))
    var feed: Array=[]
    for r in reports:
        if r.team==team and feed.size()<24: feed.append(r.duplicate())
    var fx: Array=[]
    for f in effects:
        if omniscient or f.team==team or visible.any(func(u):return u.pos.distance_to(f.a)<60): fx.append(f.duplicate())
    var ghosts: Array=[]
    for id in contacts[team]:
        var c=contacts[team][id]
        if time-c.time<25 and not visible.any(func(u): return u.id==id): ghosts.append(c.duplicate())
    return {"tick":tick,"time":time,"units":visible,"wings":own_wings,"reports":feed,"effects":fx,"ghosts":ghosts,
        "winner":winner,"control":control,"weather":weather,"limit":match_limit,"team":team}

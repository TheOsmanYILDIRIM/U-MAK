extends Control
signal selection_changed
signal preview_changed
signal hint(text: String)
const Terrain=preload("res://core/terrain.gd")
const FRIEND=Color("7dced3")
const ENEMY=Color("ee9075")
const GOLD=Color("e1cb91")
var data: Dictionary={}
var team=0
var selected_wing=1
var selected_unit=-1
var all_wings=false
var tool="select"
var center=Vector2(700,700)
var zoom=0.5
var min_zoom=0.15
var initialized=false
var touches: Dictionary={}
var gesture=false
var start_screen=Vector2.ZERO
var previous_screen=Vector2.ZERO
var drag_points: Array=[]
var preview: Array=[]
var preview_error=""
var moved=false
var editing=-1
var markers: Array=[]
var trees: Array=[]
var grass: Array=[]
var font: Font
var elapsed=0.0
var visual_positions: Dictionary={}

func _ready():
    mouse_filter=Control.MOUSE_FILTER_STOP
    clip_contents=true
    font=ThemeDB.fallback_font
    resized.connect(_resize)
    var rng=RandomNumberGenerator.new(); rng.seed=1402
    for i in range(360):
        var p=Vector2(rng.randf_range(25,1375),rng.randf_range(25,1295))
        grass.append([p,rng.randf_range(1,3)])
    for e in Terrain.FORESTS:
        for i in range(38):
            var angle=rng.randf()*TAU
            var r=sqrt(rng.randf())
            trees.append([Vector2(e.x+cos(angle)*e.z*r,e.y+sin(angle)*e.w*r),rng.randf_range(9,18)])
    _resize()

func _resize():
    min_zoom=minf(size.x/1480.0,size.y/1400.0)
    if not initialized and size.x>100 and size.y>100:
        fit(); initialized=true
    constrain()

func fit():
    center=Vector2(700,700)
    zoom=minf(size.x/1270.0,size.y/1190.0)
    constrain(); queue_redraw()

func constrain():
    zoom=clampf(zoom,maxf(0.1,min_zoom),2.8)
    center=center.clamp(Vector2(100,100),Vector2(1300,1220))

func world(p:Vector2) -> Vector2:
    return (p-size/2)/zoom+center

func screen(p:Vector2) -> Vector2:
    return (p-center)*zoom+size/2

func zoom_at(point:Vector2,ratio:float):
    var anchor=world(point)
    zoom=clampf(zoom*ratio,maxf(0.1,min_zoom),2.8)
    center=anchor-(point-size/2)/zoom
    constrain(); queue_redraw()

func selected_wings() -> Array:
    return Session.owned.duplicate() if all_wings else [selected_wing]

func select_army():
    all_wings=true; selected_unit=-1; cancel()
    selection_changed.emit()

func select_wing(id:int):
    selected_wing=id; selected_unit=-1; all_wings=false; cancel()
    selection_changed.emit()

func unit(id:int) -> Dictionary:
    for u in data.get("units",[]):
        if u.id==id: return u
    return {}

func wing() -> Dictionary:
    for w in data.get("wings",[]):
        if w.id==selected_wing: return w
    return {}

func begin(next_tool:String):
    cancel()
    if next_tool=="line" and all_wings:
        hint.emit("Hat çizmek için önce Sol, Merkez veya Sağ kanadı seç.")
        return
    tool=next_tool
    hint.emit("Hattı çiz; önizlemeyi onayla." if tool=="line" else "Hedef konuma dokun. İki parmak her zaman kamerayı yönetir.")
    queue_redraw()

func cancel():
    tool="select"; preview=[]; preview_error=""; drag_points=[]; editing=-1
    preview_changed.emit(); queue_redraw()

func confirm():
    if preview.is_empty() or preview_error!="" or all_wings: return
    if Session.send({"type":"line","wings":[selected_wing],"points":preview.duplicate()}): cancel()

func _process(dt):
    elapsed+=dt
    for m in markers: m.age+=dt
    markers=markers.filter(func(m): return m.age<1.2)
    # Rendering smooths only permitted snapshots; no positions are simulated here.
    var visible={}
    for u in data.get("units",[]):
        visible[u.id]=true
        var old:Vector2=visual_positions.get(u.id,u.pos)
        visual_positions[u.id]=u.pos if old.distance_to(u.pos)>160 else old.lerp(u.pos,1.0-exp(-18.0*dt))
    for id in visual_positions.keys():
        if not visible.has(id): visual_positions.erase(id)
    queue_redraw()

func _gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed: pointer_down(event.index,event.position)
        else: pointer_up(event.index,event.position,event.canceled)
        accept_event()
    elif event is InputEventScreenDrag:
        pointer_move(event.index,event.position); accept_event()
    elif event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom_at(event.position,1.15)
        elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom_at(event.position,1/1.15)
        elif event.button_index==MOUSE_BUTTON_LEFT:
            if event.pressed: pointer_down(-1,event.position)
            else: pointer_up(-1,event.position)
        accept_event()
    elif event is InputEventMouseMotion and touches.has(-1):
        pointer_move(-1,event.position); accept_event()
    elif event is InputEventMagnifyGesture:
        zoom_at(event.position,event.factor); accept_event()

func pointer_down(id:int,p:Vector2):
    touches[id]=p
    if touches.size()>1:
        gesture=true; drag_points=[]; preview=[]; editing=-1
        preview_changed.emit(); return
    gesture=false; moved=false; start_screen=p; previous_screen=p; editing=-1
    if tool=="line": drag_points=[Terrain.safe(world(p))]
    elif tool=="select" and selected_unit<0 and not all_wings:
        var w=wing()
        if not w.is_empty() and selected_wing in Session.owned:
            var handles=[w.points.front(),Terrain.along(w.points,0.5),w.points.back()]
            for i in range(3):
                if p.distance_to(screen(handles[i]))<18:
                    editing=i; preview=w.points.duplicate(); break

func pointer_move(id:int,p:Vector2):
    if not touches.has(id): return
    var old=touches[id]
    if touches.size()>=2:
        var keys=touches.keys()
        var old_a=touches[keys[0]]; var old_b=touches[keys[1]]
        touches[id]=p
        var a=touches[keys[0]]; var b=touches[keys[1]]
        var anchor=world((old_a+old_b)/2)
        zoom=clampf(zoom*a.distance_to(b)/maxf(1,old_a.distance_to(old_b)),maxf(0.1,min_zoom),2.8)
        center=anchor-((a+b)/2-size/2)/zoom
        constrain(); queue_redraw(); return
    touches[id]=p
    if gesture: return
    if p.distance_to(start_screen)>8: moved=true
    if tool=="line":
        var q=world(p)
        if drag_points.is_empty(): drag_points=[q]
        if q.distance_to(drag_points.back())>38 and drag_points.size()<11: drag_points.append(q)
        preview=drag_points.duplicate()
        if preview.size()<12: preview.append(q)
        preview_error=Terrain.validate_line(preview)
        preview_changed.emit()
    elif editing>=0:
        if editing==1:
            var shift=(p-old)/zoom
            for i in range(preview.size()): preview[i]+=shift
        elif editing==0: preview[0]=world(p)
        else: preview[-1]=world(p)
        preview_error=Terrain.validate_line(preview); preview_changed.emit()
    elif tool=="select" and moved:
        center-=(p-old)/zoom; constrain()
    previous_screen=p; queue_redraw()

func pointer_up(id:int,p:Vector2,cancelled:bool=false):
    if not touches.has(id): return
    touches.erase(id)
    if gesture:
        if touches.is_empty(): gesture=false
        return
    if cancelled:
        preview=[]; drag_points=[]; editing=-1; preview_changed.emit(); return
    if tool=="line" or editing>=0:
        editing=-1
        preview_error=Terrain.validate_line(preview)
        preview_changed.emit(); return
    if moved: return
    var q=Terrain.safe(world(p))
    if tool=="advance":
        if Session.send({"type":"advance","wings":selected_wings(),"point":q}): mark(q); cancel()
    elif tool in ["attack","move","retreat","supply","scout"] and selected_unit>=0:
        if Session.send({"type":"mission","unit":selected_unit,"kind":tool,"point":q}): mark(q); cancel()
    else:
        var picked={}
        var nearest=27.0
        for u in data.get("units",[]):
            if u.team!=team or u.men<=5: continue
            var d=screen(visual_positions.get(u.id,u.pos)).distance_to(p)
            if d<nearest: picked=u; nearest=d
        if not picked.is_empty():
            selected_unit=picked.id; selected_wing=picked.wing; all_wings=false; cancel(); selection_changed.emit()
        else:
            selected_unit=-1; selection_changed.emit()
    queue_redraw()

func mark(p:Vector2):
    markers.append({"pos":p,"age":0.0})

func dashed(a:Vector2,b:Vector2,color:Color,width:float=2.0):
    var d=a.distance_to(b)
    var n=maxi(1,ceili(d/12))
    for i in range(0,n,2): draw_line(a.lerp(b,float(i)/n),a.lerp(b,minf(1,float(i+1)/n)),color,width,true)

func label(p:Vector2,text:String,color:Color=Color("e9e5d1"),font_size:int=14):
    var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
    draw_style_box(tag_style(),Rect2(p+Vector2(-width/2-5,-font_size-2),Vector2(width+10,font_size+8)))
    draw_string(font,p+Vector2(-width/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func tag_style() -> StyleBoxFlat:
    var style=StyleBoxFlat.new()
    style.bg_color=Color(0.04,0.12,0.12,0.8)
    style.corner_radius_top_left=4; style.corner_radius_top_right=4
    style.corner_radius_bottom_left=4; style.corner_radius_bottom_right=4
    return style

func _draw():
    if size.x<10 or font==null: return
    draw_rect(Rect2(Vector2.ZERO,size),Color("394f45"))
    var offset=size/2-center*zoom
    draw_set_transform(offset,0,Vector2(zoom,zoom))
    draw_rect(Rect2(Vector2.ZERO,Terrain.SIZE),Color("858f6a"))
    for item in grass:
        draw_circle(item[0],item[1],Color(0.28,0.36,0.24,0.2))
    for e in Terrain.HILLS:
        for r in range(5,0,-1):
            var pts=PackedVector2Array()
            for i in range(49):
                var a=TAU*i/48.0
                pts.append(Vector2(e.x+cos(a)*e.z*r/5.0,e.y+sin(a)*e.w*r/5.0))
            draw_polyline(pts,Color(0.85,0.83,0.62,0.27),1.4/zoom,true)
    draw_polyline(PackedVector2Array([Vector2(700,40),Vector2(680,300),Vector2(700,600),Vector2(690,950),Vector2(700,1290)]),Color("a3a079"),20,true)
    draw_polyline(PackedVector2Array([Vector2(90,200),Vector2(350,430),Vector2(350,660),Vector2(250,940),Vector2(60,1200)]),Color("a3a079"),13,true)
    var river=PackedVector2Array()
    for x in range(0,1401,14): river.append(Vector2(x,Terrain.river_y(x)))
    draw_polyline(river,Color("435e50"),78,true)
    draw_polyline(river,Color("b1b08b"),69,true)
    draw_polyline(river,Color("538986"),60,true)
    draw_polyline(river,Color(0.52,0.76,0.72,0.32),38,true)
    for x in range(10,1390,50):
        var xx=x+fmod(elapsed*8,30)
        draw_line(Vector2(xx,Terrain.river_y(xx)),Vector2(xx+18,Terrain.river_y(xx+18)+2),Color(0.8,0.87,0.75,0.4),1.4,true)
    for x in Terrain.CROSSINGS:
        var y=Terrain.river_y(x)
        draw_rect(Rect2(x-37,y-41,74,82),Color("8d9576") if x==700 else Color(0.65,0.7,0.52,0.35))
        for j in range(-35,40,14): draw_line(Vector2(x-35,y+j),Vector2(x+35,y+j),Color("b4b48d"),3)
        if x==700:
            draw_line(Vector2(x-40,y-42),Vector2(x-40,y+42),Color("d5c9a2"),6)
            draw_line(Vector2(x+40,y-42),Vector2(x+40,y+42),Color("d5c9a2"),6)
    for tree in trees:
        var p=tree[0]; var radius=tree[1]
        draw_circle(p+Vector2(5,7),radius+4,Color(0.13,0.24,0.18,0.32))
        draw_circle(p,radius,Color("456c48"))
        draw_circle(p-Vector2(3,4),radius*0.62,Color("749365"))
    for y in [150.0,1180.0]:
        for i in range(8):
            var p=Vector2(605+(i%4)*48,y+floori(i/4.0)*42)
            draw_colored_polygon(PackedVector2Array([p+Vector2(-18,14),p+Vector2(0,-18),p+Vector2(18,14)]),Color("d3c7a2"))
            draw_colored_polygon(PackedVector2Array([p,p+Vector2(0,-18),p+Vector2(18,14),p+Vector2(2,14)]),Color("777f64"))
    for p in [Vector2(260,1015),Vector2(1140,295)]:
        draw_circle(p,20,Color("c3b88e")); draw_circle(p,13,Color("244b51")); draw_arc(p,17,0,TAU,24,Color("e5d5a9"),3)
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    label(screen(Vector2(700,590)),"TAŞ KÖPRÜ",GOLD,12)
    label(screen(Vector2(350,580)),"SIĞ GEÇİT",Color("d6d8bd"),11)
    label(screen(Vector2(1050,580)),"DOĞU GEÇİDİ",Color("d6d8bd"),11)
    label(screen(Vector2(260,990)),"KUYU",FRIEND,11)
    label(screen(Vector2(1140,270)),"KUYU",ENEMY,11)
    for ghost in data.get("ghosts",[]):
        var p=screen(ghost.pos)
        draw_arc(p,19,0,TAU,24,Color(0.93,0.56,0.46,0.4),1.5)
        draw_string(font,p+Vector2(-5,5),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,18,ENEMY)
    var chosen_wings=selected_wings()
    for w in data.get("wings",[]):
        var chosen=w.id in chosen_wings
        var pts=PackedVector2Array()
        for p in w.points: pts.append(screen(p))
        draw_polyline(pts,Color(FRIEND,0.85 if chosen else 0.3),3.5 if chosen else 1.5,true)
        if chosen and selected_unit<0 and not all_wings and preview.is_empty():
            for p in [w.points.front(),Terrain.along(w.points,0.5),w.points.back()]:
                draw_circle(screen(p),11,Color("183c37")); draw_arc(screen(p),11,0,TAU,24,FRIEND,2)
            var d=w.points.back()-w.points.front()
            var n=Vector2(-d.y,d.x).normalized()
            if n.y*(1 if w.team==1 else -1)<0: n=-n
            if w.flipped: n=-n
            var c=screen(Terrain.along(w.points,0.5))
            var side=Vector2(-n.y,n.x)
            draw_line(c,c+n*30,FRIEND,2,true)
            draw_line(c+n*30,c+n*21+side*5,FRIEND,2,true)
    for u in data.get("units",[]):
        if u.men<=5: continue
        var own=u.team==team
        var color=FRIEND if own else ENEMY
        var p=screen(visual_positions.get(u.id,u.pos))
        if not Rect2(Vector2(-60,-60),size+Vector2(120,120)).has_point(p): continue
        var chosen=u.id==selected_unit
        if chosen:
            draw_arc(p,26,0,TAU,40,GOLD,2.5,true)
            var m=u.get("mission",{})
            if not m.is_empty(): dashed(p,screen(m.point),GOLD,2); draw_circle(screen(m.point),6,GOLD)
        elif own and u.wing in chosen_wings:
            draw_circle(p,23,Color(0.12,0.38,0.38,0.18))
        var count=clampi(ceili(u.men/6),2,18)
        var spacing=clampf(6*zoom,2.3,8)
        for j in range(count):
            var local=Vector2((j%6-2.5)*spacing,(j/6-1)*spacing*1.2).rotated(u.angle+PI/2)
            var step=sin(elapsed*7+j)*1.1 if u.speed>1 else 0.0
            var q=p+local+Vector2(0,step)
            draw_circle(q+Vector2(1,2),2.4,Color(0.08,0.16,0.13,0.4))
            draw_line(q+Vector2(-1,1),q+Vector2(1,4),color,2)
            draw_circle(q+Vector2(0,-1),1.6,Color("dac4a1"))
        var symbol={"spear":"I","inf":"II","archer":"∿","cav":"◆"}[u.role]
        var box=Rect2(p+Vector2(-15,-29),Vector2(30,19))
        draw_style_box(tag_style(),box)
        draw_rect(box,GOLD if chosen else color,false,1.6)
        draw_string(font,p+Vector2(-6,-14),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
        if own:
            draw_rect(Rect2(p+Vector2(-18,17),Vector2(36,3)),Color("213c35"))
            draw_rect(Rect2(p+Vector2(-18,17),Vector2(36*u.morale/100,3)),Color("e6b477") if u.morale<40 else Color("aed5a9"))
            if u.state=="routed": label(p+Vector2(0,38),"ÇÖZÜLDÜ",ENEMY,9)
            elif not u.get("mission",{}).is_empty(): draw_circle(p+Vector2(21,-18),3.5,GOLD)
            elif u.get("slot","")=="r0": draw_string(font,p+Vector2(20,-16),"R",HORIZONTAL_ALIGNMENT_LEFT,-1,10,GOLD)
        if u.hit>0: draw_arc(p,20,0,TAU,20,Color(1,0.92,0.7,u.hit*3),2)
    for f in data.get("effects",[]):
        var a=screen(f.a); var b=screen(f.b)
        if f.kind=="arrow":
            var p=a.lerp(b,clampf(f.age/f.life,0,1))
            draw_line(p,p-(b-a).normalized()*9,Color("e7dbb7"),1.6,true)
        else: draw_arc(b,7+f.age*15,0,TAU,12,Color(1,0.75,0.4,1-f.age/f.life),1.5)
    if preview.size()>=2:
        var pts=PackedVector2Array()
        for p in preview: pts.append(screen(p))
        var color=GOLD if preview_error=="" else ENEMY
        draw_polyline(pts,color,4,true)
        for t in [0.1,0.36,0.64,0.9]:
            var p=screen(Terrain.along(preview,t))
            draw_rect(Rect2(p-Vector2(13,9),Vector2(26,18)),Color(color,0.22))
            draw_rect(Rect2(p-Vector2(13,9),Vector2(26,18)),color,false,1.5)
    for m in markers: draw_arc(screen(m.pos),12+m.age*20,0,TAU,32,Color(GOLD,1-m.age/1.2),2)
    var mini=Rect2(size-Vector2(117,111),Vector2(108,102))
    draw_style_box(tag_style(),mini)
    var factor=Vector2(mini.size.x/1400,mini.size.y/1320)
    for u in data.get("units",[]):
        if u.men>5: draw_circle(mini.position+u.pos*factor,2,FRIEND if u.team==team else ENEMY)
    var view_rect=Rect2(world(Vector2.ZERO),size/zoom)
    var top=(view_rect.position*factor+mini.position).clamp(mini.position,mini.end)
    var bottom=(view_rect.end*factor+mini.position).clamp(mini.position,mini.end)
    draw_rect(Rect2(top,bottom-top),Color(GOLD,0.6),false,1)

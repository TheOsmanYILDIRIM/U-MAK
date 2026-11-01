extends Control
signal selection_changed
signal preview_changed
signal hint(text: String)
const Terrain=preload("res://core/terrain.gd")
const TerrainLayer=preload("res://ui/terrain_layer.gd")
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
var terrain_view:SubViewport
var font: Font
var elapsed=0.0
var visual_positions: Dictionary={}
# Android draws a smaller LOD, not fewer simulated companies.
var mobile_lod=false
var redraw_clock=0.0
var render_frames=0
var slowest_render_ms=0.0
var last_slow_render_log=-10.0
var cached_tag:StyleBoxFlat

func _ready():
    mouse_filter=Control.MOUSE_FILTER_STOP
    clip_contents=true
    font=ThemeDB.fallback_font
    mobile_lod=OS.has_feature("mobile") or OS.get_name()=="Android" or OS.get_cmdline_user_args().has("--mobile-lod")
    cached_tag=tag_style()
    resized.connect(_resize)
    # Physical Android uses the low-memory procedural field. No startup render target allocation.
    if not mobile_lod:
        terrain_view=SubViewport.new()
        terrain_view.name="TerrainCache"
        terrain_view.size=Vector2i(1400,1320)
        terrain_view.disable_3d=true
        terrain_view.render_target_update_mode=SubViewport.UPDATE_ONCE
        add_child(terrain_view)
        terrain_view.add_child(TerrainLayer.new())
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
    # Menu never needs continuously rebuilt terrain/units in the background.
    if Session.phase!="battle": return
    redraw_clock+=dt
    if mobile_lod and redraw_clock<1.0/30.0: return
    redraw_clock=0.0
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
    draw_style_box(cached_tag,Rect2(p+Vector2(-width/2-5,-font_size-2),Vector2(width+10,font_size+8)))
    draw_string(font,p+Vector2(-width/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func tag_style() -> StyleBoxFlat:
    var style=StyleBoxFlat.new()
    style.bg_color=Color(0.04,0.12,0.12,0.8)
    style.corner_radius_top_left=4; style.corner_radius_top_right=4
    style.corner_radius_bottom_left=4; style.corner_radius_bottom_right=4
    return style

func _draw():
    if size.x<10 or font==null: return
    var started_us=Time.get_ticks_usec()
    render_frames+=1
    draw_rect(Rect2(Vector2.ZERO,size),Color("394f45"))
    var offset=size/2-center*zoom
    draw_set_transform(offset,0,Vector2(zoom,zoom))
    if terrain_view!=null:
        draw_texture(terrain_view.get_texture(),Vector2.ZERO)
    else:
        # Safe Android LOD: few strokes, no offscreen texture and no per-tree drawing.
        draw_rect(Rect2(Vector2.ZERO,Vector2(1400,1320)),Color("858f6a"))
        var river_points=PackedVector2Array()
        for x in range(0,1401,42): river_points.append(Vector2(x,Terrain.river_y(x)))
        draw_polyline(river_points,Color("4c888a"),62.0,true)
        for crossing in Terrain.CROSSINGS:
            var y=Terrain.river_y(crossing)
            draw_rect(Rect2(crossing-35,y-38,70,76),Color("d1c49d"))
        for well in [Vector2(260,1015),Vector2(1140,295)]:
            draw_circle(well,17,Color("d7d1af"))
            draw_circle(well,11,Color("35646b"))
    # Water glints alone animate over the cached scenery.
    for x in range(10,1390,50):
        var xx=x+fmod(elapsed*8,30)
        draw_line(Vector2(xx,Terrain.river_y(xx)),Vector2(xx+18,Terrain.river_y(xx+18)+2),Color(0.8,0.87,0.75,0.4),1.4,true)
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
        var detailed=not mobile_lod or zoom>0.85
        var count=clampi(ceili(u.men/(8.0 if detailed else 14.0)),2,16 if detailed else 7)
        var cols=6 if detailed else 4
        var spacing=clampf(6*zoom,2.8,8)
        for j in range(count):
            var local=Vector2((j%cols-(cols-1)*0.5)*spacing,(floori(float(j)/cols)-1)*spacing*1.2).rotated(u.angle+PI/2)
            var step=sin(elapsed*7+j)*1.1 if u.speed>1 else 0.0
            var q=p+local+Vector2(0,step)
            if detailed:
                draw_circle(q+Vector2(1,2),2.4,Color(0.08,0.16,0.13,0.4))
                draw_line(q+Vector2(-1,1),q+Vector2(1,4),color,2)
                draw_circle(q+Vector2(0,-1),1.6,Color("dac4a1"))
            else:
                draw_circle(q,2.5,color)
        var symbol={"spear":"I","inf":"II","archer":"∿","cav":"◆"}[u.role]
        var box=Rect2(p+Vector2(-15,-29),Vector2(30,19))
        draw_style_box(cached_tag,box)
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
    var draw_ms=(Time.get_ticks_usec()-started_us)/1000.0
    slowest_render_ms=maxf(slowest_render_ms,draw_ms)
    if mobile_lod and draw_ms>45.0 and elapsed-last_slow_render_log>5.0:
        last_slow_render_log=elapsed
        push_warning("UCMAK_SLOW_DRAW draw_ms=%.1f visible=%d zoom=%.2f" % [draw_ms,data.get("units",[]).size(),zoom])

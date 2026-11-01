extends RefCounted
var passed=0
var failed=0
func check(value:bool,name:String):
    if value: passed+=1; print("PASS_UI ",name)
    else: failed+=1; printerr("FAIL_UI ",name)
func run(root) -> bool:
    var f=root.field
    await root.get_tree().process_frame
    var q=Vector2(650,950)
    check(f.world(f.screen(q)).distance_to(q)<0.01,"camera roundtrip")
    var p=f.size/2
    var before=f.world(p)
    f.zoom_at(p,1.3)
    check(f.world(p).distance_to(before)<0.1,"zoom preserves anchor")
    f.select_wing(1); f.begin("line")
    var a=f.screen(Vector2(550,950)); var b=f.screen(Vector2(830,950))
    var original_field_size=f.size
    f.pointer_down(0,a); f.pointer_move(0,b); f.pointer_up(0,b)
    check(f.size==original_field_size,"preview keeps camera viewport stable")
    check(f.preview.size()>=2 and f.preview_error=="","line produces valid preview")
    var orders=Session.battle.metrics.orders
    f.confirm()
    check(Session.battle.metrics.orders==orders+1,"only confirmation submits line")
    f.begin("line"); f.pointer_down(0,a); f.pointer_move(0,b)
    f.pointer_down(1,b+Vector2(50,0))
    check(f.preview.is_empty(),"second finger cancels draft")
    f.pointer_move(1,b+Vector2(100,20)); f.pointer_up(1,b+Vector2(100,20)); f.pointer_up(0,b)
    check(Session.battle.metrics.orders==orders+1,"pinch release cannot issue an order")
    f.begin("line"); f.pointer_down(0,a); f.pointer_move(0,b); f.pointer_up(0,b,true)
    check(f.preview.is_empty(),"cancelled touch cancels draft")
    f.cancel(); var old_center=f.center
    f.pointer_down(0,Vector2(80,80)); f.pointer_move(0,Vector2(160,120)); f.pointer_up(0,Vector2(160,120))
    check(f.center.distance_to(old_center)>5,"single finger pans outside drawing mode")
    await root.get_tree().process_frame
    await root.get_tree().process_frame
    print("UI_LAYOUT dock=",root.dock.get_rect()," minimum=",root.dock.get_combined_minimum_size()," root=",root.size)
    check(root.dock.position.y>=0 and root.dock.position.y+root.dock.size.y<=root.size.y+2 and root.dock.position.x+root.dock.size.x<=root.size.x+2,"dock fits viewport")
    var touches=InputEventScreenTouch.new(); touches.index=2; touches.position=f.size/2; touches.pressed=true
    f._gui_input(touches)
    touches.pressed=false; touches.canceled=true; f._gui_input(touches)
    check(f.touches.is_empty(),"screen touch event path releases tracking")
    var saved=Session.view
    Session.view={}; root.refresh()
    check(f.data.is_empty(),"empty network snapshot never reveals enemy preview")
    f._process(0.1)
    check(f.visual_positions.is_empty(),"hidden positions removed from render interpolation")
    Session.view=saved; root.refresh()
    f.select_army()
    check(f.all_wings and f.selected_unit<0 and f.selected_wings()==Session.owned,"army selection uses only owned wings")
    f.begin("line")
    check(f.tool=="select","whole army cannot accidentally replace a single line")
    f.begin("advance")
    var target=f.screen(Vector2(700,980))
    f.pointer_down(0,target); f.pointer_up(0,target)
    check(Session.battle.queue.back().type=="advance" and Session.battle.queue.back().wings==Session.owned,"touch army order sends the whole selected group")
    f.select_wing(1)
    check(not f.all_wings and f.selected_wings()==[1],"single wing selection restores precise control")
    root.show_reports()
    check(root.is_menu_open and root.modal_box.get_child_count()>3,"report history opens with real simulation entries")
    root.close_modal()
    check(not root.is_menu_open,"report history closes back to live battle")
    await root.get_tree().process_frame
    var physical_scale=float(root.get_window().size.y)/root.size.y
    var tab_height=root.dock_content.get_child(0).get_child(0).size.y*physical_scale
    print("TOUCH_METRIC physical_scale=",physical_scale," tab_height_px=",tab_height)
    check(tab_height>=44,"primary hit targets remain at least 44 output pixels")
    f.selected_unit=6; root.rebuild_dock()
    await root.get_tree().process_frame
    await root.get_tree().process_frame
    check(root.dock.position.y+root.dock.size.y<=root.size.y+2,"individual company panel stays inside viewport")
    check(root.dock_scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED and root.dock_content.size.x<=root.dock_scroll.size.x+1,"command content has no horizontal clipping")
    root.dock_scroll.ensure_control_visible(root.command_options.get_child(0))
    await root.get_tree().process_frame
    check(root.command_options.get_global_rect().end.y<=root.dock.get_global_rect().end.y+1,"scroll exposes bottom company controls")
    root.show_details()
    check(root.is_menu_open and root.modal_box.get_child_count()>10,"company detail shows all ten skills")
    root.close_modal(); f.select_wing(1)
    print("UI_RESULT passed=",passed," failed=",failed," viewport=",root.size)
    return failed==0

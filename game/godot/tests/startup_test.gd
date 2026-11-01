extends RefCounted
## Test the actual "Talime başla" UI button, not just the battle model.
var passed=0
var failed=0
func check(ok:bool, name:String):
    if ok:
        passed+=1
        print("PASS_START ",name)
    else:
        failed+=1
        printerr("FAIL_START ",name)

func run(root:Control) -> bool:
    var t0=Time.get_ticks_msec()
    check(Session.phase=="menu" and root.is_menu_open,"initial menu is visible")
    check(is_instance_valid(root.training_button) and root.training_button.visible,"actual training button exists")
    check(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false)),"touchscreen taps reach Control buttons")
    var before=Session.battle.tick
    # Desktop CI cannot emulate an Android OS touch-to-mouse conversion reliably.
    # Exercise startup separately; verify the actual project touch setting above.
    root.training_button.pressed.emit()
    await root.get_tree().process_frame
    await root.get_tree().process_frame
    await root.get_tree().process_frame
    check(Session.phase=="battle" and Session.mode=="local","training button enters local battle")
    check(Session.battle.units.size()==36 and Session.view.units.size()>=18,"battle state and filtered snapshot initialized")
    check(not root.is_menu_open and not root.training_starting,"menu closed and start state released")
    check(Session.battle.tick>=before,"tick monotonic across start")
    if root.field.mobile_lod:
        check(root.field.terrain_view==null,"mobile safe mode allocates no terrain render target")
    else:
        check(is_instance_valid(root.field.terrain_view),"desktop terrain cache viewport exists")
        check(root.field.terrain_view.size==Vector2i(1400,1320) and root.field.terrain_view.get_texture()!=null,"desktop terrain texture available")
    var frame_start=root.field.render_frames
    var tick_start=Session.battle.tick
    await root.get_tree().create_timer(2.0).timeout
    check(Session.battle.tick>tick_start+10,"battle simulation continues for two real seconds")
    check(root.field.render_frames>=frame_start+4,"battlefield continues drawing after transition")
    check(root.field.data.get("units",[]).size()>0,"battlefield receives real snapshot")
    var elapsed=Time.get_ticks_msec()-t0
    check(elapsed<12000,"startup responds without prolonged stall")
    print("STARTUP_RESULT passed=",passed," failed=",failed," elapsed_ms=",elapsed," rendered=",root.field.render_frames," slowest_draw_ms=",root.field.slowest_render_ms)
    return failed==0

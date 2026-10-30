extends Control
const Field=preload("res://ui/battlefield.gd")
const Battle=preload("res://core/battle.gd")
const BG=Color("112d29")
const GOLD=Color("e1cb91")
var field
var top: PanelContainer
var dock: PanelContainer
var dock_content: VBoxContainer
var feed: Button
var title: Label
var detail: Label
var status: Label
var pause_button: Button
var confirm_row: HBoxContainer
var preview_label: Label
var modal: ColorRect
var modal_box: VBoxContainer
var address: LineEdit
var timer_label: Label
var previous_phase=""
var roster_size=-1
var is_menu_open=false
var toast: Label
var toast_left=0.0
var frame_times: Array=[]

func box(color:Color,border:Color=Color("37554a"),radius:int=12) -> StyleBoxFlat:
    var s=StyleBoxFlat.new(); s.bg_color=color
    s.border_color=border
    s.set_border_width_all(1); s.set_corner_radius_all(radius)
    s.content_margin_left=12; s.content_margin_right=12; s.content_margin_top=9; s.content_margin_bottom=9
    return s

func text(value:String,size_px:int=16,color:Color=Color("dce5d5")) -> Label:
    var l=Label.new(); l.text=value
    l.add_theme_font_size_override("font_size",size_px); l.add_theme_color_override("font_color",color)
    return l

func button(value:String,callback:Callable,accent:bool=false) -> Button:
    var b=Button.new(); b.text=value; b.custom_minimum_size=Vector2(0,50)
    b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    b.add_theme_stylebox_override("normal",box(GOLD if accent else Color("204139")))
    b.add_theme_stylebox_override("hover",box(Color("31584a")))
    b.add_theme_stylebox_override("pressed",box(Color("4c7660"),GOLD))
    b.add_theme_stylebox_override("disabled",box(Color("192e2b"),Color("263d35")))
    b.add_theme_color_override("font_color",BG if accent else Color("e3e6d3"))
    b.add_theme_font_size_override("font_size",16)
    b.pressed.connect(callback)
    return b

func _ready():
    var args=OS.get_cmdline_user_args()
    if args.has("--test-host") or args.has("--test-client"):
        var harness=load("res://tests/net_peer.gd").new()
        add_child(harness)
        return
    field=Field.new(); add_child(field)
    field.selection_changed.connect(rebuild_dock)
    field.preview_changed.connect(update_preview)
    field.hint.connect(show_hint)
    top=PanelContainer.new(); top.add_theme_stylebox_override("panel",box(BG)); add_child(top)
    var head=HBoxContainer.new(); head.add_theme_constant_override("separation",8); top.add_child(head)
    var brand=VBoxContainer.new(); brand.size_flags_horizontal=Control.SIZE_EXPAND_FILL; head.add_child(brand)
    brand.add_child(text("U Ç M A K",25,GOLD)); brand.add_child(text("CEPHE KOMUTASI  /  0.4",10,Color("a6b8a2")))
    timer_label=text("00:00",17); head.add_child(timer_label)
    pause_button=button("Ⅱ",func():
        if Session.mode=="local": Session.paused=not Session.paused
    )
    pause_button.custom_minimum_size.x=46; head.add_child(pause_button)
    var fit=button("⊡",func(): field.fit()); fit.custom_minimum_size.x=46; head.add_child(fit)
    var menu=button("≡",open_menu); menu.custom_minimum_size.x=46; head.add_child(menu)
    dock=PanelContainer.new(); dock.add_theme_stylebox_override("panel",box(BG)); add_child(dock)
    dock_content=VBoxContainer.new(); dock_content.add_theme_constant_override("separation",8); dock.add_child(dock_content)
    feed=button("KEŞİF  •  Raporlar burada akacak.",func():
        var reports=field.data.get("reports",[])
        if not reports.is_empty() and reports[0].pos.x>=0: field.center=reports[0].pos
    )
    feed.alignment=HORIZONTAL_ALIGNMENT_LEFT
    feed.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    feed.add_theme_font_size_override("font_size",14); add_child(feed)
    toast=text("",15,GOLD); toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
    toast.add_theme_stylebox_override("normal",box(Color(0.05,0.12,0.11,0.9)))
    add_child(toast)
    Session.changed.connect(refresh)
    Session.notice.connect(show_hint)
    resized.connect(layout_ui)
    layout_ui(); rebuild_dock(); refresh()
    if args.has("--visual-test") or args.has("--ui-test"):
        Session.offline(); field.selected_wing=1; field.selected_unit=-1
        Session.paused=true
        for i in range(740): Session.battle.step(0.05)
        Session.view=Session.battle.snapshot(0,true)
        refresh(); field.fit()
        await get_tree().process_frame
        if args.has("--ui-test"):
            var tests=load("res://tests/ui_test.gd").new()
            var ok=await tests.run(self)
            get_tree().quit(0 if ok else 1)
        else:
            await get_tree().create_timer(1.0).timeout
            await RenderingServer.frame_post_draw
            var output="user://battle.png"
            for a in args:
                if a.begins_with("--capture="): output=a.trim_prefix("--capture=")
            var image=get_viewport().get_texture().get_image()
            var error=image.save_png(output)
            print("VISUAL_CAPTURE ",output," ",image.get_size()," status=",error)
            get_tree().quit(0 if error==OK else 1)

func layout_ui():
    if field==null: return
    var landscape=size.x>size.y*1.15
    top.position=Vector2(8,8); top.size=Vector2(size.x-16,72)
    if landscape:
        dock.position=Vector2(size.x-300,88); dock.size=Vector2(292,size.y-96)
        field.position=Vector2(0,84); field.size=Vector2(size.x-308,size.y-84)
        feed.position=Vector2(12,size.y-82); feed.size=Vector2(maxf(150,field.size.x-146),70)
    else:
        var height=396.0 if field.selected_unit>=0 else 344.0
        if not field.preview.is_empty(): height+=52
        dock.position=Vector2(8,size.y-height-8); dock.size=Vector2(size.x-16,height)
        field.position=Vector2(0,84); field.size=Vector2(size.x,dock.position.y-88)
        feed.position=Vector2(12,dock.position.y-78); feed.size=Vector2(maxf(150,size.x-146),66)
    toast.position=Vector2(22,95); toast.size=Vector2(field.size.x-44,48)
    if is_instance_valid(modal):
        modal.position=Vector2.ZERO; modal.size=size
        var panel=modal.get_child(0)
        panel.position=Vector2(maxf(12,(size.x-420)/2),maxf(90,(size.y-600)/2))
        panel.size=Vector2(minf(size.x-24,420),minf(size.y-110,600))

func _process(dt):
    if field==null: return
    toast_left=maxf(0,toast_left-dt); toast.visible=toast_left>0
    pause_button.text="▶" if Session.paused else "Ⅱ"
    pause_button.disabled=Session.mode!="local"
    frame_times.append(dt)
    if frame_times.size()>120: frame_times.pop_front()

func show_hint(value:String):
    if toast==null: return
    toast.text=value; toast_left=4.0

func refresh():
    if field==null: return
    if Session.phase!=previous_phase:
        previous_phase=Session.phase
        if Session.phase=="battle":
            close_modal(); field.team=Session.team; field.selected_wing=Session.team*3+1; field.selected_unit=-1
            rebuild_dock()
        elif Session.phase in ["menu","lobby","connecting"]: open_menu()
    if Session.phase=="lobby" and roster_size!=Session.players.size():
        roster_size=Session.players.size(); open_menu()
    field.data=Session.view if not Session.view.is_empty() else Session.battle.snapshot(0,true)
    field.team=Session.team
    if Session.phase=="battle" and not field.selected_wing in Session.owned:
        if not Session.owned.is_empty(): field.selected_wing=Session.owned[0]; field.selected_unit=-1; rebuild_dock()
    var t=float(field.data.get("time",0))
    timer_label.text="%02d:%02d" % [int(t)/60,int(t)%60]
    update_status()
    var reports=field.data.get("reports",[])
    if not reports.is_empty():
        feed.text="%s  ·  %02d:%02d\n%s" % [reports[0].source,int(reports[0].time)/60,int(reports[0].time)%60,reports[0].text]
    if Session.phase=="battle" and int(field.data.get("winner",-1))>=0 and not is_menu_open: show_result()

func rebuild_dock():
    if dock_content==null: return
    for c in dock_content.get_children(): dock_content.remove_child(c); c.queue_free()
    var tabs=HBoxContainer.new(); tabs.add_theme_constant_override("separation",6); dock_content.add_child(tabs)
    for i in range(3):
        var id=Session.team*3+i
        var b=button(["Sol","Merkez","Sağ"][i],func(): field.select_wing(id),id==field.selected_wing and field.selected_unit<0)
        b.disabled=Session.phase=="battle" and not id in Session.owned
        tabs.add_child(b)
    title=text("Merkez",24,GOLD); dock_content.add_child(title)
    detail=text("Komutanınız hattı ve yedekleri yönetir.",13,Color("a9bca6")); detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; dock_content.add_child(detail)
    status=text("",13); dock_content.add_child(status)
    var actions=GridContainer.new(); actions.columns=3 if field.selected_unit>=0 else (2 if size.x>size.y*1.15 else 4)
    actions.add_theme_constant_override("h_separation",6); actions.add_theme_constant_override("v_separation",6)
    dock_content.add_child(actions)
    if field.selected_unit<0:
        actions.add_child(button("⌁\nHat çiz",func():field.begin("line"),true))
        actions.add_child(button("↗\nİlerle",func():field.begin("advance")))
        actions.add_child(button("◇\nTut",func(): Session.send({"type":"hold","wings":[field.selected_wing]})))
        actions.add_child(button("↶\nÇekil",func(): Session.send({"type":"withdraw","wings":[field.selected_wing]})))
    else:
        for pair in [["Hücum","attack"],["Mevzi","move"],["Keşif","scout"],["Su al","supply"],["Toparlan","retreat"]]:
            var kind=pair[1]
            actions.add_child(button(pair[0],func():field.begin(kind),kind=="attack"))
        actions.add_child(button("Geri çağır",func(): Session.send({"type":"return","unit":field.selected_unit})))
    var options=HBoxContainer.new(); dock_content.add_child(options)
    if field.selected_unit>=0:
        options.add_child(button("← Kanat",func():field.select_wing(field.selected_wing)))
    else:
        options.add_child(button("Yön çevir",func():Session.send({"type":"flip","wings":[field.selected_wing]})))
        var initiative=OptionButton.new(); initiative.custom_minimum_size=Vector2(110,44)
        for s in ["Sıkı emir","Dengeli","Serbest"]: initiative.add_item(s)
        var w=field.wing()
        initiative.select(["strict","balanced","free"].find(w.get("initiative","balanced")))
        initiative.item_selected.connect(func(i):Session.send({"type":"initiative","wings":[field.selected_wing],"value":["strict","balanced","free"][i]}))
        options.add_child(initiative)
    options.add_child(button("Bilgi",show_details))
    confirm_row=HBoxContainer.new(); dock_content.add_child(confirm_row)
    confirm_row.add_child(button("✓ Hattı onayla",func():field.confirm(),true))
    confirm_row.add_child(button("Vazgeç",func():field.cancel()))
    preview_label=text("",12,GOLD); preview_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; dock_content.add_child(preview_label)
    update_preview(); update_status(); layout_ui()

func update_preview():
    if confirm_row==null: return
    confirm_row.visible=not field.preview.is_empty()
    confirm_row.get_child(0).disabled=field.preview_error!=""
    preview_label.text=field.preview_error if field.preview_error!="" and not field.preview.is_empty() else "Çiz → onayla → komutan uygulasın."
    layout_ui()

func update_status():
    if title==null: return
    if field.selected_unit>=0:
        var u=field.unit(field.selected_unit)
        if u.is_empty(): return
        title.text=u.name
        detail.text=u.get("reason","")
        status.text="%d kişi  ·  Moral %d  ·  Dinçlik %d  ·  Su %d" % [u.men,u.get("morale",0),u.get("stamina",0),u.get("water",0)]
    else:
        var w=field.wing()
        if w.is_empty(): return
        title.text=w.name+("  ·  EMİR YOLDA" if w.pending else "")
        detail.text=w.commander.name+" · "+w.commander.trait+" · "+field.data.get("weather","Açık")
        var men=0.0
        for u in field.data.get("units",[]):
            if u.wing==w.id: men+=u.men
        status.text="%d kişi  ·  %d hat boşluğu  ·  Geçit %d%%" % [men,w.gaps,absf(field.data.get("control",0))]

func close_modal():
    is_menu_open=false
    if is_instance_valid(modal): remove_child(modal); modal.queue_free()
    modal=null

func make_modal():
    close_modal(); is_menu_open=true
    modal=ColorRect.new(); modal.color=Color(0.01,0.045,0.04,0.86); modal.mouse_filter=Control.MOUSE_FILTER_STOP; add_child(modal)
    var panel=PanelContainer.new(); panel.add_theme_stylebox_override("panel",box(BG,GOLD,18)); modal.add_child(panel)
    var scroll=ScrollContainer.new(); panel.add_child(scroll)
    modal_box=VBoxContainer.new(); modal_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    modal_box.add_theme_constant_override("separation",12); scroll.add_child(modal_box)
    layout_ui()

func paragraph(value:String):
    var l=text(value,15,Color("afc1ac")); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    modal_box.add_child(l)

func open_menu():
    make_modal()
    modal_box.add_child(text("U Ç M A K",34,GOLD))
    modal_box.add_child(text("CEPHE KOMUTASI  ·  GODOT 0.4",12))
    if Session.phase=="battle":
        paragraph("Tek parmak: seç / kaydır. İki parmak: yakınlaş / uzaklaş. Hat aracı çizimi ayrı tutar. Özel görevler kanat emirleriyle silinmez.")
        paragraph("Kazanmak için geçidi kontrol et veya düşmanın düzenli savaşma gücünü kır. Ağ maçında menü oyunu durdurmaz.")
        modal_box.add_child(button("Muharebeye dön",close_modal,true))
        modal_box.add_child(button("Ana menüye çık",func():Session.stop()))
    elif Session.phase=="lobby":
        paragraph("ODA  ·  %d / 4 komutan\n1–2 kişi: tam ordu. Müttefik eklenince sağ kanadı ikinci komutan yönetir." % Session.players.size())
        for id in Session.players:
            var s=int(Session.players[id])
            modal_box.add_child(text("%s  ·  %s" % ["Sancak A" if s%2==0 else "Sancak B","Başkomutan" if s<2 else "Kanat komutanı"],17))
        if Session.mode=="host":
            var addresses: Array=[]
            for ip in IP.get_local_addresses():
                if ip.begins_with("192.168.") or ip.begins_with("10."): addresses.append(ip)
            paragraph("Bağlantı: "+", ".join(addresses)+"\nUDP 24642 · Aynı Wi-Fi / erişilebilir sunucu")
            var start=button("Maçı başlat",func():Session.start_match(),true)
            start.disabled=Session.players.size()<2; modal_box.add_child(start)
        else: paragraph("Ev sahibinin maçı başlatması bekleniyor.")
        modal_box.add_child(button("Odadan ayrıl",func():Session.stop()))
    elif Session.phase=="connecting":
        paragraph("Sunucuya bağlanılıyor…")
        modal_box.add_child(button("İptal",func():Session.stop()))
    else:
        paragraph("Bir hattı yönet. Bir bölüğü göreve ayır. Yedeğin boşluğu kapatsın.\n\n18 dost ve 18 düşman bölüğü; nehir, keşif, moral ve gerçek zamanlı komuta.")
        modal_box.add_child(button("Talime başla  ·  AI rakip",func():Session.offline(),true))
        modal_box.add_child(button("Oda kur  ·  2–4 oyuncu",func():Session.host()))
        address=LineEdit.new(); address.placeholder_text="Sunucu IP adresi"; address.text="127.0.0.1"; address.custom_minimum_size.y=48
        modal_box.add_child(address)
        modal_box.add_child(button("Odaya katıl",func():Session.join(address.text)))
        paragraph("Bu sürüm doğrudan ENet bağlantısı kullanır. İnternet eşleştirme / oda kodu servisi henüz yok. İki telefonda aynı Wi-Fi ile ev sahibinin IP adresini kullan.")
        paragraph("Prototip rolleri tarihsel kadro doğrulaması değildir. Köyler, casuslar, tam çevre ve kalıcı sefer sistemi geliştirme kapsamındadır.")

func show_details():
    make_modal()
    if field.selected_unit>=0:
        var u=field.unit(field.selected_unit)
        modal_box.add_child(text(u.get("name","Bölük"),24,GOLD))
        paragraph("Mevcut: %d\nYaralı: %d\nMoral: %d\nDinçlik: %d\nSu: %d\nErzak: %d" % [u.get("men",0),u.get("wounded",0),u.get("morale",0),u.get("stamina",0),u.get("water",0),u.get("food",0)])
        for skill in Battle.SKILLS: paragraph("%s: %.1f" % [skill,u.get("xp",{}).get(skill,0)])
    else:
        var w=field.wing()
        modal_box.add_child(text(w.get("name","Kanat"),24,GOLD))
        paragraph("%s\n\nSıkı emir: yalnız yakındaki temasa tepki.\nDengeli: sınırlı yerel inisiyatif.\nSerbest: daha geniş temas alanı.\n\nAtılgan komutan daha geniş risk alır; temkinli komutan daha dar alanda kalır. Kişilik emrin yerine geçmez." % w.get("commander",{}).get("name",""))
    modal_box.add_child(button("Kapat",close_modal,true))

func show_result():
    make_modal()
    var winner=int(field.data.get("winner",2))
    modal_box.add_child(text("ZAFER" if winner==Session.team else "BERABERE" if winner==2 else "CEPHE DÜŞTÜ",30,GOLD))
    var men=0.0
    for u in field.data.get("units",[]):
        if u.team==Session.team: men+=u.men
    paragraph("Hayatta kalan: %d\nSüre: %02d:%02d\n\nBirliklerin görev tecrübesi bu maçta hesaplandı. Kalıcı sefer ve kayıt aktarımı henüz uygulanmadı." % [men,int(field.data.time)/60,int(field.data.time)%60])
    if Session.mode=="local": modal_box.add_child(button("Yeniden oyna",func():Session.offline(),true))
    modal_box.add_child(button("Ana menü",func():Session.stop()))

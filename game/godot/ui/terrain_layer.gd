extends Node2D
## Terrain is rendered once into a SubViewport; live battlefield only draws one quad.
const Terrain=preload("res://core/terrain.gd")
var grass: Array=[]
var trees: Array=[]
var cached_hills: Array=[]
var cached_river=PackedVector2Array()

func _ready():
    var rng=RandomNumberGenerator.new(); rng.seed=1402
    for i in range(360):
        var p=Vector2(rng.randf_range(25,1375),rng.randf_range(25,1295))
        grass.append([p,rng.randf_range(1,3)])
    for e in Terrain.FORESTS:
        for i in range(38):
            var angle=rng.randf()*TAU
            var r=sqrt(rng.randf())
            trees.append([Vector2(e.x+cos(angle)*e.z*r,e.y+sin(angle)*e.w*r),rng.randf_range(9,18)])
    for e in Terrain.HILLS:
        for ring in range(5,0,-1):
            var contour=PackedVector2Array()
            for i in range(49):
                var a=TAU*i/48.0
                contour.append(Vector2(e.x+cos(a)*e.z*ring/5.0,e.y+sin(a)*e.w*ring/5.0))
            cached_hills.append(contour)
    for x in range(0,1401,14): cached_river.append(Vector2(x,Terrain.river_y(x)))
    queue_redraw()

func _draw():
    draw_rect(Rect2(Vector2.ZERO,Terrain.SIZE),Color("858f6a"))
    for item in grass:
        draw_circle(item[0],item[1],Color(0.28,0.36,0.24,0.2))
    for contour in cached_hills:
        draw_polyline(contour,Color(0.85,0.83,0.62,0.27),1.4,true)
    draw_polyline(PackedVector2Array([Vector2(700,40),Vector2(680,300),Vector2(700,600),Vector2(690,950),Vector2(700,1290)]),Color("a3a079"),20,true)
    draw_polyline(PackedVector2Array([Vector2(90,200),Vector2(350,430),Vector2(350,660),Vector2(250,940),Vector2(60,1200)]),Color("a3a079"),13,true)
    draw_polyline(cached_river,Color("435e50"),78,true)
    draw_polyline(cached_river,Color("b1b08b"),69,true)
    draw_polyline(cached_river,Color("538986"),60,true)
    draw_polyline(cached_river,Color(0.52,0.76,0.72,0.32),38,true)
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

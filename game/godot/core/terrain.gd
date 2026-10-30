extends RefCounted
## Terrain is shared by authority, renderer and tests. No decorative soldier AI.
const SIZE = Vector2(1400, 1320)
const CELL = 28.0
const CROSSINGS = [350.0, 700.0, 1050.0]
const FORESTS = [Vector4(210,450,150,150), Vector4(1180,830,150,130), Vector4(1070,250,150,90), Vector4(410,1090,135,90)]
const HILLS = [Vector4(870,420,160,125), Vector4(390,850,150,110)]
var grid = AStarGrid2D.new()

func _init():
    grid.region = Rect2i(0,0,50,48)
    grid.cell_size = Vector2(CELL,CELL)
    grid.offset = Vector2(14,14)
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    grid.update()
    for y in range(48):
        for x in range(50):
            var p = Vector2(x*CELL+14,y*CELL+14)
            grid.set_point_solid(Vector2i(x,y),not walkable(p))
            grid.set_point_weight_scale(Vector2i(x,y),cost(p))

static func river_y(x: float) -> float:
    return 620.0+25.0*sin(x*0.006)+8.0*sin(x*0.017)

static func inside(p: Vector2, e: Vector4) -> bool:
    return pow((p.x-e.x)/e.z,2)+pow((p.y-e.y)/e.w,2)<1.0

static func kind(p: Vector2) -> String:
    if absf(p.y-river_y(p.x))<32:
        for x in CROSSINGS:
            if absf(p.x-x)<43:
                return "bridge" if x==700.0 else "ford"
        return "water"
    for e in FORESTS:
        if inside(p,e): return "forest"
    for e in HILLS:
        if inside(p,e): return "hill"
    return "grass"

static func walkable(p: Vector2) -> bool:
    return p.is_finite() and p.x>=24 and p.y>=24 and p.x<=1376 and p.y<=1296 and kind(p)!="water"

static func safe(p: Vector2) -> Vector2:
    var q = p.clamp(Vector2(28,28),SIZE-Vector2(28,28))
    if not walkable(q): q.y=river_y(q.x)+(-55 if q.y<river_y(q.x) else 55)
    return q

static func cost(p: Vector2) -> float:
    match kind(p):
        "forest": return 1.48
        "hill": return 1.18
        "ford": return 1.8
        _: return 1.0

static func clear(a: Vector2,b: Vector2) -> bool:
    var n = maxi(1,ceili(a.distance_to(b)/8))
    for i in range(1,n+1):
        if not walkable(a.lerp(b,float(i)/n)): return false
    return true

func cell(p: Vector2) -> Vector2i:
    var c = Vector2i(p/CELL).clamp(Vector2i(1,1),Vector2i(48,45))
    if not grid.is_point_solid(c): return c
    for r in range(1,5):
        for dy in range(-r,r+1):
            for dx in range(-r,r+1):
                var q=c+Vector2i(dx,dy)
                if grid.is_in_boundsv(q) and not grid.is_point_solid(q): return q
    return c

func path(a: Vector2,b: Vector2) -> Array:
    b=safe(b)
    if clear(a,b): return [b]
    var raw=grid.get_point_path(cell(a),cell(b))
    if raw.is_empty(): return []
    var route: Array=[]
    for p in raw: route.append(p)
    route.append(b)
    var result: Array=[]
    var origin=a
    var i=0
    while i<route.size():
        var best=i
        for j in range(i,route.size()):
            if clear(origin,route[j]): best=j
            else: break
        if not clear(origin,route[best]): return []
        result.append(route[best])
        origin=route[best]
        i=best+1
    return result

static func along(points: Array,t: float) -> Vector2:
    if points.is_empty(): return Vector2.ZERO
    var length=0.0
    for i in range(1,points.size()): length+=points[i-1].distance_to(points[i])
    var left=clampf(t,0,1)*length
    for i in range(1,points.size()):
        var d=points[i-1].distance_to(points[i])
        if left<=d: return points[i-1].lerp(points[i],left/maxf(d,0.01))
        left-=d
    return points.back()

static func validate_line(points: Array) -> String:
    if points.size()<2 or points.size()>12: return "2–12 noktalı bir hat çiz."
    var length=0.0
    for p in points:
        if not p is Vector2 or not p.is_finite(): return "Geçersiz konum."
        if not walkable(p): return "Hat kıyıda ve harita içinde olmalı."
    for i in range(points.size()-1):
        length+=points[i].distance_to(points[i+1])
        if not clear(points[i],points[i+1]): return "Hat nehir yatağından geçemez."
        for j in range(i+2,points.size()-1):
            if Geometry2D.segment_intersects_segment(points[i],points[i+1],points[j],points[j+1])!=null:
                return "Hat kendi üzerinden geçemez."
    if length<120: return "Hat çok kısa; biraz genişlet."
    if length>620: return "Hat çok geniş; bölükler kopar."
    if points[0].distance_to(points.back())<80: return "Hattın uçlarını ayır."
    return ""

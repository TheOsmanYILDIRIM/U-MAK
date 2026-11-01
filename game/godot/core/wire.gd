extends RefCounted
## Bounded compressed snapshots, split below ENet's MTU. Lost frames are superseded.
const CHUNK=900
const MAX_PARTS=64
const MAX_RAW=524288
var frames: Dictionary={}
var last=-1
static func pack(snapshot:Dictionary,permissions:Array) -> Array:
    var compressed=var_to_bytes({"state":snapshot,"owned":permissions}).compress(FileAccess.COMPRESSION_DEFLATE)
    var parts: Array=[]
    for i in range(0,compressed.size(),CHUNK): parts.append(compressed.slice(i,mini(i+CHUNK,compressed.size())))
    return parts
func clear():
    frames.clear(); last=-1
func consume(sequence:int,index:int,total:int,chunk:PackedByteArray) -> Dictionary:
    if sequence<=last or index<0 or index>=total or total<1 or total>MAX_PARTS or chunk.is_empty() or chunk.size()>CHUNK: return {}
    if not frames.has(sequence):
        if frames.size()>=4: frames.erase(frames.keys().min())
        frames[sequence]={"total":total,"parts":{}}
    var frame=frames[sequence]
    if frame.total!=total: frames.erase(sequence); return {}
    frame.parts[index]=chunk
    if frame.parts.size()!=total: return {}
    var packed=PackedByteArray()
    for i in range(total): packed.append_array(frame.parts[i])
    frames.erase(sequence)
    var raw=packed.decompress_dynamic(MAX_RAW,FileAccess.COMPRESSION_DEFLATE)
    if raw.is_empty(): return {}
    var message=bytes_to_var(raw)
    if not message is Dictionary or not message.get("state") is Dictionary or not message.get("owned") is Array: return {}
    if int(message.state.get("tick",-1))!=sequence: return {}
    last=sequence
    for key in frames.keys():
        if key<=last: frames.erase(key)
    return message

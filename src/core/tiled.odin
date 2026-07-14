package core;
import "../types"
import "../io"
import "core:os"

import "core:strings"
import "core:strconv"
import "core:path/filepath"

import "core:fmt"
import "core:encoding/xml"
import "core:encoding/json"

// TODO make a common struct with values many of theise use (like position, visible etcp)
Value :: union {
	i64, 
	f64, 
	bool, 
	string, 
}

Property :: struct {
    name, type: string,
    value: Value
}

Image :: struct {
    source: string,
    width, height: int
}

TileSet :: struct {
    name: string,
    firstgid, tilewidth, tileheight, tilecount, columns: int,
    image: Image,
    tilesheet: ^types.TileSheet
}
Object :: struct {
    id, gid: int,
    x, y, width, height: f32,
    visible: bool,
    name: string,
    class: string, // or type?
    layer_depth: int,
    properties: [dynamic]Property,
    point: bool
}

LayerBase :: struct {
    id: int,
    name: string,

    visible: bool,
    parallax: types.Vector2,
    layer_depth: int,
}

ObjectGroup :: struct {
    using base: LayerBase,

    width, height: int,
    draworder: string,
    objects: [dynamic]Object,
        
}
ImageLayer :: struct {
    using base: LayerBase, 
    image: string,
    width, height: int,
    imagewidth, imageheight, x, y, offsetx, offsety: f32,
    repeatx, repeaty: bool,
}
Layer :: struct {
    using base: LayerBase,
    width, height: int,
    data: [dynamic]int,
}
Map :: struct {
    orientation, renderorder: string, // TODO implement
    tilewidth, tileheight, infinite, nextlayerid, nextobjectid: int, //TODO implement
    width, height: f32,
    tilesets: [dynamic]TileSet,
    layers: [dynamic]Layer,
    objectgroups: [dynamic]ObjectGroup,
    imagelayers: [dynamic]ImageLayer
}

load_tsx :: proc(tileset: ^TileSet, path: string) {
    // FIXME real path
    fmt.println("INFO: loading tsx:",path)
    tmx_set := tileset
    doc, error := xml.load_from_file(path)



    for element in doc.elements {
        if element.ident == "tileset" {
            for attr in element.attribs {
                switch attr.key{
                case "name": tmx_set.name = fmt.tprintf(attr.val)
                case "tilewidth": if val,ok := strconv.parse_int(attr.val); ok do tmx_set.tilewidth = val
                case "tileheight": if val,ok := strconv.parse_int(attr.val); ok do tmx_set.tileheight = val
                case "columns": if val,ok := strconv.parse_int(attr.val); ok do tmx_set.columns = val
                }
            }
        }
        if element.ident == "image" {
            for attr in element.attribs {
                switch attr.key{
                case "source":
                    here := filepath.dir(path)
                    src,_ := filepath.join({here, attr.val})
                    tmx_set.image.source = fmt.tprintf(src) // TODO add path folder
                    created : bool
                    tmx_set.tilesheet, created = io.new_tilesheet(tmx_set.image.source, {cast(i32)tmx_set.tilewidth, cast(i32)tmx_set.tileheight})
                    if !created do panic("asd")
                    fmt.println("TILESHEET: ", tmx_set.image.source, tmx_set.tilesheet, created)

                case "width": if val,ok := strconv.parse_int(attr.val); ok do tmx_set.image.width = val
                case "height": if val,ok := strconv.parse_int(attr.val); ok do tmx_set.image.height = val
                }
            }
            
        }
    }
    
    xml.destroy(doc)
    fmt.println("result:", tmx_set)
}

load_layer :: proc(layer: json.Object, layer_depth: int) -> Layer {

    _layer := Layer({visible=true, layer_depth=layer_depth, parallax={1,1}});
    if v,ok := layer["width"].(json.Float); ok do _layer.width = cast(int)v
    if v,ok := layer["height"].(json.Float); ok do _layer.height = cast(int)v
    if v,ok := layer["name"].(json.String); ok do _layer.name = v
    if v,ok := layer["visible"].(json.Boolean); ok do _layer.visible = v
    if v,ok := layer["parallaxx"].(json.Float); ok do _layer.parallax.x = cast(f32)v
    if v,ok := layer["parallaxy"].(json.Float); ok do _layer.parallax.y = cast(f32)v
    if v,ok := layer["data"].(json.Array); ok {
        data := make([dynamic]int)
        for value in v {
            append(&data, cast(int)value.(json.Float))
        }
        _layer.data = data
    } 

    return _layer
}
load_imagelayer :: proc(layer: json.Object, path: string, layer_depth: int) -> ImageLayer {

    _layer := ImageLayer({visible=true,layer_depth = layer_depth,parallax={1,1}});
    if v,ok := layer["width"].(json.Float); ok do _layer.width = cast(int)v
    if v,ok := layer["height"].(json.Float); ok do _layer.height = cast(int)v
    if v,ok := layer["id"].(json.String); ok do _layer.name = v
    if v,ok := layer["name"].(json.String); ok do _layer.name = v
    if v,ok := layer["image"].(json.String); ok {
        here := filepath.dir(path)
        _path,_ := filepath.join({here, v})
         _layer.image = _path
    }
    if v,ok := layer["visible"].(json.Boolean); ok do _layer.visible = v
    if v,ok := layer["repeatx"].(json.Boolean); ok do _layer.repeatx = v
    if v,ok := layer["repeaty"].(json.Boolean); ok do _layer.repeaty = v
    if v,ok := layer["parallaxx"].(json.Float); ok do _layer.parallax.x = cast(f32)v
    if v,ok := layer["parallaxy"].(json.Float); ok do _layer.parallax.y = cast(f32)v
    if v,ok := layer["x"].(json.Float); ok do _layer.x = cast(f32)v
    if v,ok := layer["y"].(json.Float); ok do _layer.y = cast(f32)v
    if v,ok := layer["offsetx"].(json.Float); ok do _layer.offsetx = cast(f32)v
    if v,ok := layer["offsety"].(json.Float); ok do _layer.offsety = cast(f32)v
    if v,ok := layer["imagewidth"].(json.Float); ok do _layer.imagewidth = cast(f32)v
    if v,ok := layer["imageheight"].(json.Float); ok do _layer.imageheight = cast(f32)v


    return _layer
}

load_object :: proc (value: json.Object, layer_depth: int) -> Object {
    object := Object({gid=-1, visible=true, layer_depth = layer_depth})

    if v,ok := value["name"].(json.String); ok do object.name = v
    if v,ok := value["type"].(json.String); ok do object.class = v
    if v,ok := value["gid"].(json.Float); ok do object.gid = cast(int)v
    if v,ok := value["id"].(json.Float); ok do object.id = cast(int)v
    if v,ok := value["width"].(json.Float); ok do object.width = cast(f32)v
    if v,ok := value["height"].(json.Float); ok do object.height = cast(f32)v
    if v,ok := value["visible"].(json.Boolean); ok do object.visible = v
    if v,ok := value["point"].(json.Boolean); ok do object.point = v
    if v,ok := value["x"].(json.Float); ok do object.x = cast(f32)v
    if v,ok := value["y"].(json.Float); ok do object.y = cast(f32)v
    if v,ok := value["properties"].(json.Array); ok {
        for el in v {
            prop := Property({})
            #partial switch val in el {
                case json.Object:
                #partial switch type in val["value"] {
                    case json.Integer : prop.value=type
                    case json.Float   : prop.value=type
                    case json.Boolean : prop.value=type
                    case json.String  : prop.value=type
                }
                prop.name = val["name"].(json.String)
                prop.type = val["type"].(json.String)
            }
            append(&object.properties, prop)
        }
    }
    
    // TODO add properties
    return object

}

load_objectgroup :: proc(layer: json.Object, layer_depth: int) -> ObjectGroup {

    objectgroup := ObjectGroup({visible=true, layer_depth = layer_depth});
    if v,ok := layer["draworder"].(json.String); ok do objectgroup.draworder = v
    if v,ok := layer["name"].(json.String); ok do objectgroup.name = v
    if v,ok := layer["id"].(json.Float); ok do objectgroup.id = cast(int)v
    if v,ok := layer["visible"].(json.Boolean); ok do objectgroup.visible = v
    if v,ok := layer["parallaxx"].(json.Float); ok do objectgroup.parallax.x = cast(f32)v
    if v,ok := layer["parallaxy"].(json.Float); ok do objectgroup.parallax.y = cast(f32)v
    if v,ok := layer["objects"].(json.Array); ok {
        objects := make([dynamic]Object)
        for value in v {
            append(&objects, load_object(value.(json.Object), layer_depth))
        }
        objectgroup.objects = objects
    } 

    return objectgroup
}

load_tileset :: proc(tileset: json.Object, path: string) -> TileSet {
    _tileset := TileSet({})
    if v,ok := tileset["firstgid"].(json.Float); ok do _tileset.firstgid = cast(int)v
    if v,ok := tileset["source"].(json.String); ok {
        here := filepath.dir(path)
        _path,_ := filepath.join({here, v})
        // CHECK IF JSON OR TMX
        //load_tsx(&_tileset, _path)
        // delete(here)
        delete(_path)
    } 
    return _tileset
}

load_map :: proc(path: string) -> ^Map {
    data, read_err := os.read_entire_file(path, context.allocator)
	  if read_err != nil {
		    fmt.eprintfln("Failed to load the file: %v", read_err)
		    return nil
	  }
	  defer delete(data)
    _map:= new(Map)
    value, error := json.parse(data)
    #partial switch v in value {
        case json.Object:
        _map.width = cast(f32)v["width"].(json.Float)
        _map.height = cast(f32)v["height"].(json.Float)
        _map.nextlayerid = cast(int)v["nextlayerid"].(json.Float)
        _map.nextobjectid = cast(int)v["nextobjectid"].(json.Float)
        _map.orientation = v["orientation"].(json.String)
        _map.renderorder = v["renderorder"].(json.String)
        //_map.tiledversion =v["tiledversion"].(json.String)
        _map.tilewidth = cast(int)v["tilewidth"].(json.Float)
        _map.tileheight = cast(int)v["tileheight"].(json.Float)

        layer_depth := -len(v["layers"].(json.Array))
        for layer in v["layers"].(json.Array) {
            switch layer.(json.Object)["type"].(json.String)  {
            case "tilelayer": append(&_map.layers,load_layer(layer.(json.Object), layer_depth))
            case "objectgroup": append(&_map.objectgroups,load_objectgroup(layer.(json.Object), layer_depth))
            case "imagelayer": append(&_map.imagelayers,load_imagelayer(layer.(json.Object), path, layer_depth))
            }
            layer_depth += 1
        }
        for tileset in v["tilesets"].(json.Array) {
            append(&_map.tilesets,load_tileset(tileset.(json.Object), path))
        }

        case:
        fmt.println("WARNING: no real map")
    }
    json.destroy_value(value)
    return _map
}


destroy :: proc(_map: ^Map) {
    for layer in _map.layers {
        delete(layer.data)
    }
    for objectgroup in _map.objectgroups {
        delete(objectgroup.objects)
    }
    for tileset in _map.tilesets {
        if tileset.tilesheet != nil do io.free_tilesheet(tileset.tilesheet)
    }

    delete(_map.tilesets)
    delete(_map.layers)
    delete(_map.objectgroups)
    delete(_map.imagelayers)
    free(_map)
}

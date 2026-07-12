package core;
import "../types"
import "../io"

import "core:strings"
import "core:strconv"
import "core:path/filepath"

import "core:fmt"
import "core:encoding/xml"

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
Layer :: struct {
    id, name: string,
    width, height: int,
    data: [dynamic]int
}
Map :: struct {
    orientation, renderorder: string, // TODO implement
    width, height, tilewidth, tileheight, infinite, nextlayerid, nextobjectid: int, //TODO implement
    tilesets: [dynamic]TileSet,
    layers: [dynamic]Layer
}

load_tsx :: proc(tileset: TileSet, path: string) -> TileSet{
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
    return tmx_set
}

load_tmx :: proc(path: string) -> ^Map {
    tmx_map := new(Map);
    doc, error := xml.load_from_file(path)
    indexes : [dynamic]int
    layer := Layer({})
    tileset := TileSet({})
    for element in doc.elements {
        if element.ident == "map" {
            for attr in element.attribs {
                switch attr.key{
                case "orientation": tmx_map.orientation = fmt.tprintf(attr.val)
                case "renderorder": tmx_map.renderorder = fmt.tprintf(attr.val)
                case "width": if val,ok := strconv.parse_int(attr.val); ok do tmx_map.width = val
                case "height": if val,ok := strconv.parse_int(attr.val); ok do tmx_map.height = val
                case "tilewidth": if val,ok := strconv.parse_int(attr.val); ok do tmx_map.tilewidth = val
                case "tileheight": if val,ok := strconv.parse_int(attr.val); ok do tmx_map.tileheight = val
                case "infinite": if val,ok := strconv.parse_int(attr.val); ok do tmx_map.infinite = val
                case "nextlayerid": if val,ok := strconv.parse_int(attr.val); ok do tmx_map.nextlayerid = val
                case "nextobjectid": if val,ok := strconv.parse_int(attr.val); ok do tmx_map.nextobjectid = val
                }
            }
        }
        if element.ident == "layer" {
            indexes = make([dynamic]int) // we allocate memory for the data 
            for attr in element.attribs {
                switch attr.key{
                case "id": layer.id = fmt.tprintf(attr.val)
                case "name": layer.name = fmt.tprintf(attr.val)
                case "width" : if val,ok := strconv.parse_int(fmt.tprintf(attr.val)); ok do layer.width = val
                case "height": if val,ok := strconv.parse_int(attr.val); ok do layer.height = val
                }
            }
        }
        if element.ident == "tileset" {
            for attr in element.attribs {
                switch attr.key {
                case "firstgid": if val,ok := strconv.parse_int(attr.val); ok do tileset.firstgid = val
                case "source":
                    // FIXME
                    here := filepath.dir(path)
                    _path,_ := filepath.join({here, attr.val})
                    fmt.println("LOAD TSX:", _path)
                    tileset = load_tsx(tileset,_path)
                }
            }
            append(&tmx_map.tilesets, tileset)
            tileset = TileSet({})
        }
        if element.ident == "data" {
            #partial switch v in element.value[0] {
                case string:
                values := strings.split(v, ",")
                for value in values{
                    // CSV rows have trailing commas + newlines, so tokens like
                    // "\n0" appear; trim whitespace or parse_int drops them
                    // (which silently dropped the first tile of every row).
                    trimmed := strings.trim_space(value)
                    if trimmed == "" do continue
                    if value, could := strconv.parse_int(trimmed); could  {
                        append(&indexes, value)
                    }
                }
                delete(values)
            }
            layer.data = indexes
            append(&tmx_map.layers, layer)
        }
    }
    xml.destroy(doc)
    return tmx_map
}

create_tilemap :: proc(_map: ^Map) -> types.TileMap {
    tmap := types.TileMap({})
    tmap.width = _map.width
    tmap.height = _map.height

    
    // tilesheet := io.new_tilesheet("./game/assets/FREE_Fantasy Forest/Tiles/Tileset Outside.png", {32,32})
    // floor_tiles := make([dynamic]^types.Image)
    // fmt.println("len", len(tilesheet.images), len(tilesheet.images[0]))
    // for layer in _map.layers {
    //     for value in layer.data {
    //         if value == 0 do append(&floor_tiles, nil)
    //         else {
    //             x := (value-1) % (_map.tileSet.columns);
    //             y := (value-1) / (_map.tileSet.columns);
    //             fmt.println(value-1,x,y)
    //             append(&floor_tiles, tilesheet.images[y][x])
    //         }
    //     }
    // }



    // tmap.tiles = floor_tiles
    return tmap
}


destroy :: proc(_map: ^Map) {
    for layer in _map.layers {
        delete(layer.data)
    }
    
    delete(_map.layers)
    free(_map)

}

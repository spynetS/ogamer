package scripting;
import es "../event-system"
import "../ecs/types"



is_key_down :: proc(key: types.KeyboardKey) -> bool {
    for i in 0..<len(types.keys) {
        if types.keys[i] == key do return true
    }
    return false;
}

is_key_pressed :: proc(key: types.KeyboardKey) -> bool {
    for event in es.event_queue_poll() {
        #partial switch ev in event {
        case es.Event_Key_Pressed:
            if ev.key == key do return true
        }
    }
    return false
}


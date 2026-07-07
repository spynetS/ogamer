package scripting;
import es "../event-system"
import "../types"



is_key_down :: proc(key: types.KeyboardKey) -> bool {
    for i in 0..<len(types.keys) {
        if types.keys[i] == key do return true
    }
    return false;
}

is_key_pressed :: proc(key: types.KeyboardKey) -> bool {
    for event in es.event_queue_poll() {
        #partial switch ev in event {
        case types.Event_Key_Pressed:
            if ev.key == key do return true
        }
    }
    return false
}

is_mouse_down :: proc(mouse_button: types.MouseButton) -> bool {
    for i in 0..<len(types.mouse_buttons) {
        if types.mouse_buttons[i] == mouse_button do return true
    }
    return false;
}

is_mouse_pressed :: proc(mouse_button: types.MouseButton) -> bool {
    for event in es.event_queue_poll() {
        #partial switch ev in event {
        case types.Event_MouseButton_Pressed:
            if ev.button == mouse_button do return true
        }
    }
    return false
}



package ogamer_input;
import es "../events"



is_key_down :: proc(key: KeyboardKey) -> bool {
    for i in 0..<len(keys) {
        if keys[i] == key do return true
    }
    return false;
}

is_key_pressed :: proc(eventQueue: ^es.EventQueue, key: KeyboardKey) -> bool {
    for event in es.event_queue_poll(eventQueue) {
        #partial switch ev in event {
        case es.Key_Pressed:
            if ev.key == i32(key) do return true
        }
    }
    return false
}

is_mouse_down :: proc(mouse_button: MouseButton) -> bool {
    for i in 0..<len(mouse_buttons) {
        if mouse_buttons[i] == mouse_button do return true
    }
    return false;
}

is_mouse_pressed :: proc(eventQueue: ^es.EventQueue, mouse_button: MouseButton) -> bool {
    for event in es.event_queue_poll(eventQueue) {
        #partial switch ev in event {
        case es.MouseButton_Pressed:
            if ev.button == i32(mouse_button) do return true
        }
    }
    return false
}

// THESE has to be implemented by someting (RENDERER OFTEN)
get_mouse_position : proc() -> [2]f32
get_world_mouse_position : proc() -> [2]f32

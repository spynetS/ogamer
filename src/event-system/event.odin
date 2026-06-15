package event;
import "../ecs/types"

Event_Key_Pressed :: struct {
    key: types.KeyboardKey,
}
Event_Key_Released :: struct {
    key: types.KeyboardKey,
}


// The union of all possible events
Event :: union {
    Event_Key_Pressed,
}

events: [dynamic]Event


event_queue_init :: proc() {
    events = make([dynamic]Event, 0, 64)
}

event_queue_destroy :: proc() {
    delete(events)
}

emit :: proc(e: Event) {
    append(&events, e)
}

event_queue_clear :: proc() {
    clear(&events)
}

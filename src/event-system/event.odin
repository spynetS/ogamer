package event;
import "core:fmt"
import "../ecs/types"

Event_Key_Pressed :: struct {
    key: types.KeyboardKey,
}
Event_Key_Released :: struct { // TODO add so it gets emited
    key: types.KeyboardKey,
}
Event_Collision_Entered :: struct {
    a: ^types.RigidBody,
    b: ^types.RigidBody
}
Event_Collision_Left :: struct {
    a: ^types.RigidBody,
    b: ^types.RigidBody
}
Event_Collision_Hit :: struct {
    a: ^types.RigidBody,
    b: ^types.RigidBody
}

// The union of all possible events
Event :: union {
    Event_Key_Pressed,
    Event_Key_Released,
    Event_Collision_Entered,
    Event_Collision_Left,
    Event_Collision_Hit,
}

events: [dynamic]Event


event_queue_init :: proc() {
    events = make([dynamic]Event, 0, 64)
}

event_queue_destroy :: proc() {
    delete(events)
}

emit :: proc(e: Event) {
    fmt.println("INFO: New Event", e)
    append(&events, e)
}

event_queue_clear :: proc() {
    clear(&events)
}

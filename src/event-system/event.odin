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
Event_SpriteAnimator_End :: struct {
    animator: ^types.SpriteAnimator
}
Event_Should_Close_Window :: struct {

}

// The union of all possible events
Event :: union {
    Event_Key_Pressed,
    Event_Key_Released,
    Event_Collision_Entered,
    Event_Collision_Left,
    Event_Collision_Hit,
    Event_SpriteAnimator_End,
    Event_Should_Close_Window,
}

next_events    : [dynamic]Event
current_events : [dynamic]Event


event_queue_init :: proc() {
    next_events    = make([dynamic]Event, 0, 64)
    current_events = make([dynamic]Event, 0, 64)
}

event_queue_destroy :: proc() {
    delete(next_events)
    delete(current_events)
}

emit :: proc(e: Event) {
    fmt.println("INFO: New Event", e)
    append(&next_events, e)
}

event_queue_clear :: proc() {
    current_events, next_events = next_events, current_events
    clear(&next_events)
}

event_queue_poll :: proc() -> [dynamic]Event {
    return current_events
}

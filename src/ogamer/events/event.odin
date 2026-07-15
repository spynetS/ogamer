package ogamer_events;
import "core:fmt"


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
    fmt.println("INFO: New =Event", e)
    append(&next_events, e)
}

event_queue_clear :: proc() {
    current_events, next_events = next_events, current_events
    clear(&next_events)
}

event_queue_poll :: proc() -> [dynamic]Event {
    return current_events
}

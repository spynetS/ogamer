package ogamer_events;
import "core:fmt"

new_eventQueue :: proc() -> ^EventQueue {
    eq := new(EventQueue)
    event_queue_init(eq)
    return eq
}

event_queue_init :: proc(eventQueue: ^EventQueue) {
    eventQueue.next_events    = make([dynamic]Event, 0, 64)
    eventQueue.current_events = make([dynamic]Event, 0, 64)
}

event_queue_destroy :: proc(eventQueue: ^EventQueue) {
    delete(eventQueue.next_events)
    delete(eventQueue.current_events)
}

emit :: proc(eventQueue: ^EventQueue, e: Event) {
    fmt.println("INFO: New =Event", e)
    append(&eventQueue.next_events, e)
}

event_queue_clear :: proc(eventQueue: ^EventQueue) {
    eventQueue.current_events, eventQueue.next_events = eventQueue.next_events, eventQueue.current_events
    clear(&eventQueue.next_events)
}

event_queue_poll :: proc(eventQueue: ^EventQueue) -> [dynamic]Event {
    return eventQueue.current_events
}

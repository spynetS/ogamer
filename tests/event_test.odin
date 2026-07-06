package tests

import "core:testing"
import es "../src/event-system"
import "../src/types"

// The event queue is package-level global state (not per-instance), so all
// assertions live in a single test to avoid racing with other tests under
// the parallel test runner.
@(test)
test_event_queue_double_buffering :: proc(t: ^testing.T) {
    es.event_queue_init()
    defer es.event_queue_destroy()

    // emit only queues into next_events; poll reads current_events, which
    // starts out empty until the first clear/swap.
    es.emit(types.Event_Key_Pressed{key = types.KeyboardKey.A})
    testing.expect_value(t, len(es.event_queue_poll()), 0)

    es.event_queue_clear()
    events := es.event_queue_poll()
    testing.expect_value(t, len(events), 1)

    #partial switch v in events[0] {
    case types.Event_Key_Pressed:
        testing.expect_value(t, v.key, types.KeyboardKey.A)
    case:
        testing.fail_now(t, "expected Event_Key_Pressed")
    }

    // a clear with nothing newly emitted should surface no events
    es.event_queue_clear()
    testing.expect_value(t, len(es.event_queue_poll()), 0)
}

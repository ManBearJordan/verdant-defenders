extends GutTest

var dc_script = load("res://scripts/DungeonController.gd")
var dc = null

func before_each():
	dc = dc_script.new()
	add_child_autofree(dc)

func test_start_run_emits_choices():
	watch_signals(dc)
	dc.start_run()
	assert_signal_emitted(dc, "choices_ready")
	
func test_choose_room_emits_room_entered():
	watch_signals(dc)
	dc.start_run()
	
	# Wait for choices or just assume they are ready since it's synchronous in our impl
	dc.choose_room(0)
	
	assert_signal_emitted(dc, "room_entered")
	assert_eq(dc.room_counter, 0, "Counter should be 0 (will check logic)")

func test_room_loop_progression():
	dc.start_run()
	
	# Simulate clearing a room
	dc.next_room()
	
	# Should get new choices
	# Since start_run gives initial choices, next_room gives 2nd set
	# We didn't spy on choices yet, let's verify logic state
	assert_eq(dc.room_counter, 1)

func test_floor_completion():
	dc.start_run()
	watch_signals(dc)
	
	# Advance 10 rooms
	for i in range(10):
		dc.next_room()
		
	assert_signal_emitted(dc, "floor_cleared")

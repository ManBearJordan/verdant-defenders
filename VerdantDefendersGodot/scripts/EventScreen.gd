extends Control

# EventScreen.gd
# Visual Interface for Event Encounters

@onready var title_label = $Panel/VBox/Title
@onready var image_rect = $Panel/VBox/Image
@onready var desc_label = $Panel/VBox/Description
@onready var choices_container = $Panel/VBox/Choices

var event_controller: Node
var current_event_data: Dictionary = {}

func _ready() -> void:
	event_controller = get_node_or_null("/root/EventController")
	if event_controller:
		event_controller.event_started.connect(_on_event_started)
		
		# Check if already active? 
		if not event_controller._current_event.is_empty():
			_on_event_started(event_controller._current_event)
			
func _on_event_started(data: Dictionary) -> void:
	current_event_data = data
	
	title_label.text = data.get("title", "Unknown Event")
	desc_label.text = data.get("text", "...")
	
	# Image
	var img_path = data.get("image", "")
	if img_path != "":
		# Load if exists, else generic
		pass
		
	# Choices
	for c in choices_container.get_children():
		c.queue_free()
		
	var choices = data.get("choices", [])
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		btn.text = choice.get("text", "Continue")
		btn.tooltip_text = choice.get("tooltip", "")
		btn.custom_minimum_size = Vector2(0, 50)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Validation check (costs)
		# Needs access to run state to see if affordable
		var outcome = choice.get("outcome", {})
		if "cost_hp" in outcome:
			# Check HP
			pass
			
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)

func _on_choice_pressed(idx: int) -> void:
	if event_controller:
		event_controller.select_choice(idx)
		# Navigation handled by RunController via signals or EventController callback
		# EventController emits event_completed.
		# Who listens? RunController?
		# Currently RunController.goto_event() just changes screen.
		# Does RunController listen to EventController? Not yet.
		# We should probably hook this up.
		
		# For now, let's manually return to map here or via RC
		var rc = get_node_or_null("/root/RunController")
		if rc: rc.return_to_map()

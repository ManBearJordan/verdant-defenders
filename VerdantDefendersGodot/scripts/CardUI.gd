extends Panel

var card_id := ""
var card_data: Resource = null

func setup(id: String):
	card_id = id
	card_data = DataLayer.get_card(id)

	$VBox/Title.text = card_data.name if "name" in card_data else id
	$VBox/Cost.text = "Cost: %d" % (card_data.cost if "cost" in card_data else 1)
	$VBox/Description.text = card_data.description if "description" in card_data else ""

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cost = card_data.cost if "cost" in card_data else 1
		var card_system = get_node_or_null("/root/CardSystem")
		if card_system == null or card_system.energy < cost:
			print("Not enough energy.")
			return

		var targeting_system = get_node_or_null("/root/TargetingSystem")
		if targeting_system == null:
			print("TargetingSystem not found.")
			return
			
		var target = targeting_system.current_target
		if not target:
			print("No target selected.")
			return

		print("Played card %s on %s" % [card_id, target.name])
		card_system.play_card(card_id, target)
		targeting_system.clear_target()
		queue_free()

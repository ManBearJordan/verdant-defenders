extends Panel

var card_id := ""
var card_data := {}

func setup(id: String):
	card_id = id
	card_data = DataLayer.get_card(id)

	$VBox/Title.text = card_data.get("name", id)
	$VBox/Cost.text = "Cost: %d" % card_data.get("cost", 1)
	$VBox/Description.text = card_data.get("description", "")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var cost = card_data.get("cost", 1)
		if CardSystem.energy < cost:
			print("Not enough energy.")
			return

		var target = TargetingSystem.get_target()
		if not target:
			print("No target selected.")
			return

		print("Played card %s on %s" % [card_id, target.name])
		CardSystem.play_card(card_id, target)
		TargetingSystem.clear_target()
		queue_free()

extends Control

func show_summary(data: Dictionary):
	var _game = get_node("/root/GameController")
	var text = ""

	text += "[center][b]Overgrowth - Run Summary[/b][/center]\n\n"
	text += "Class: %s\n" % data.get("class", "Unknown")
	text += "Result: %s\n" % data.get("result", "???")
	text += "Duration: %d minutes\n" % data.get("duration_minutes", 0)
	text += "Layer Reached: %s\n" % data.get("layer_reached", "???")
	text += "Shards Earned: %d\n" % data.get("shards_earned", 0)
	text += "World Seed Bonus: +%d\n" % data.get("world_seed_level", 0)
	text += "\n[b]Deck:[/b]\n"

	for card in data.get("deck", []):
		text += "- %s\n" % card

	text += "\n[b]Sigils:[/b]\n"
	for sigil in data.get("sigils", []):
		text += "- %s\n" % sigil

	text += "\n[b]Stats:[/b]\n"
	for stat_key in data.get("stats", {}).keys():
		text += "%s: %s\n" % [stat_key.capitalize().replace("_", " "), str(data["stats"][stat_key])]

	$Panel/VBox/Stats.clear()
	$Panel/VBox/Stats.append_bbcode(text)
	self.visible = true

func _ready():
	$Panel/VBox/ReturnButton.connect("pressed", _on_return_pressed)

func _on_return_pressed():
	get_tree().change_scene("res://Scenes/StartScreen.tscn")

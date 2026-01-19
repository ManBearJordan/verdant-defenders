extends Node
class_name TargetingSystem

signal target_changed(new_target: Node)

var current_target: Node = null
var _last_highlight: Node = null

# Select (or toggle off) the current enemy target.
func set_target(target: Node) -> void:
	if target == current_target:
		_set_highlight(target, false)
		current_target = null
		emit_signal("target_changed", null)
		return

	if _last_highlight:
		_set_highlight(_last_highlight, false)

	current_target = target
	_last_highlight = target
	_set_highlight(target, true)
	emit_signal("target_changed", target)

func clear_target() -> void:
	if current_target:
		_set_highlight(current_target, false)
	current_target = null
	emit_signal("target_changed", null)

# Optional helper: pick the first alive enemy under a given parent node.
func pick_first_alive(enemies_root: Node) -> void:
	if enemies_root == null:
		clear_target()
		return
	for c in enemies_root.get_children():
		if c and c.has_method("get_current_hp"):
			var hp := int(c.call("get_current_hp"))
			if hp > 0:
				set_target(c)
				return
	clear_target()

func _set_highlight(node: Node, on: bool) -> void:
	if node == null:
		return
	# If enemy implements set_highlight(on), use it.
	if node.has_method("set_highlight"):
		node.call("set_highlight", on)
		return
	# Otherwise, if there's a child named "Highlight" that is a CanvasItem, toggle visibility.
	if node.has_node("Highlight"):
		var n := node.get_node("Highlight")
		if n is CanvasItem:
			(n as CanvasItem).visible = on

extends Control

@onready var ec = get_node_or_null("/root/EventController")
@onready var gc = get_node_or_null("/root/GameController")
@onready var dm = get_node_or_null("/root/DeckManager")

var _card_selector: ScrollContainer

func _ready() -> void:
    if not ec:
        push_error("EventUI: No EventController found")
        queue_free()
        return
        
    ec.event_started.connect(_on_event_started)
    ec.event_completed.connect(_on_event_completed)
    
    # Start an event immediately
    ec.start_random_event()

func _on_event_started(event_data: Dictionary) -> void:
    _build_ui(event_data)

func _on_event_completed() -> void:
    # Handle post-event cleanup or closing
    # Usually we wait for user to click "Leave" which triggers completion
    queue_free()
    
    # Notify DungeonController to move on
    var dc = get_node_or_null("/root/DungeonController")
    if dc and dc.has_method("next_room"):
        dc.next_room()

func _build_ui(data: Dictionary) -> void:
    var root = get_node_or_null("Panel/VBox")
    if not root: return
    
    for c in root.get_children():
        c.queue_free()
        
    # Title
    var title = Label.new()
    title.text = data.get("title", "Event")
    title.add_theme_font_size_override("font_size", 24)
    root.add_child(title)
    
    # Text
    var desc = RichTextLabel.new()
    desc.text = data.get("text", "...")
    desc.fit_content = true
    desc.custom_minimum_size.y = 100
    root.add_child(desc)
    
    root.add_child(HSeparator.new())
    
    # Choices
    var choices = data.get("choices", [])
    for i in range(choices.size()):
        var choice = choices[i]
        var btn = Button.new()
        btn.text = choice.get("text", "Continue")
        
        # Check specific "removal" logic which implies UI intervention BEFORE outcome
        # But EventController applies outcome immediately on select.
        # If "remove_card" type, we might need to intercept.
        var outcome = choice.get("outcome", {})
        if outcome.get("type") == "remove_card":
            btn.pressed.connect(_on_remove_card_pressed)
        else:
            btn.pressed.connect(func(): ec.select_choice(i))
            
        root.add_child(btn)

func _on_remove_card_pressed() -> void:
    # Open card selector
    # Usually reusing a generic selector component is best.
    # For now, build a simple one here.
    var root = get_node_or_null("Panel")
    if not root: return
    
    if _card_selector: _card_selector.queue_free()
    
    _card_selector = ScrollContainer.new()
    _card_selector.set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg = ColorRect.new()
    bg.color = Color(0,0,0,0.9)
    _card_selector.add_child(bg) # Wrong parenting, but OK for quick UI
    
    # Correct structure:
    var overlay = Panel.new()
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(overlay)
    
    var flow = FlowContainer.new()
    flow.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(flow)
    
    if dm:
        var cards = dm.get_all_cards()
        for c in cards:
            var b = Button.new()
            b.text = c.get("name", "Card")
            b.custom_minimum_size = Vector2(120, 160)
            b.pressed.connect(func():
                dm.remove_card(c)
                ec._current_event = {} # Clear event
                ec.event_completed.emit() # Manually trigger completion
                overlay.queue_free()
            )
            flow.add_child(b)
            
    var cancel = Button.new()
    cancel.text = "Cancel"
    cancel.pressed.connect(func(): overlay.queue_free())
    overlay.add_child(cancel)

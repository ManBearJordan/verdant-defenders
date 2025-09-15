const CardDatabase = preload("res://scripts/CardDatabase.gd")
extends Node2D

# Handles deck setup and drawing cards to the hand

const STARTER_DECK : Array[String] = [
    # Strikes
    "Thorn Lash", "Blossom Strike", "Vine Whip", "Bud Burst", "Petal Spray",
    "Root Smash", "Sap Shot", "Thorned Blade", "Gilded Bud", "Blooming Edge",
    # Tactics
    "Seed Shield", "Vine Trap", "Sprout Heal", "Fertile Soil", "Rooting Pulse",
    "Seedlings", "Thorn Wall", "Petal Veil", "Sap Shield", "Bud Barrier",
    # Rituals
    "Growth Ritual", "Garden Bloom", "Growth Aura", "Seed Surge", "Thorned Roots",
    # Filler cards
    "Seed Spark", "Nature's Whistle", "Elemental Flicker", "Rot Drop", "Arcane Echo"
]

var deck : Array[String] = []
var discard : Array[String] = []
var hand_nodes := []
var gold : int = 100
var hp : int = 100
var max_hp : int = 100
var block : int = 0  # Player block system

# Energy restored each turn
const STARTING_ENERGY : int = 3
var energy : int = STARTING_ENERGY
@onready var card_db = CardDatabase.new()
var enemy_data := {}
var room_number : int = 0
var state : String = "combat"

const EnemyScene = preload("res://Scenes/Enemy.tscn")

func _ready():
    add_to_group("game_controller")  # Add to group for easy access
    randomize()
    deck = STARTER_DECK.duplicate()
    deck.shuffle()
    discard = []
    _load_enemy_data()
    spawn_combat_room()

func start_turn():
    energy = STARTING_ENERGY
    block = 0  # Block resets each turn
    _update_energy_label()
    _update_player_status()  # Update all player status displays
    var boss = _get_active_boss()
    if boss:
        boss._on_turn_start()
    draw_cards(5)

func _get_active_boss():
    const Boss = preload("res://scripts/Boss.gd")
    for child in get_parent().get_children():
        if child is Boss:
            return child
    return null

func draw_cards(count:int):
    for i in range(count):
        if deck.is_empty():
            _reshuffle_discard()
        if deck.is_empty():
            break
        var card_name = deck.pop_back()
        var card_ui = CardUI.instantiate()
        card_ui.setup(card_db.get_card(card_name))
        $Hand.add_child(card_ui)
        hand_nodes.append(card_ui)
    
    _update_deck_size_label()
    _arrange_hand_cards()

func _arrange_hand_cards():
    # Arrange cards in hand in a nice arc
    var hand_count = hand_nodes.size()
    if hand_count == 0:
        return
    
    var start_x = -100 * (hand_count - 1) / 2.0
    for i in range(hand_count):
        var card = hand_nodes[i]
        card.position = Vector2(start_x + i * 100, 0)
        card.original_position = card.position

func _reshuffle_discard():
    if discard.size() > 0:
        deck = discard.duplicate()
        deck.shuffle()
        discard.clear()
        _update_deck_size_label()

# Reference to CardUI scene
const CardUI = preload("res://Scenes/CardUI.tscn")
const EnemyContainerPath = "Enemies"

func play_card(name:String):
    var data = card_db.get_card(name)
    if data == null:
        print("Card not found: ", name)
        return
    if energy < data.cost:
        print("Not enough energy to play ", name)
        return
    
    energy -= data.cost
    _update_energy_label()
    print("Playing card: ", name, " (", data.effect, ")")
    
    # Apply card effects
    if data.damage > 0:
        _apply_damage_to_enemy(data.damage)
    if data.block > 0:
        block += data.block
        print("Player gains %d Block (Total: %d)" % [data.block, block])
        _update_player_status()
    
    # Handle special card effects
    _handle_special_effects(data)
    
    discard.append(name)
    for n in hand_nodes:
        if n.card_data.name == name:
            hand_nodes.erase(n)
            n.queue_free()
            break

func _handle_special_effects(card_data: CardData):
    match card_data.name:
        "Sprout Heal":
            hp = min(max_hp, hp + 5)
            print("Healed 5 HP")
            _update_player_status()
        "Growth Ritual":
            print("Growth Ritual: Next turn gain +1 Energy")
            # TODO: Implement persistent effects
        "Seed Shield":
            print("Planted a Seed and gained Block")
        "Nature's Whistle":
            print("Gained 1 Seed")
        "Vine Whip":
            # This card hits twice - apply damage again
            _apply_damage_to_enemy(4)
            print("Vine Whip hits again!")
        "Petal Spray":
            # Hits all enemies
            var container = get_node(EnemyContainerPath)
            for enemy in container.get_children():
                if enemy != container.get_child(0):  # Skip first enemy (already hit)
                    enemy.apply_damage(3)
            print("Petal Spray hits all enemies!")
        "Blossom Strike":
            print("Gained 1 Seed from Blossom Strike")
        "Root Smash":
            print("Enemy is weakened!")
        "Sap Shot":
            hp = min(max_hp, hp + 2)
            print("Healed 2 HP from Sap Shot")
            _update_player_status()
        "Garden Bloom":
            draw_cards(1)
            print("Garden Bloom: Drew 1 card")
        "Growth Aura":
            print("All Strikes deal +2 damage this combat")
        _:
            pass

func end_turn():
    # Discard all cards in hand
    for n in hand_nodes:
        discard.append(n.card_data.name)
        n.queue_free()
    hand_nodes.clear()
    
    # Enemy turn
    _enemy_turn()
    
    # Start new player turn
    start_turn()

func _enemy_turn():
    print("--- Enemy Turn ---")
    var container = get_node(EnemyContainerPath)
    for enemy in container.get_children():
        if enemy.has_method("take_turn"):
            enemy.take_turn()
    print("--- Player Turn ---")

func _update_energy_label():
    $EnergyLabel.text = "Energy: %d" % energy

func _update_deck_size_label():
    $DeckSizeLabel.text = "Deck: %d" % deck.size()

func _update_player_status():
    # Add health label if it doesn't exist
    if not has_node("HealthLabel"):
        var health_label = Label.new()
        health_label.name = "HealthLabel"
        health_label.position = Vector2(10, 50)
        add_child(health_label)
    $HealthLabel.text = "Health: %d/%d" % [hp, max_hp]
    
    # Add block label if it doesn't exist  
    if not has_node("BlockLabel"):
        var block_label = Label.new()
        block_label.name = "BlockLabel"
        block_label.position = Vector2(10, 70)
        add_child(block_label)
    $BlockLabel.text = "Block: %d" % block
    
    # Add gold label if it doesn't exist
    if not has_node("GoldLabel"):
        var gold_label = Label.new()
        gold_label.name = "GoldLabel"
        gold_label.position = Vector2(120, 10)
        add_child(gold_label)
    $GoldLabel.text = "Gold: %d" % gold

func _on_EndTurnButton_pressed():
    end_turn()

func _apply_damage_to_enemy(dmg:int):
    var container = get_node(EnemyContainerPath)
    if container.get_child_count() > 0:
        var enemy = container.get_child(0)
        enemy.apply_damage(dmg)

func buy_card(card_name:String):
    gold -= 50
    deck.append(card_name)
    _update_deck_size_label()

func heal_player():
    hp = min(max_hp, hp + 20)
    print("Healed to %d" % hp)

func remove_from_deck():
    if deck.size() > 0:
        var removed = deck.pop_back()
        print("Removed %s" % removed)

func take_damage(amount: int):
    var actual_damage = max(0, amount - block)
    hp -= actual_damage
    block = max(0, block - amount)  # Block absorbs damage
    print("Player takes ", actual_damage, " damage! (", amount - actual_damage, " blocked)")
    print("Health: ", hp, "/", max_hp, " Block: ", block)
    _update_player_status()
    
    if hp <= 0:
        _game_over()

func _game_over():
    print("Game Over!")
    # Add game over logic here - for now just reset
    hp = max_hp
    deck = STARTER_DECK.duplicate()
    deck.shuffle()
    discard.clear()
    room_number = 0
    _update_player_status()
    spawn_combat_room()

func apply_event_effect(effect:String):
    match effect:
        "gain_seed":
            print("Gained a seed")
        "gain_gold":
            gold += 50
            _update_player_status()
        _:
            pass

func _load_enemy_data():
    var file = FileAccess.open("res://Data/enemy_data.json", FileAccess.READ)
    if file:
        enemy_data = JSON.parse_string(file.get_as_text())

func spawn_combat_room():
    state = "combat"
    room_number += 1
    start_turn()
    var container = get_node(EnemyContainerPath)
    for child in container.get_children():
        child.queue_free()
    
    # Every 5th room is a boss fight
    if room_number % 5 == 0:
        _spawn_boss()
    else:
        _spawn_regular_enemies()

func _spawn_boss():
    var boss_names = ["Thorn King", "Blight Colossus", "Storm Wyrm", "Verdant Overlord"]
    var boss_name = boss_names[(room_number / 5 - 1) % boss_names.size()]
    
    var boss_data = {
        "max_hp": 80 + room_number * 5,  # Bosses get stronger over time
        "damage": 12 + room_number
    }
    
    var boss_scene = load("res://Scenes/Boss.tscn")
    var boss = boss_scene.instantiate()
    boss.setup(boss_name, boss_data)
    
    var container = get_node(EnemyContainerPath)
    container.add_child(boss)
    boss.position = Vector2(0, 0)
    boss.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
    
    print("Boss battle: ", boss_name)

func _spawn_regular_enemies():
    var container = get_node(EnemyContainerPath)
    var enemy_count = min(3, 1 + room_number / 3)  # More enemies as game progresses
    
    for i in range(enemy_count):
        var names = enemy_data.keys()
        var enemy_name = names[randi() % names.size()]
        var enemy = EnemyScene.instantiate()
        
        # Make enemies slightly stronger over time
        var scaled_data = enemy_data[enemy_name].duplicate()
        scaled_data["max_hp"] += room_number * 2
        scaled_data["damage"] += room_number / 2
        
        enemy.setup(enemy_name, scaled_data)
        container.add_child(enemy)
        enemy.position = Vector2(200 * i - 200, 0)
        enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

func _on_boss_defeated(boss):
    print("Boss defeated! Great job!")
    # Give bonus rewards for boss
    gold += 100
    hp = min(max_hp, hp + 20)
    print("Gained 100 gold and healed 20 HP!")
    _update_player_status()
    boss.queue_free()
    call_deferred("_room_cleared")

func _on_enemy_died(enemy):
    if get_node(EnemyContainerPath).get_child_count() == 0:
        _room_cleared()

func _room_cleared():
    print("Room %d cleared!" % room_number)
    
    # Give rewards
    gold += 25
    print("Gained 25 gold!")
    
    # Heal a little bit
    if hp < max_hp:
        hp = min(max_hp, hp + 5)
        print("Healed 5 HP")
    
    _update_player_status()
    
    # Progress to next room or show victory screen
    if room_number >= 20:
        _victory()
    else:
        spawn_combat_room()

func _victory():
    print("Congratulations! You've cleared all rooms!")
    print("Starting a new run...")
    # Reset for new run
    room_number = 0
    hp = max_hp
    deck = STARTER_DECK.duplicate()
    deck.shuffle()
    discard.clear()
    gold = 100
    _update_player_status()
    spawn_combat_room()

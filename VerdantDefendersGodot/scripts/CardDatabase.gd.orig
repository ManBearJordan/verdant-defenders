const CardData = preload("res://scripts/CardData.gd")
extends Node
class_name CardDatabase

var cards := {}

func _ready():
    _load_growth_cards()

func get_card(name:String) -> CardData:
    return cards.get(name)

func _load_growth_cards():
    cards["Thorn Lash"] = CardData.new("Thorn Lash", "Strike", 1, "Deal 6 damage. If target has a Seed, deal 2 extra damage.", 6)
    cards["Blossom Strike"] = CardData.new("Blossom Strike", "Strike", 1, "Deal 5 damage. Gain 1 Seed.", 5)
    cards["Vine Whip"] = CardData.new("Vine Whip", "Strike", 1, "Deal 4 damage twice.", 8)
    cards["Bud Burst"] = CardData.new("Bud Burst", "Strike", 2, "Deal 10 damage. If you have ≥3 Seeds, draw 1 card.", 10)
    cards["Petal Spray"] = CardData.new("Petal Spray", "Strike", 1, "Deal 3 damage to all enemies.", 3)
    cards["Root Smash"] = CardData.new("Root Smash", "Strike", 2, "Deal 8 damage and apply 2 Weak.", 8)
    cards["Sap Shot"] = CardData.new("Sap Shot", "Strike", 1, "Deal 4 damage and heal 2 HP.", 4)
    cards["Thorned Blade"] = CardData.new("Thorned Blade", "Strike", 1, "Deal 5 damage; if played consecutively, cost 0 next Strike.", 5)
    cards["Gilded Bud"] = CardData.new("Gilded Bud", "Strike", 2, "Deal 7 damage. Gain 1 Growth Rune.", 7)
    cards["Blooming Edge"] = CardData.new("Blooming Edge", "Strike", 2, "Deal 6 damage and apply 1 Vulnerable.", 6)
    cards["Petal Pierce"] = CardData.new("Petal Pierce", "Strike", 1, "Deal 4 damage; if enemy is Poisoned, gain 1 Seed.", 4)
    cards["Seeded Slash"] = CardData.new("Seeded Slash", "Strike", 1, "Deal 5 damage. Plant a Seed.", 5)
    cards["Thorn Barrage"] = CardData.new("Thorn Barrage", "Strike", 3, "Deal 4 damage 3 times.", 12)
    cards["Sappy Lunge"] = CardData.new("Sappy Lunge", "Strike", 1, "Deal 5 damage. If no Seeds, gain 2 Seeds.", 5)
    cards["Vine Cleaver"] = CardData.new("Vine Cleaver", "Strike", 2, "Deal 9 damage to all enemies if you have ≥4 Seeds.", 9)

    cards["Seed Shield"] = CardData.new("Seed Shield", "Tactic", 1, "Gain 6 Block. Plant a Seed.", 0, 6)
    cards["Vine Trap"] = CardData.new("Vine Trap", "Tactic", 1, "Place a trap: first enemy to move takes 8 damage.", 8)
    cards["Sprout Heal"] = CardData.new("Sprout Heal", "Tactic", 1, "Heal 5 HP. Draw 1 card.")
    cards["Fertile Soil"] = CardData.new("Fertile Soil", "Tactic", 2, "Next Growth Strike gains +3 damage.")
    cards["Rooting Pulse"] = CardData.new("Rooting Pulse", "Tactic", 1, "Apply 2 Vulnerable to all enemies.")
    cards["Seedlings"] = CardData.new("Seedlings", "Tactic", 1, "Gain 2 Seeds.")
    cards["Thorn Wall"] = CardData.new("Thorn Wall", "Tactic", 2, "Gain 10 Block. Deal 4 damage to attackers.", 0, 10)
    cards["Petal Veil"] = CardData.new("Petal Veil", "Tactic", 2, "Gain 8 Block. Reduce next damage by 4.", 0, 8)
    cards["Sap Shield"] = CardData.new("Sap Shield", "Tactic", 1, "Gain 4 Block. Next Ritual costs 1 less.", 0, 4)
    cards["Bud Barrier"] = CardData.new("Bud Barrier", "Tactic", 1, "Gain 5 Block. If you have ≥2 Seeds, gain an extra card.", 0, 5)
    cards["Sprout Sentry"] = CardData.new("Sprout Sentry", "Tactic", 2, "Summon a Seedling: at end of turn, heal 2 HP.")
    cards["Petal Step"] = CardData.new("Petal Step", "Tactic", 1, "Dodge an attack this turn.")
    cards["Growth Glyph"] = CardData.new("Growth Glyph", "Tactic", 2, "Next two Strikes are free.")
    cards["Mossy Guard"] = CardData.new("Mossy Guard", "Tactic", 1, "Gain 3 Block. Gain 1 Growth Rune.", 0, 3)

    cards["Growth Ritual"] = CardData.new("Growth Ritual", "Ritual", 0, "Gain 1 Energy next turn if you've played a Ritual this combat.")
    cards["Garden Bloom"] = CardData.new("Garden Bloom", "Ritual", 2, "At end of turn, draw 1 card and gain 1 Seed.")
    cards["Growth Aura"] = CardData.new("Growth Aura", "Ritual", 2, "All Strikes deal +2 damage.")
    cards["Seed Surge"] = CardData.new("Seed Surge", "Ritual", 3, "At start of each turn, gain 1 Energy.")
    cards["Thorned Roots"] = CardData.new("Thorned Roots", "Ritual", 2, "Whenever you gain Block, enemies lose 1 Strength.")
    cards["Verdant Warding"] = CardData.new("Verdant Warding", "Ritual", 2, "At end of combat, heal 5 HP.")
    cards["Blooming Ward"] = CardData.new("Blooming Ward", "Ritual", 3, "At end of turn, apply 1 Poison to all enemies.")
    cards["Sprouting Might"] = CardData.new("Sprouting Might", "Ritual", 2, "Strikes cost 0 if you played ≥3 Strikes last turn.")
    cards["Fungal Fortress"] = CardData.new("Fungal Fortress", "Ritual", 3, "Gain 2 Seeds at end of each turn.")
    cards["Rooted Resolve"] = CardData.new("Rooted Resolve", "Ritual", 2, "At start of combat, gain 5 Block.")
    cards["Nature's Boon"] = CardData.new("Nature's Boon", "Ritual", 3, "Gain 2 Growth Runes.")
    cards["Verdant Bond"] = CardData.new("Verdant Bond", "Ritual", 2, "Whenever you play a Ritual, draw 1 card.")
    cards["Petal Parade"] = CardData.new("Petal Parade", "Ritual", 3, "Strikes hit all enemies.")
    cards["Seed of Renewal"] = CardData.new("Seed of Renewal", "Ritual", 3, "At end of turn, remove one negative status.")
    cards["Overgrowth"] = CardData.new("Overgrowth", "Ritual", 4, "All Strikes and Tactics gain +1 effect.")
    cards["Eternal Blossom"] = CardData.new("Eternal Blossom", "Ritual", 5, "At end of combat, retain all unplayed cards.")

    # Generic filler cards
    cards["Seed Spark"] = CardData.new("Seed Spark", "Filler", 0, "Draw 1 card.")
    cards["Nature's Whistle"] = CardData.new("Nature's Whistle", "Filler", 0, "Gain 1 Seed.")
    cards["Elemental Flicker"] = CardData.new("Elemental Flicker", "Filler", 0, "Deal 1 damage randomly.", 1)
    cards["Rot Drop"] = CardData.new("Rot Drop", "Filler", 0, "Apply 1 Poison randomly.")
    cards["Arcane Echo"] = CardData.new("Arcane Echo", "Filler", 0, "Next Ritual costs 1 less.")

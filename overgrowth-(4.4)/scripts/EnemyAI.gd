extends Node
func compute_intent(e: Dictionary, turn: int) -> Dictionary:
	var ai := str(e.get("ai","attack"))
	match ai:
		"attack": return {"type":"attack","value": int(e.get("damage",0))}
		"alternate":
			if (turn % 2) == 1: return {"type":"attack","value": int(e.get("damage",0))}
			else: return {"type":"defend","value": 0}
		"attack_thorns": return {"type":"attack","value": int(e.get("damage",0))}
		"cycle":
			var base := int(e.get("damage",0)); var val := base + int((turn-1) % 3)
			return {"type":"attack","value": val}
		_: return {"type":"attack","value": int(e.get("damage",0))}
func act_enemy(e: Dictionary, combat, gc) -> void:
	if int(e.get("hp",0)) <= 0: return
	var intent = compute_intent(e, combat.turn)
	var intent_type = intent.get("type","attack")
	
	if intent_type == "attack":
		var dmg: int = int(intent.get("value",0)) + int(e.get("strength",0))
		var absorbed: int = min(combat.player_block, dmg); combat.player_block -= absorbed
		var left: int = dmg - absorbed; if left > 0: gc.player_hp -= left
	elif intent_type == "defend":
		var block_amount: int = int(intent.get("value",0))
		e["block"] = int(e.get("block", 0)) + block_amount

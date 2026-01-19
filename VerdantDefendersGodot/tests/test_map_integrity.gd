@tool
extends SceneTree

func _init():
	print("--- MAP VERIFICATION TEST ---")
	test_map_integrity()
	quit()

func test_map_integrity():
	var map_gen_script = load("res://scripts/MapGenerator.gd")
	var map_gen = map_gen_script.new()
	
	print("Testing 100 Map Generations...")
	
	for i in range(100):
		var map = map_gen.generate_map(1)
		var layers = map["layers"]
		
		# Check 1: Layer Count
		if layers.size() != 12:
			print("FAIL: Incorrect layer count %d" % layers.size())
			return
			
		# Check 2: Connectivity & No Crossing
		for l in range(layers.size() - 1):
			var curr = layers[l]
			var next_l = layers[l+1]
			
			var max_target_so_far = -1
			
			for u in curr:
				# Check Next pointers
				if u["next"].is_empty():
					# Valid only if pruned? But generator should prune cleanly.
					# Actually my generator leaves pruned nodes in array but 'reachable' check removes them?
					# No, `_prune_map` creates a NEW clean array. So empty next is BAD (dead end), unless end of map.
					if l < layers.size() - 1:
						# It IS possible for a node to have no children if it was pruned? 
						# Pruning removes nodes that don't reach boss.
						# So every node in valid map MUST reach boss.
						print("FAIL: Node has no children at layer %d index %d" % [l, u["index"]])
						return
				
				# Check Crossing
				# Rule: min(targets) >= max_target_of_prev_node ?
				# Actually the strict rule I implemented: `min(targets(u)) >= max(targets(u-1))`?
				# My code: `for v_idx in range(prev_node_max_target, next_layer.size())`
				# and sets `prev_node_max_target = chosen_targets.back()`.
				# So `min(u.next)` MUST be >= `max((u-1).next)`.
				
				var my_min = 999
				var my_max = -1
				for v in u["next"]:
					if v < my_min: my_min = v
					if v > my_max: my_max = v
					
				if my_min < max_target_so_far:
					print("FAIL: Crossing Edge detected at Layer %d! Node %d -> %d crosses prev max %d" % [l, u["index"], my_min, max_target_so_far])
					quit(1)
					
				max_target_so_far = my_max
	
	print("SUCCESS: 100 Maps Generated with ZERO Crossing Edges and Full Integrity.")
	quit(0)

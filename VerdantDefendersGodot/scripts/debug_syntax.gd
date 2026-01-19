extends SceneTree

func _init():
	print("Debugging CombatSystem Syntax...")
	var s = load("res://scripts/CombatSystem.gd")
	if s:
		print("Loaded Script Resource.")
		# Force instantiation to trigger runtime/parser errors
		# Wrap in pcall if possible? No.
		# Just let it crash, the output should contain the error.
		if s.can_instantiate():
			print("Can instantiate. Attempting new()...")
			var i = s.new()
			print("Instantiated successfully.")
		else:
			print("Cannot instantiate (can_instantiate=false).")
	else:
		print("Failed to load script.")
		
	print("Debugging GameController Syntax...")
	s = load("res://scripts/GameController.gd")
	if s:
		if s.can_instantiate():
			var i = s.new()
			print("GameController instantiated.")
			
	quit()

extends SceneTree

func _init():
	print("Minimal Compilation Test Started")
	var failed = false
	
	# Try to access key autoloads
	var rc = get_root().get_node_or_null("RunController")
	if rc: print("PASS: RunController loaded")
	else: 
		print("FAIL: RunController not found")
		failed = true
		
	var mc = get_root().get_node_or_null("MapController")
	if mc: print("PASS: MapController loaded")
	else: 
		print("FAIL: MapController not found")
		failed = true

	var cs = get_root().get_node_or_null("CardSystem")
	if cs: print("PASS: CardSystem loaded")
	else: 
		print("FAIL: CardSystem not found")
		failed = true
		
	if failed:
		print("Compilation errors likely exist.")
	else:
		print("All critical autoloads loaded successfully.")
		
	quit()

extends SceneTree

func _init():
	print("Testing RunController Load...")
	var rc_script = load("res://scripts/RunController.gd")
	if not rc_script:
		print("FAIL: Could not load script")
		quit()
		return
	
	var rc = rc_script.new()
	if not rc:
		print("FAIL: Could not instance script")
		quit()
		return
		
	print("SUCCESS: RunController loaded and instanced")
	quit()

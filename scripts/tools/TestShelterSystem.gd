extends SceneTree

func _init():
	print("🧪 TESTING SHELTER SYSTEM IMPLEMENTATION")
	print("=".repeat(60))
	
	# Test 1: Verificare che i file esistano e siano compilabili
	test_file_existence()
	
	# Test 2: Verificare metodi critici
	test_critical_methods()
	
	print("\n✅ SHELTER SYSTEM VALIDATION COMPLETE")
	quit()

func test_file_existence():
	print("\n📁 File Existence Tests:")
	
	var files_to_check = [
		"res://scenes/ui/popups/RestNightPopup.tscn",
		"res://scripts/ui/popups/RestNightPopup.gd"
	]
	
	for file_path in files_to_check:
		if ResourceLoader.exists(file_path):
			print("✅ %s exists" % file_path)
		else:
			print("❌ %s missing" % file_path)

func test_critical_methods():
	print("\n⚙️ Critical Method Tests:")
	
	# Test TimeManager methods
	if TimeManager.has_method("advance_time_until_hour"):
		print("✅ TimeManager.advance_time_until_hour() available")
		
		# Test the method
		var initial_hour = TimeManager.current_hour
		var target_hour = 6
		print("   Testing time advancement: %d → %d" % [initial_hour, target_hour])
		
		TimeManager.advance_time_until_hour(target_hour)
		
		if TimeManager.current_hour == target_hour:
			print("✅ Time advancement working correctly")
		else:
			print("⚠️ Time advancement result: %d (expected %d)" % [TimeManager.current_hour, target_hour])
	else:
		print("❌ TimeManager.advance_time_until_hour() missing")
	
	# Test InputManager signals
	if InputManager.has_signal("shelter_action_requested"):
		print("✅ InputManager shelter_action_requested signal available")
	else:
		print("❌ InputManager shelter_action_requested signal missing")
	
	# Test PlayerManager food/water methods
	if PlayerManager.has_method("modify_food") and PlayerManager.has_method("modify_water"):
		print("✅ PlayerManager food/water methods available")
	else:
		print("❌ PlayerManager food/water methods missing")
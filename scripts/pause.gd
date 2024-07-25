extends Node


var paused : bool = false

func update():
	get_tree().paused = paused
	$pause_panel.visible = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.use_accumulated_input = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.use_accumulated_input = false

func _unhandled_input(event):
	if not event.is_action_pressed("g_pause") or get_parent().health <= 0:
		return
	paused = not paused
	update()
	

func _on_continue_pressed():
	paused = false
	update()

func _on_back_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

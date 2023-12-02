extends Control


func _on_exit_button_pressed():
	get_tree().quit()


func _on_credits_button_pressed():
	$credits.visible = 1


func _on_close_credits_button_pressed():
	$credits.visible = 0


func _on_play_button_pressed():
	$level_select_control.visible = 1


func _on_close_options_button_pressed():
	$options_control.visible = 0


func _on_options_button_pressed():
	$options_control.visible = 1


func _on_exit_level_select_pressed():
	$level_select_control.visible = 0

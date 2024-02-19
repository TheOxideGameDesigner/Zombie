extends StaticBody3D

@onready var text = $text
@export_multiline var message
@onready var label = $text/Label


func _ready():
	label.text = message
	var format_dict = {}
	for i in InputMap.get_actions():
		var events = InputMap.action_get_events(i)
		if events.is_empty():
			continue
		var event = events[0]
		var evstr = "UNKNOWN"
		if event is InputEventKey:
			evstr = event.as_text_keycode()
		elif event is InputEventMouseButton:
			evstr = event.as_text()
		format_dict[i] = evstr
	label.text = label.text.format(format_dict)


func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		text.visible = 1


func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		text.visible = 0

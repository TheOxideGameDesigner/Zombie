extends Control

@onready var label = $panel/story

const SPEED = 10
var timer = 0.0

@export_multiline var text : String = "sample text"
@onready var guide = $panel/guide
@export_file var scene : String = "res://scenes/main_menu.tscn"


func _unhandled_key_input(event):
	if not event.is_pressed():
		return
	if label.visible_characters < text.length():
		label.visible_characters = text.length()
	else:
		get_tree().change_scene_to_file(scene)


func _ready():
	label.text = text

func _process(delta):
	if label.visible_characters < text.length():
		timer += delta
		label.visible_characters = int(timer * SPEED)
	else:
		guide.visible = true

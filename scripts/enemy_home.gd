extends Node3D


const BOB_AMPLITUDE : float = 0.1
const BOB_FREQ : float = 2


@export var color : Color
@onready var cross = $cross
@onready var init_height : float = cross.position.y
@onready var time_left_label = $cross/time_left_label
var time : float = 0.0
var time_left : float = 0.0


func _ready() -> void:
	cross.modulate = color
	$cross_base.modulate = color
	time_left_label.modulate = color


func _process(delta : float) -> void:
	time_left -= delta
	if int(time_left) != int(time_left + delta):
		if time_left > 0:
			time_left_label.text = str(ceil(time_left))
		else:
			time_left_label.text = ""
	time += delta
	cross.position.y = init_height + BOB_AMPLITUDE * sin(time * BOB_FREQ)

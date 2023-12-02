extends Node3D


const BOB_AMPLITUDE = 0.1
const BOB_FREQ = 2


@export var color : Color
@onready var cross = $cross
@onready var init_height = cross.position.y
@onready var time_left_label = $cross/time_left_label
var time = 0.0
var time_left = 0.0


func _ready():
	cross.modulate = color
	$cross_base.modulate = color
	time_left_label.modulate = color


func _process(delta):
	time_left -= delta
	if time_left > 0:
		time_left_label.text = str(ceil(time_left))
	else:
		time_left_label.text = ""
	time += delta
	cross.position.y = init_height + BOB_AMPLITUDE * sin(time * BOB_FREQ)

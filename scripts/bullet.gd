extends Node3D


@export var speed = 50
@export var lifespan = 0.05

@onready var mesh = $mesh

const SLEEP_FRAMES = 2
var frame = 0

var timer = 0.0


func _process(delta):
	if frame >= SLEEP_FRAMES:
		mesh.position += speed * delta * Vector3.FORWARD
		timer += delta
	else:
		frame += 1
	if timer > lifespan:
		queue_free()
		return

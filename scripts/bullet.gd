extends Node3D


@export var speed : float = 50
@export var lifespan : float = 0.05

@onready var mesh = $mesh

const SLEEP_FRAMES : int = 2
var frame : int = 0

var timer : float = 0.0


func _process(delta : float) -> void:
	if frame >= SLEEP_FRAMES:
		mesh.position += speed * delta * Vector3.FORWARD
		timer += delta
	else:
		frame += 1
	if timer > lifespan:
		queue_free()
		return

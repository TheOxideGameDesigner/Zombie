extends GPUParticles3D


var dir = Vector3.ZERO
var speed = 2
var color = Color(1, 0, 0)
var spread = 27.75


func _ready():
	process_material = process_material.duplicate()
	emitting = true
	process_material.direction = dir
	process_material.color_ramp.gradient.colors = [Color(color.r, color.g, color.b, 1), Color(color.r, color.g, color.b, 0)]
	process_material.initial_velocity_min = speed
	process_material.initial_velocity_max = 2 * speed
	process_material.spread = spread


func _on_finished():
	queue_free()

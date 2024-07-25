extends GPUParticles3D


@export var dir : Vector3 = Vector3.ZERO
@export var speed : float = 2
@export var size : float = 0.1
@export var color : Color = Color(1, 0, 0)
@export var spread : float = 27.75


func _ready() -> void:
	process_material = ParticleProcessMaterial.new()
	emitting = true
	process_material.direction = dir
	process_material.color_ramp = GradientTexture1D.new()
	process_material.color_ramp.gradient = Gradient.new()
	process_material.color_ramp.gradient.colors = [Color(color.r, color.g, color.b, 1), Color(color.r, color.g, color.b, 0)]
	process_material.initial_velocity_min = speed
	process_material.initial_velocity_max = 2 * speed
	process_material.spread = spread
	draw_pass_1 = BoxMesh.new()
	draw_pass_1.size = Vector3(size, size, size)


func _on_finished() -> void:
	queue_free()

extends MeshInstance3D


var timer : float = 0.0
var EXPLOSION_TIME : float = 0.5
@export var color : Color = Color(1, 1, 0)
@export var explosion_scale : float = 15.0


func _ready() -> void:
	material_override = preload("res://resources/materials/specific_mats/angel_explosion.tres").duplicate()
	material_override.albedo_color = color

func _process(delta : float) -> void:
	timer += delta
	scale = Vector3.ONE * timer * explosion_scale
	material_override.albedo_color.a = max(0, EXPLOSION_TIME - timer)
	if timer > 2:
		queue_free()

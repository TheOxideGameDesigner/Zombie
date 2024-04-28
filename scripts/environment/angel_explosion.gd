extends MeshInstance3D


var timer = 0.0
var EXPLOSION_TIME = 0.5


func _ready():
	material_override = preload("res://resources/materials/specific_mats/angel_explosion.tres").duplicate()


func _process(delta):
	timer += delta
	scale = Vector3.ONE * timer * 15
	material_override.albedo_color.a = max(0, EXPLOSION_TIME - timer)
	if timer > 2:
		queue_free()

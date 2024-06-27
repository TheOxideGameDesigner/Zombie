extends Node3D

@onready var mesh = $mesh
@onready var cyl = mesh.mesh
@onready var mat = mesh.material_override
@export var begin : Vector3
@export var end : Vector3

var timer = 0.5


func _ready():
	cyl.height = begin.distance_to(end)
	cyl.rings = int(cyl.height * 2)
	position = begin
	mat.set_shader_parameter("offset", -cyl.height / 2)
	look_at(end)


func _process(delta):
	timer -= delta
	if timer < 0.0:
		queue_free()
		return
	mat.set_shader_parameter("opac", timer * 2)

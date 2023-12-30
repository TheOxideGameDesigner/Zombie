extends MeshInstance3D


@export var color : Color = Color(0, 0.5, 1)
@export var one_sided : bool = 1
@export var vis_threshold = -0.2

@onready var player = get_tree().get_nodes_in_group("player")[0]
@onready var dir = Vector3.MODEL_FRONT.rotated(Vector3.UP, global_rotation.y)

func _ready():
	material_override = preload("res://resources/materials/lock_mat.tres").duplicate()
	material_override.albedo_color = color
	$arrow.visible = 0


func _process(_delta):
	if one_sided:
		visible = dir.dot(Vector3(player.global_position - global_position).normalized()) > vis_threshold

extends MeshInstance3D


@export var type : int = 0


func _ready():
	seed(int((position.x + position.z) * 3))
	$image.material_override = load("res://resources/materials/specific_mats/paintings/" + str(randi_range(type * 4 + 1, 4 + type * 5)) + ".tres")

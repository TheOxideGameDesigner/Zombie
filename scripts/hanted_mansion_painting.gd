extends MeshInstance3D


func set_image(id):
	$image.material_override = load("res://resources/materials/specific_mats/paintings/" + str(id) + ".tres")

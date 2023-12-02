extends Node3D


@export var group = 1000

func _ready():
	$Area3D/move_trigger.group = group
	$Area3D/move_trigger2.group = group + 1
	$left.add_to_group(str(group))
	$right.add_to_group(str(group+1))

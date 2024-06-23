extends StaticBody3D


@export var key_id : int = -1
@export var key_col = Color(0, 0.5, 1)


func _ready():
	if key_id < 0:
		$door_moving/lock.queue_free()
		$door_moving/Area3D.queue_free()
		$door_moving.rotate(Vector3.UP, PI / 2)
	else:
		$door_moving/Area3D/rotate_trigger.keys_required.push_back(key_id)
		$door_moving/lock.color = key_col
		$door_moving/lock.update_color()

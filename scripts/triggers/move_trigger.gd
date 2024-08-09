extends Node3D

const INSTA_MOVE_THRESHOLD : float = 0.1

var inside : bool = 0
var triggered : bool = 0
var timer : float = 0
@export var group : int = 0
@export var target : Vector3 = Vector3.ZERO
@export var time : float = 0.0
@export var delay : float = 0.0
@export var global_target : bool = false
@export var keys_required : Array[int] = []

@onready var player = get_tree().get_nodes_in_group("player")[0]

var in_group = []

func player_has_keys() -> bool:
	for i in range(keys_required.size()):
		if not player.collected_keys[keys_required[i]]:
			return 0
	return 1

func _process(delta : float) -> void:
	if in_group.is_empty():
		return
	
	if not triggered:
		if inside and player_has_keys():
			triggered = 1
	if not triggered:
		return
	timer += delta
	if timer < delay:
		return
	if time < INSTA_MOVE_THRESHOLD:
		for n in in_group:
			if global_target:
				n.global_position = target
			else:
				n.position += target
		queue_free()
		return
	for n in in_group:
		if global_target:
			n.global_position += (target - n.global_position).normalized() * delta / time
		else:
			n.position += target * delta / time
	if timer > time + delay:
		queue_free()


func _on_ready_timer_timeout() -> void:
	if group >= 0:
		in_group = get_tree().get_nodes_in_group(str(group))
	else:
		in_group = [get_parent().get_parent()]

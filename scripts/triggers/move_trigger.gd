extends Node3D

const INSTA_MOVE_THRESHOLD = 0.1

var will_activate = 0
var inside = 0
var prev_inside = 0
var triggered = 0
var timer = 0
@export var group : int = 0
@export var target : Vector3 = Vector3.ZERO
@export var time : float = 0.0
@export var delay : float = 0.0
@export var multi_activate : bool = false
@export var on_exit : bool = false
@export var global_target : bool = false
@export var keys_required : Array[int] = []

@onready var player = get_tree().get_nodes_in_group("player")[0]

var in_group = []

func player_has_keys():
	for i in range(keys_required.size()):
		if not player.collected_keys[keys_required[i]]:
			return 0
	return 1

func _process(delta):
	if in_group.is_empty():
		return
	
	var has_keys = player_has_keys()
	
	var can_activate = inside and not prev_inside and has_keys
	prev_inside = inside
	
	if on_exit and can_activate:
		will_activate = 1
	
	if (on_exit and will_activate and not inside) or (not on_exit and can_activate):
		timer = 0
		triggered = 1
		will_activate = 0
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
		if multi_activate:
			triggered = 0
		else:
			queue_free()
		return
	for n in in_group:
		if global_target:
			n.global_position += (target - n.global_position).normalized() * delta / time
		else:
			n.position += target * delta / time
	if timer > time + delay:
		if multi_activate:
			triggered = 0
		else:
			queue_free()


func _on_ready_timer_timeout():
	in_group = get_tree().get_nodes_in_group(str(group))

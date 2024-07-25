extends Node3D


var dir : Vector3 = Vector3.ZERO
@export var explosive_force : float = 3
@export var lifetime : float = 5
@export var sinking_speed : float = 0.25
var rigid_bodies : Array[RigidBody3D] = []
var frozen : bool = 0
var added_force_yet : bool = 0


func _ready() -> void:
	for c in get_children():
		if c is RigidBody3D:
			rigid_bodies.push_back(c)
			c.freeze = 1
			for d in c.get_children():
				if d is MeshInstance3D:
					d.position = position + c.position.rotated(Vector3.UP, rotation.y)
					d.rotation = rotation + c.rotation


func _on_freeze_timer_timeout():
	frozen = 1

var timer : float = 0
func _process(delta : float) -> void:
	var added_force_yet_c : bool = added_force_yet
	for c in rigid_bodies:
		c.freeze = frozen
		if not c.freeze and not added_force_yet_c:
			c.apply_impulse(dir + c.position.normalized() * explosive_force)
			added_force_yet = 1
			
	if frozen:
		for c in rigid_bodies:
			c.position.y -= delta * sinking_speed
		timer += delta
		if timer > lifetime:
			queue_free()

extends Node3D


var dir : Vector3 = Vector3.ZERO
@export var explosive_force = 3
@export var lifetime = 5
@export var sinking_speed = 0.25
var rigid_bodies : Array[RigidBody3D] = []
var frozen = 0
var frames_passed = 0
var added_force_yet = 0


func _ready():
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

var timer = 0
func _process(delta):
	frames_passed += 1
	var added_force_yet_c = added_force_yet
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

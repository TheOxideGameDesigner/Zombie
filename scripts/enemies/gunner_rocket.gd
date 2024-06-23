extends Area3D


var SPEED = 30.0
const V_HOMING_FORCE = 50
const DAMAGE = 30

const EXPLOSION_TIME = 1
const EXPLOSION_RADIUS = 6

var target
var death_message = "You were killed by a fireball"
var vel = Vector3.ZERO
var velv = 0

var timer = 0.0
var exploded : bool = 0

var time_since_birth = 0

var hit_target = 0
@onready var sprite = $sprite
@onready var explosion = $explosion

func set_vel(new_vel):
	vel = new_vel.normalized() * SPEED


func _process(delta):
	if exploded and not hit_target:
		if timer > EXPLOSION_TIME:
			queue_free()
		timer += delta
		explosion.mesh.material.albedo_color.a = pow(1 - timer / EXPLOSION_TIME, 2)
		explosion.scale = Vector3.ONE * EXPLOSION_RADIUS * timer / EXPLOSION_TIME
	
	if exploded:
		return
	time_since_birth += delta


func _physics_process(delta):
	if exploded:
		return
	if target.is_in_group("enemy"):
		vel = target.position + Vector3(0, 1, 0) - position
	vel = vel.normalized()
	global_position += vel * delta * SPEED


func physics(body = null):
	if body != null and body.is_in_group("physics"):
		body.apply_central_impulse(5 * vel)
	for obj in get_tree().get_nodes_in_group("physics"):
		if obj == body:
			continue
		var dist = obj.global_position.distance_to(global_position)
		if dist < 7.5:
			obj.apply_central_impulse(10 * (obj.global_position - global_position).normalized() / (1 + dist / 3))


func _on_body_entered(body):
	if body == get_parent() or exploded:
		return
	exploded = 1
	physics(body)
	explosion.visible = 1
	sprite.queue_free()
	$hitbox.queue_free()
	if !body.is_in_group("player") and !body.is_in_group("enemy"):
		return
	hit_target = 1
	explosion.queue_free()
	$death_timer.queue_free()
	if body.is_in_group("player"):
		body.pain(death_message, DAMAGE)
		body.knockback(vel.normalized() * 10 + Vector3(0, 0.2, 0))
	else:
		body.pain(DAMAGE)
		if body.is_in_group("lightweight"):
			body.add_vel += vel.normalized() * 10



func _on_death_timer_timeout():
	if exploded:
		return
	exploded = 1
	physics()
	explosion.visible = 1
	sprite.queue_free()
	$hitbox.queue_free()

extends Area3D


var SPEED = 30.0
const HOMING_FORCE = 6
const V_HOMING_FORCE = 50
const DAMAGE = 40
const HOMING_TIME = 0.5

const EXPLOSION_TIME = 1
const EXPLOSION_RADIUS = 6

var player
var vel = Vector3.ZERO
var velv = 0

var timer = 0.0
var exploded : bool = 0

var time_since_birth = 0
var frames_passed = 0

var hit_player = 0

func set_vel(new_vel):
	vel = new_vel.normalized() * SPEED


func _process(delta):
	if exploded and not hit_player:
		if timer > EXPLOSION_TIME:
			queue_free()
		timer += delta
		$explosion.mesh.material.albedo_color.a = pow(1 - timer / EXPLOSION_TIME, 2)
		$explosion.scale = Vector3.ONE * EXPLOSION_RADIUS * timer / EXPLOSION_TIME


func _physics_process(delta):
	if exploded:
		return
	time_since_birth += delta
	if vel == Vector3.ZERO:
		return
	
	if time_since_birth < HOMING_TIME:
		vel += HOMING_FORCE * delta * Vector3(player.global_position - global_position).normalized()
		vel.y = 0
		vel = vel.normalized()
	global_position += vel * delta * SPEED
	global_position.y = lerp(global_position.y, player.global_position.y + 1.5, min(1, V_HOMING_FORCE * delta / (position.distance_to(player.position) + 1)))
	$sprite.global_position = global_position
	if frames_passed > 3:
		$sprite.visible = 1
	else:
		frames_passed += 1


func _on_body_entered(body):
	if body.is_in_group("enemy") or (not body.get_collision_layer_value(1) and not body.get_collision_layer_value(9)) or exploded:
		return
	exploded = 1
	$explosion.visible = 1
	$sprite.queue_free()
	$hitbox.queue_free()
	if body != player:
		return
	hit_player = 1
	$explosion.queue_free()
	$death_timer.queue_free()
	player.pain(DAMAGE)
	player.knockback(vel.normalized() * 10 + Vector3(0, 0.2, 0))



func _on_death_timer_timeout():
	if hit_player or exploded:
		return
	exploded = 1
	$explosion.visible = 1
	$sprite.queue_free()
	$hitbox.queue_free()

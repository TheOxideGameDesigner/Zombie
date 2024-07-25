extends StaticBody3D


const SPEED : float = 30.0
const LIFESPAN : float = 3.0
const DAMAGE : float = 75.0
const FALLOFF : float = 0.2
const EXPLOSION_SIZE : float = 5.0
const SPLASH_RADIUS : float = 7.5
const PLAYER_SPLASH_RADIUS : float = 3
var time : float = 0.0
var dir : Vector3 = Vector3.ZERO
var initial_pos : Vector3 = Vector3.ZERO
var exploding : bool = 0
var explosion_timer : float = 0.0
var explosion_time : float = 0.5

var damage_mul : float = 1.0

var explosion_material = preload("res://resources/materials/plasma_bright.tres").duplicate()
@onready var explosion = $explosion
@onready var player = get_tree().get_first_node_in_group("player")

func explode(body : PhysicsBody3D):
	exploding = 1
	$sprite.visible = 0
	$explosion.visible = 1
	$hitbox.disabled = 1
	for obj in get_tree().get_nodes_in_group("enemy"):
		if obj != body:
			var dist : float = obj.global_position.distance_to(global_position)
			if dist < SPLASH_RADIUS:
				if obj.is_in_group("lightweight") and not (obj.is_in_group("phantom") and obj.dist_from_player > obj.PHANTOM_RADIUS):
					var expl_dir : Vector3 = (obj.global_position - position).normalized() + dir
					expl_dir.y = 0
					obj.add_vel = expl_dir.normalized() * 10
				obj.pain(lerp(0.0, DAMAGE, 1.0 - dist / SPLASH_RADIUS) * damage_mul)
	for obj in get_tree().get_nodes_in_group("physics"):
		var dist : float = obj.global_position.distance_to(global_position)
		if dist < SPLASH_RADIUS:
			obj.apply_central_impulse(5 * (obj.global_position - position).normalized() / (1 + dist / 3))
	var dist : float = (player.position + Vector3(0, 0.85, 0)).distance_to(position)
	if dist < PLAYER_SPLASH_RADIUS:
		var knockback_dir : Vector3 = (player.cam.global_position - position) * 6 / (dist * dist)
		knockback_dir.y = 2
		player.knockback(knockback_dir)
		
	if body == null:
		return
	if body.is_in_group("enemy"):
		body.pain(DAMAGE * damage_mul)
		if body.is_in_group("lightweight"):
			var expl_dir : Vector3 = (body.global_position - position).normalized() + dir
			expl_dir.y = 0
			body.add_vel = expl_dir.normalized() * 12
	elif body.is_in_group("physics"):
		body.apply_central_impulse(dir * 15)



func _ready() -> void:
	dir = dir.normalized()
	global_position = initial_pos
	explosion.set_surface_override_material(0, explosion_material)


func _process(delta : float) -> void:
	if exploding:
		explosion.scale = Vector3.ONE * lerp(0.0, EXPLOSION_SIZE, explosion_timer / explosion_time)
		explosion_material.albedo_color.a = pow(1 - explosion_timer / explosion_time, 2)
		explosion_timer += delta
		if explosion_timer > explosion_time:
			queue_free()
		return
	
	move_and_collide(dir * SPEED * delta)
	time += delta
	
	if time > LIFESPAN:
		explode(null)


func _on_area_body_entered(body : PhysicsBody3D) -> void:
	if exploding or body == player or body.is_in_group("cannonball") or (body.is_in_group("phantom") and body.dist_from_player > body.PHANTOM_RADIUS):
		return
	explode(body)

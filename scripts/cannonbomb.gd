extends RigidBody3D


var explosion_material = preload("res://resources/materials/plasma_medium.tres").duplicate()
var material = preload("res://resources/materials/cannonbomb_mat.tres").duplicate()
@onready var explosion = $explosion
@onready var player = get_tree().get_first_node_in_group("player")
@onready var player_camera = player.get_node("cam/camera")
var exploding : bool = 0

var explosion_timer : float = 0
var explosion_time : float = 0.4
const EXPLOSION_SIZE : float = 5

const SPEED : float = 30.0
const LIFESPAN : float = 3.0
const FLICKER_TIME : float = 1.0
const FLICKER_FREQ : float = 10
const DAMAGE : float = 150.0
const FALLOFF : float = 0.25
const SPLASH_RADIUS : float = 6
const SELF_DAMAGE_RADIUS : float = 5
var time : float = 0.0

var damage_mul : float = 1.0

func explode(body : PhysicsBody3D) -> void:
	exploding = 1
	$bomb_sphere.visible = 0
	$explosion.visible = 1
	$hitbox.disabled = 1
	freeze = 1
	for obj in get_tree().get_nodes_in_group("enemy"):
		if obj != body and obj != self:
			var dist : float = obj.global_position.distance_to(global_position)
			if dist < SPLASH_RADIUS:
				if obj.is_in_group("lightweight") and not (obj.is_in_group("phantom") and obj.dist_from_player > obj.PHANTOM_RADIUS):
					var expl_dir : Vector3 = (obj.global_position - position).normalized()
					expl_dir.y = 0
					obj.add_vel = expl_dir.normalized() * 10
				obj.pain(lerp(0.0, DAMAGE, sqrt(1.0 - dist / SPLASH_RADIUS)) * damage_mul)
	for obj in get_tree().get_nodes_in_group("physics"):
		var dist : float = obj.global_position.distance_to(global_position)
		if dist < SPLASH_RADIUS:
			obj.apply_central_impulse(20 * (obj.global_position - position).normalized() / (1 + dist / 3))
	var dist : float = (player.position + Vector3(0, 0.85, 0)).distance_to(position)
	if dist < SELF_DAMAGE_RADIUS:
		player.knockback((player.cam.global_position - position) * 12 / (dist * dist))
		player.velocity.y *= 0.2
		player.pain("You killed yourself with a bomb", floori(40.0 / max(1.0, dist * 0.35)), true)
	if dist < 15:
		player_camera.shake(0.4, 2 / (dist / 7.5 + 1), 0.025)
		
	if body == null or body == self:
		return
	if body.is_in_group("enemy"):
		body.pain(DAMAGE * damage_mul)
		if body.is_in_group("lightweight"):
			var expl_dir : Vector3 = (body.global_position - position).normalized()
			expl_dir.y = 0
			body.add_vel = expl_dir.normalized() * 10


func _ready() -> void:
	explosion.set_surface_override_material(0, explosion_material)
	$bomb_sphere.set_surface_override_material(0, material)
	$bomb_sphere/bomb_cylinder.set_surface_override_material(0, material)

func _process(delta : float) -> void:
	time += delta
	visible = time > 0.05
	if time > LIFESPAN and not exploding:
		explode(null)
	elif time > LIFESPAN - FLICKER_TIME:
		var flicker : bool = int(FLICKER_FREQ * (LIFESPAN - time) / FLICKER_TIME) % 2
		if flicker:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		else:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if exploding:
		explosion.scale = Vector3.ONE * lerp(0.0, EXPLOSION_SIZE, explosion_timer / explosion_time)
		explosion_material.albedo_color.a = pow(1 - explosion_timer / explosion_time, 1)
		explosion_timer += delta
		if explosion_timer > explosion_time:
			queue_free()
		return


func _on_area_body_entered(body : PhysicsBody3D) -> void:
	if exploding or body == self or (body.is_in_group("phantom") and body.dist_from_player > body.PHANTOM_RADIUS):
		return
	if body.is_in_group("enemy"):
		explode(body)

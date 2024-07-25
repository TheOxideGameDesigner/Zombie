extends StaticBody3D


var HVEL : float = 15.0
const GR_ACCEL : float = 9.8
const DAMAGE : int = 30
const SPLASH_RADIUS : float = 5.0
const EXPLOSION_TIME : float = 0.5
const EXPLOSION_RADIUS : float = 8
const FLICKER_TIME : float = 1.0
const FLICKER_FREQ : float = 10

@onready var player = get_tree().get_first_node_in_group("player")
var death_message : String = "You were killed by a bomb"
@onready var start_pos : Vector3 = global_position
var target_pos : Vector3
@onready var hdir : Vector3 = Vector3(target_pos.x - start_pos.x, 0, target_pos.z - start_pos.z).normalized()
@onready var roll_axis : Vector3 = hdir.rotated(Vector3.UP, PI / 2).normalized()
@onready var touch_area = $touch_area

var vvel : float = 0.0

var timer : float = 0.0
var touched_surface : bool = 0
var exploded : bool = 0

var hit_target : bool = 0
@onready var sprite = $sprite
@onready var explosion = $explosion
@onready var death_timer = $death_timer

@onready var shaded_material = preload("res://resources/materials/level_mat.tres")
@onready var unshaded_material = preload("res://resources/materials/level_unshaded_mat.tres")


func physics() -> void:
	for obj in get_tree().get_nodes_in_group("physics"):
		var dist : float = obj.global_position.distance_to(global_position)
		if dist < 7.5:
			obj.apply_central_impulse(15 * (obj.global_position - position).normalized() / (1 + dist / 3))


func _ready() -> void:
	var tf : float = Vector3(target_pos.x - start_pos.x, 0, target_pos.z - start_pos.z).length() / HVEL
	vvel = (target_pos.y - start_pos.y + tf * tf * GR_ACCEL / 2) / tf

func _process(delta : float) -> void:
	if exploded:
		if timer > EXPLOSION_TIME:
			queue_free()
		timer += delta
		explosion.mesh.material.albedo_color.a = pow(1 - timer / EXPLOSION_TIME, 2)
		explosion.scale = Vector3.ONE * EXPLOSION_RADIUS * timer / EXPLOSION_TIME
		return
	if not hit_target and death_timer.time_left < FLICKER_TIME:
		var flicker : bool = int(FLICKER_FREQ * (death_timer.time_left) / FLICKER_TIME) % 2
		if flicker:
			sprite.material_override = unshaded_material
		else:
			sprite.material_override = shaded_material
	if not touched_surface and not hit_target:
		sprite.rotate(roll_axis.normalized(), delta * 2 * PI)


func _physics_process(delta : float) -> void:
	if touched_surface:
		return
	vvel -= GR_ACCEL * delta
	var movement : Vector3 = HVEL * delta * hdir
	movement.y += vvel * delta
	move_and_collide(movement)


func _on_body_entered(body : PhysicsBody3D) -> void:
	if exploded or hit_target or (body.is_in_group("phantom") and body.dist_from_target > body.PHANTOM_RADIUS):
		return
	if body.is_in_group("player"):
		hit_target = 1
		physics()
		explosion.queue_free()
		sprite.queue_free()
		$hitbox.queue_free()
		death_timer.queue_free()
		$touch_area.queue_free()
		var kb : Vector3
		if touched_surface:
			kb = (body.position - position).normalized() * 10
		else:
			kb = hdir * 10 + Vector3(0, 0.2, 0)
		body.pain(death_message, DAMAGE)
		body.knockback(kb)
	else:
		touched_surface = 1



func _on_death_timer_timeout() -> void:
	if exploded or hit_target:
		return
	exploded = 1
	physics()
	explosion.visible = 1
	sprite.queue_free()
	$hitbox.queue_free()
	death_timer.queue_free()
	$touch_area.queue_free()
	var dist : float = (player.position + Vector3(0, 0.5, 0)).distance_to(global_position)
	if dist < SPLASH_RADIUS:
		var effect : float = lerp(1.0, 0.0, dist / SPLASH_RADIUS)
		player.knockback((player.position - position).normalized() * 10 * effect)
		player.pain(death_message, DAMAGE * effect)

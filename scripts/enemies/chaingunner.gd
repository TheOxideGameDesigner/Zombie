extends CharacterBody3D


var HP : int = 300
const REVOLVER_HEAL : int = 3
const HIT_RANGE : float = 20
const HIT_TIME : float = 0.2
var HIT_DAMAGE : int = 4
const GRAVE_DEPTH : float = 4
const RISE_HEIGHT : float = 0.25
const RISE_FLICKER : float = 0.25
const RISE_TIME : float = 3.7664
const MAX_TURN_SPEED = PI / 5
const RADIUS = 1
const ACTIVE_RADIUS = 64

var rising = 0
var health : int
var alive = 1
var rising_timer = 0.0
var vulnerability = 1.0
var has_died = 0
var drops = []

var pain_col = 0.0

var disable_particles : bool = false
var disable_gibs : bool = false

@onready var player = get_tree().get_first_node_in_group("player")
@onready var home = $home
@onready var cross = $home/cross
@onready var health_label = $mesh/health
@onready var mesh = $mesh
@onready var hitbox = $hitbox
@onready var ray = $ray
@onready var alerted = $mesh/alerted
@onready var key = $mesh/key
@onready var respawn = $respawn
@onready var aura = $mesh/aura
@onready var raycast_hitbox = $raycast_collision/raycast_hitbox
@onready var hit_timer = $hit_timer

var mesh_material = preload("res://resources/materials/enemy_mat_gamma_corrected.tres")
var blood = preload("res://scenes/environment/blood_particles.tscn")
var rocket = preload("res://scenes/props/enemies/gunner_rocket.tscn")
@export var gibs : PackedScene
@onready var body = $mesh/mountainside_chaingunner
@onready var chaingun = $mesh/mountainside_chaingunner/chaingun

@onready var init_mesh_pos = $mesh.global_position - position
@onready var dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))

@export var respawn_time = 10.0
@export var spawn_ang = 0.0
@export_range(0, 4) var min_dif : int = 0
@onready var rot = mesh.rotation.y

var sees_player = 0
var prev_pos = Vector3.ZERO

var in_active_zone = 1

func make_inactive():
	in_active_zone = 0

func is_active():
	return in_active_zone and dist_from_player < ACTIVE_RADIUS


func _ready():
	visible = true
	
	var is_opengl = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"
	if is_opengl:
		mesh_material = preload("res://resources/materials/opengl/enemy_mat_opengl.tres")
	
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	disable_particles = config.get_value("video", "disable_particles", false)
	disable_gibs = config.get_value("video", "disable_gibs", false)
	
	health = HP
	update_healthbar()
	
	#determine at what height to put the enemy home
	ray.target_position = Vector3(0, -10, 0)
	var max_height = -1000000
	const CHECKS = 4
	for i in range(CHECKS):
		var pos = Vector2.RIGHT.rotated(2 * PI * i / CHECKS) * RADIUS
		ray.position = Vector3(pos.x, ray.position.y, pos.y)
		ray.force_raycast_update()
		if ray.is_colliding():
			var col = ray.get_collision_point().y
			if col > max_height:
				max_height = col
	home.global_position.y = max_height
	ray.position = Vector3(0, ray.position.y, 0)
	ray.force_raycast_update()
	if ray.is_colliding():
		global_position.y = ray.get_collision_point().y
	
	mesh.top_level = 1
	if rotation.y != 0:
		spawn_ang += rotation.y
		rotation.y = 0
	rot = spawn_ang
	
	var node = self
	while node != get_tree().root:
		for g in node.get_groups():
			if g.is_valid_int():
				home.add_to_group(g)
				add_to_group(g)
		node = node.get_parent()
	
	respawn.wait_time = respawn_time
	for i in get_tree().get_nodes_in_group("see_through"):
		ray.add_exception(i)
	
	for c in get_children():
		if c.is_in_group("drop"):
			drops.push_back(c)
			remove_child(c)
			key.visible = 1
	
	var diff = config.get_value("gameplay", "difficulty", 2)
	if diff < min_dif and drops.is_empty():
		queue_free()


func add_particles(edmg):
	if disable_particles:
		return
	var new_blood = blood.instantiate()
	if edmg < health:
		new_blood.dir = Vector3.FORWARD.rotated(Vector3.UP, randf_range(-PI, PI)) + Vector3(0, 0.5, 0)
	else:
		new_blood.spread = 180
	new_blood.speed = clamp(edmg / 10, 1, 10)
	add_child(new_blood)
	new_blood.position = position + Vector3(0, 1.5, 0) + new_blood.dir.normalized() * 0.35
	new_blood.amount = clamp(edmg / 2, 5, 50)


func add_gibs(dmg):
	if disable_gibs or get_tree().current_scene == null:
		return
	var new_gibs = gibs.instantiate()
	new_gibs.position = position
	new_gibs.rotation.y = mesh.rotation.y
	get_tree().current_scene.add_child(new_gibs)
	new_gibs.dir = (position - player.position).normalized() * clamp(dmg / 10, 1, 10)


func pain(dmg):
	if rising or not alive or health <= 0:
		return
	
	var edmg = roundi(dmg * vulnerability)
	
	if edmg >= health:
		add_gibs(edmg)
	
	add_particles(edmg)
	
	pain_col = 1.0
	health -= dmg * vulnerability
	update_healthbar()
	if player.wpn == 1:
		player.health = player.health + REVOLVER_HEAL


func update_healthbar():
	health_label.text = str(max(0, health))


func _process(delta):
	dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
	
	mesh.visible = (alive and not rising) or (rising and int(rising_timer / RISE_FLICKER) % 2 == 1)
	health_label.visible = alive
	alerted.visible = not hit_timer.is_stopped()
	alerted.position = Vector3(0, 1.862, 0) + Vector3(0, 0.5, 0) * int(key.visible)
	
	if not alive:
		cross.visible = 1
		return
	cross.visible = 0
	
	pain_col = max(0, pain_col - delta * 2)
	const FADE_RANGE = 1
	var pb_col = clamp(lerp(0.0, 1.0, (player.SHOTGUN_PB_RANGE - dist_from_player) / FADE_RANGE) ,0.0, 1.0)
	var col = max(pain_col, pb_col) * 0.5
	body.set_instance_shader_parameter("pain", col)
	chaingun.set_instance_shader_parameter("pain", col)


func rising_func(t):
	return (1 - 1 / (10 * t + 1)) * 1.1


func _physics_process(delta):
	mesh.global_position = position + init_mesh_pos
	if not is_active() or not alive:
		return
	
	var dir2player = player.global_position - global_position
	var dir2player2D = Vector2(dir2player.x, dir2player.z).normalized()
	var player_dir = player.cam.transform.basis.z
	var player_dir2D = Vector2(player_dir.x, player_dir.z).normalized()
	raycast_hitbox.disabled = rising or not alive or dir2player2D.dot(player_dir2D) < player.MIN_HIT_DOT_PROD
	
	if rising and rising_timer < RISE_TIME:
		mesh.rotation.y = spawn_ang
		rising_timer += delta
		velocity.y = 0.0
		position.y = rising_func(rising_timer / RISE_TIME) * (RISE_HEIGHT + GRAVE_DEPTH) + home.position.y - GRAVE_DEPTH
		return
	else:
		rising = 0
	
	if health <= 0 and alive:
		if not has_died:
			has_died = 1
			key.visible = 0
			for c in drops:
				add_child(c)
				c.top_level = 1
				c.global_position = global_position + Vector3(0, 2, 0)
		home.time_left = respawn_time
		alive = 0
		$hit_timer.stop()
		respawn.start()
		position = home.position
		position.y -= GRAVE_DEPTH
	
	rot = fposmod(rot, 2 * PI)
	mesh.rotation.y = fposmod(mesh.rotation.y, 2 * PI)
	var dif = fposmod(rot - mesh.rotation.y, 2 * PI)
	if dif < MAX_TURN_SPEED * delta or 2 * PI - dif < MAX_TURN_SPEED * delta:
		mesh.rotation.y = rot
	else:
		if dif < PI:
			mesh.rotation.y += MAX_TURN_SPEED * delta
		else:
			mesh.rotation.y -= MAX_TURN_SPEED * delta
	
	if prev_pos != position:
		prev_pos = position
		ray.target_position = Vector3(0, -1.7, 0)
		ray.force_raycast_update()
		if not ray.is_colliding():
			position.y -= 9.8 * delta
		else:
			position.y = ray.get_collision_point().y
	
	ray.target_position = ray.to_local(player.position + Vector3(0, 1.5, 0)).normalized() * HIT_RANGE
	ray.force_raycast_update()
	
	sees_player = ray.is_colliding() and ray.get_collider().is_in_group("player")
	if sees_player:
		if hit_timer.is_stopped():
			hit_timer.start()
		var dir = player.position - position
		rot = -atan2(dir.z, dir.x) + PI / 2


func _on_hit_timer_timeout():
	pass


func _on_respawn_timeout():
	health = HP
	update_healthbar()
	alive = 1
	rising = 1
	rising_timer = 0

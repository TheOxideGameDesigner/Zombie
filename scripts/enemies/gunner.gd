extends StaticBody3D


var HP : int = 300
const HYPNO_RESISTANCE = 17
const HYPNO_HEALTH_DRAIN = 7
var hypno_health_drain_timer = 0.0
var hypnotizable : bool = true
var hypno_timer = 0.0
var ROCKET_SPEED = 30
const REVOLVER_HEAL : int = 2
const HIT_RANGE : float = 25
const GRAVE_DEPTH : float = 4
const RISE_HEIGHT : float = 0.25
const RISE_FLICKER : float = 0.25
const RISE_TIME : float = 3.7664
const MAX_TURN_SPEED = 3 * PI
const RADIUS = 1
const ACTIVE_RADIUS = 64

var rising = 0
var health : int
var alive : bool = 1
var rising_timer = 0.0
var has_died = 0
var drops = []

var pain_col = 0.0

var disable_particles : bool = false
var disable_gibs : bool = false

@onready var player = get_tree().get_first_node_in_group("player")
@onready var player_cam = player.get_node("cam")
@onready var target = player
@onready var home = $home
@onready var cross = $home/cross
@onready var health_label = $mesh/health
@onready var mesh = $mesh
@onready var mesh_body = $mesh/mountainside_gunner
@onready var hitbox = $hitbox
@onready var ray = $ray
@onready var alerted = $mesh/alerted
@onready var key = $mesh/key
@onready var respawn = $respawn
@onready var aura = $mesh/aura
@onready var raycast_hitbox = $raycast_collision/raycast_hitbox
@onready var raycast_area = $raycast_collision
@onready var hit_timer = $hit_timer

var mesh_material = preload("res://resources/materials/enemy_mat.tres")
var blood = preload("res://scenes/environment/blood_particles.tscn")
var rocket = preload("res://scenes/props/enemies/gunner_rocket.tscn")
@export var gibs : PackedScene
@onready var body = $mesh/mountainside_gunner/Armature/Skeleton3D/gunner_body

@onready var init_mesh_pos = $mesh.global_position - position
@onready var dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
@onready var dist_from_target = dist_from_player

@export var respawn_time = 10.0
@export var spawn_ang = 0.0
@export_range(0, 4) var min_dif : int = 0
@onready var rot = mesh.rotation.y

var sees_target = 0
var prev_pos = Vector3.ZERO
var hypno_col = 0.0
var hypno : bool = false


func hypnotize():
	target = null
	hypno = true
	add_to_group("hypno")
	set_collision_layer_value(10, true)
	ray.set_collision_mask_value(2, true)
	ray.set_collision_mask_value(9, false)
	alerted.visible = false
	update_healthbar()


func unhypnotize():
	hypno_timer = 0.0
	hypno = false
	remove_from_group("hypno")
	set_collision_layer_value(10, false)
	ray.set_collision_mask_value(2, false)
	ray.set_collision_mask_value(9, true)


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
	
	for c in get_children():
		if c.is_in_group("drop"):
			drops.push_back(c)
			remove_child(c)
			key.visible = 1
	
	var diff = config.get_value("gameplay", "difficulty", 2)
	if diff < min_dif and drops.is_empty():
		queue_free()
	
	body.set_surface_override_material(0, mesh_material)


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


func pain(dmg, noblood=false, heal_player = false):
	if rising or not alive or health <= 0:
		return
	
	if dmg >= health:
		add_gibs(dmg)
	
	if not noblood:
		add_particles(dmg)
		pain_col = 1.0
	
	health -= dmg
	update_healthbar()
	if heal_player:
		player.health = player.health + REVOLVER_HEAL


func update_healthbar():
	health_label.text = str(max(0, health))


func rising_func(t):
	return (1 - 1 / (10 * t + 1)) * 1.1


func ai(delta):
	if hypno:
		if hypno_health_drain_timer <= 0:
			hypno_health_drain_timer = 0.2
			pain(HYPNO_HEALTH_DRAIN, true)
		hypno_health_drain_timer -= delta
		hypno_timer += delta
	
	if target == null:
		dist_from_target = 10000
	else:
		dist_from_target = Vector2(target.position.x, target.position.z).distance_to(Vector2(position.x, position.z))
	mesh.global_position = position + init_mesh_pos
	if not alive:
		return
	
	var dir2player = player.global_position - global_position
	var dir2player2D = Vector2(dir2player.x, dir2player.z).normalized()
	raycast_area.rotation.y = -atan2(dir2player2D.y, dir2player2D.x) + PI / 2
	raycast_hitbox.disabled = rising or not alive
	
	if rising and rising_timer < RISE_TIME:
		mesh.rotation.y = spawn_ang
		rising_timer += delta
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
		if hypno:
			unhypnotize()
	
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
	
	#determine target
	if not hypno:
		var min_dist = HIT_RANGE
		ray.target_position = ray.to_local(player.position + Vector3(0, 1.5, 0)).normalized() * HIT_RANGE
		ray.force_raycast_update()
		if ray.get_collider() == player:
			min_dist = dist_from_player
			target = player
		for hombie in get_tree().get_nodes_in_group("hypno"):
			var dist_from_hombie = Vector2(hombie.position.x, hombie.position.z).distance_to(Vector2(position.x, position.z))
			if dist_from_hombie < HIT_RANGE:
				ray.target_position = ray.to_local(hombie.position + Vector3(0, 1.5, 0)).normalized() * HIT_RANGE
				ray.force_raycast_update()
				if ray.get_collider() == hombie:
					if dist_from_hombie < min_dist and hombie.hypno_timer > 1:
						target = hombie
						min_dist = dist_from_hombie
					if hombie.dist_from_target >= dist_from_hombie:
						hombie.target = self
						hombie.dist_from_target = dist_from_hombie
	
	if target != player and target != null and (not target.alive or target.hypno == hypno):
		target = null
		alerted.visible = false
	
	if target == null:
		sees_target = false
	else:
		ray.target_position = ray.to_local(target.position + Vector3(0, 1.5, 0)).normalized() * HIT_RANGE
		ray.force_raycast_update()
		sees_target = ray.is_colliding() and ray.get_collider() == target
	
	if sees_target:
		if hit_timer.is_stopped():
			hit_timer.start()
		var dir
		if target == player:
			dir = player_cam.position - position
		else:
			dir = target.position - position
		rot = -atan2(dir.z, dir.x) + PI / 2


func _process(delta):
	dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
	if dist_from_player > ACTIVE_RADIUS:
		mesh_body.process_mode = Node.PROCESS_MODE_DISABLED
		return
	else:
		mesh_body.process_mode = Node.PROCESS_MODE_INHERIT
	
	ai(delta)
	
	mesh.visible = (alive and not rising) or (rising and int(rising_timer / RISE_FLICKER) % 2 == 1)
	health_label.visible = alive
	alerted.visible = not hit_timer.is_stopped() or sees_target
	alerted.position = Vector3(0, 1.862, 0) + Vector3(0, 0.5, 0) * int(key.visible)
	
	if not alive:
		cross.visible = 1
		return
	cross.visible = 0
	
	if pain_col > 0.0 or dist_from_player < player.SHOTGUN_PB_RANGE:
		pain_col = max(0, pain_col - delta * 2)
		const FADE_RANGE = 1
		var pb_col = clamp(lerp(0.0, 1.0, (player.SHOTGUN_PB_RANGE - dist_from_player) / FADE_RANGE) ,0.0, 1.0)
		var col = max(pain_col, pb_col) * 0.5
		body.set_instance_shader_parameter("pain", col)
	if hypno:
		hypno_col = min(0.35, hypno_col + delta)
		body.set_instance_shader_parameter("hypno", hypno_col)
	else:
		hypno_col = max(0.0, hypno_col - delta)
		body.set_instance_shader_parameter("hypno", hypno_col)


func _on_hit_timer_timeout():
	if target == null:
		return
	mesh_body.play("shooting", 0.3)
	var new_rocket = rocket.instantiate()
	new_rocket.target = target
	new_rocket.death_message = "You were killed by a gunner"
	new_rocket.SPEED = ROCKET_SPEED
	new_rocket.set_vel(target.position - position)
	new_rocket.position = Vector3(0.102,1.17,1.54).rotated(Vector3.UP, mesh.rotation.y)
	if hypno:
		new_rocket.set_collision_mask_value(2, true)
	else:
		new_rocket.set_collision_mask_value(10, true)
	add_child(new_rocket)
	new_rocket.top_level = 1

func _on_respawn_timeout():
	health = HP
	update_healthbar()
	alive = 1
	rising = 1
	rising_timer = 0

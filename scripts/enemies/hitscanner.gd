extends CharacterBody3D

var HP : int = 100
const HYPNO_RESISTANCE = 1.5
const HYPNO_HEALTH_DRAIN = 1
var hypno_health_drain_timer = 0.0
var hypno_health = 1.0
var hypnotizable : bool = true
var hypno_timer = 0.0
const SPEED = 5
const WALK_FREQ = 1
const MAX_TURN_SPEED = 2 * PI
const MAX_TURN_SPEED_AIMING = PI / 5

const PUSH_FORCE = 2.5

const GR_ACCEL = 9.8
const RADIUS = 0.5

const VIS_RANGE = 30
const GRAVE_DEPTH = 4
const RISE_TIME = 3.7664
const RISE_HEIGHT = 0.25
const RISE_FLICKER = 0.25
const AIM_TIME : float = 0.5
const HIT_RANGE : float = 20
const HIT_RANGE_MARGIN = 1.0
const PB_RANGE : float = 2
const FALLOFF : float = 0.1
var HIT_TIME : float = 1.25
const HIT_DAMAGE : int = 40
const REVOLVER_HEAL : int = 5
const ATTENTION_SPAN : float = 10

const ACTIVE_RADIUS = 64
const TARGET_RADIUS = 4


var rising = 0
var health : int
var alive = 1
var target_pos = Vector3.ZERO
var sees_target = false
var aim_timer = AIM_TIME
var rising_timer = 0.0
var hit_timer = HIT_TIME
var attention_span_timer = 0
var hypno : bool = 0
var hypno_col = 0.0

var pain_col = 0.0

var bumps : Array[Vector3] = []
var bump_timers : Array[float] = []


@onready var mesh_body = $mesh/mountainside_hitscanner
@onready var player = get_tree().get_first_node_in_group("player")
@onready var target = player
@onready var home = $home
@onready var health_label = $mesh/health
@onready var mesh = $mesh
@onready var hitbox = $hitbox
@onready var ray = $ray
@onready var alerted = $mesh/alerted
@onready var respawn = $respawn
@onready var collision_area = $collision_area
@onready var aura = $mesh/aura
@onready var raycast_hitbox = $raycast_collision/raycast_hitbox
@onready var collision_area_hitbox = $collision_area/collision_area_hitbox
@onready var ribbon = $mesh/ribbon
@onready var ribbon_mesh = $mesh/ribbon/ribbon_mesh

var mesh_material = preload("res://resources/materials/enemy_mat.tres")
var blood = preload("res://scenes/environment/blood_particles.tscn")
@export var gibs : PackedScene
@export var gibs_standing : PackedScene
@onready var body = $mesh/mountainside_hitscanner/Armature/Skeleton3D/runner_body

@onready var init_mesh_pos = $mesh.global_position - position
@onready var init_ribbon_pos = ribbon.position
@onready var dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
@onready var dist_from_target = dist_from_player

@onready var rot = mesh.rotation.y
var y_vel = 0.0

@export var respawn_time = 10.0
@export var spawn_ang = 0.0
@export_range(0, 4) var min_dif : int = 0

var disable_particles : bool = false
var disable_gibs : bool = false

var add_vel = Vector3.ZERO


func hypnotize():
	target = null
	hypno = true
	add_to_group("hypno")
	set_collision_layer_value(10, true)
	ray.set_collision_mask_value(2, true)
	ray.set_collision_mask_value(9, false)
	alerted.visible = false
	hypno_health = 1.0
	update_healthbar()


func unhypnotize():
	hypno_timer = 0.0
	hypno = false
	remove_from_group("hypno")
	set_collision_layer_value(10, false)
	ray.set_collision_mask_value(2, false)
	ray.set_collision_mask_value(9, true)


func is_active():
	return dist_from_player < ACTIVE_RADIUS


func is_asleep():
	return not alerted.visible


func _ready():
	visible = true
	
	var is_opengl = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"
	if is_opengl:
		mesh_material = preload("res://resources/materials/opengl/enemy_mat_opengl.tres")
	
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	disable_particles = config.get_value("video", "disable_particles", false)
	disable_gibs = config.get_value("video", "disable_gibs", false)
	
	var diff = config.get_value("gameplay", "difficulty", 2)
	if diff < min_dif:
		queue_free()
	
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
	mesh.rotation.y = spawn_ang
	rot = mesh.rotation.y
	
	var node = self
	while node != get_tree().root:
		for g in node.get_groups():
			if g.is_valid_int():
				home.add_to_group(g)
				add_to_group(g)
		node = node.get_parent()
	
	target_pos = home.global_position
	respawn.wait_time = respawn_time
	
	body.set_surface_override_material(0, mesh_material)
	ribbon_mesh.material_override = preload("res://resources/materials/ribbon_mat.tres").duplicate()
	ribbon.top_level = 1



func add_particles(edmg):
	if disable_particles:
		return
	var new_blood = blood.instantiate()
	if edmg < health:
		new_blood.dir = velocity.rotated(Vector3.UP, (randi_range(0, 2) - 1) * (PI / 2 + randf_range(-PI/10, PI/10))) + Vector3(0, 0.5, 0)
	else:
		new_blood.spread = 180
	new_blood.speed = clamp(edmg / 10, 1, 10)
	add_child(new_blood)
	new_blood.position = position + Vector3(0, 1.5, 0) + new_blood.dir.normalized() * 0.25
	new_blood.amount = clamp(edmg / 2, 5, 50)


func add_gibs(dmg):
	if disable_gibs or get_tree().current_scene == null:
		return
	var new_gibs
	if dist_from_target < HIT_RANGE:
		new_gibs = gibs.instantiate()
	else:
		new_gibs = gibs_standing.instantiate()
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
	
	if hypno or sees_target:
		return
	
	alerted.visible = 1
	target_pos = player.position


func fire():
	ribbon_mesh.material_override.albedo_color.a = 0.5
	var dir = Vector3(0, 0, 1).rotated(Vector3.UP, mesh.rotation.y)
	ray.position = Vector3(0.079, 1.642, 0.847).rotated(Vector3.UP, mesh.rotation.y)
	ray.target_position = dir * (dist_from_target - 0.847) + Vector3(0, target.position.y - ray.global_position.y + 1.5, 0) + Vector3(-0.079, 0, 0).rotated(Vector3.UP, mesh.rotation.y)
	ray.force_raycast_update()
	ribbon.position = mesh.to_global(init_ribbon_pos)
	ribbon.rotation.y = mesh.rotation.y
	ribbon.rotation.x = -atan2(ray.to_local(player.position).y + 1.5, dist_from_target)
	if ray.is_colliding():
		ribbon.scale.z = ribbon.global_position.distance_to(ray.get_collision_point())
	else:
		ribbon.scale.z = HIT_RANGE
	if ray.is_colliding() and ray.get_collider() == target:
		var dmg
		if dist_from_target < PB_RANGE:
			dmg = HIT_DAMAGE
		else:
			dmg = HIT_DAMAGE / (FALLOFF * (dist_from_target - PB_RANGE) + 1)
		if target == player:
			player.pain("You were killed by a shooter", dmg)
		else:
			target.pain(dmg)


func update_healthbar():
	health_label.modulate = Color(1, hypno_health, 1)
	health_label.text = str(max(0, floor(health * hypno_health)))


func _process(delta):
	ribbon_mesh.material_override.albedo_color.a = max(0, ribbon_mesh.material_override.albedo_color.a - delta)
	dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
	dist_from_target = position.distance_to(player.position)
	if not is_active():
		mesh_body.process_mode = Node.PROCESS_MODE_DISABLED
		return
	else:
		mesh_body.process_mode = Node.PROCESS_MODE_INHERIT
	
	mesh.visible = (alive and not rising) or (rising and int(rising_timer / RISE_FLICKER) % 2 == 1)
	health_label.visible = alive
	
	if not alive:
		return
	
	pain_col = max(0, pain_col - delta * 2)
	const FADE_RANGE = 1
	var pb_col = clamp(lerp(0.0, 1.0, (player.SHOTGUN_PB_RANGE - dist_from_player) / FADE_RANGE) ,0.0, 1.0)
	var col = max(pain_col, pb_col) * 0.5
	body.set_instance_shader_parameter("pain", col)
	if hypno:
		hypno_col = min(0.35, hypno_col + delta)
	else:
		hypno_col = max(0.0, hypno_col - delta)
	body.set_instance_shader_parameter("hypno", hypno_col)
	
	if rising or is_asleep() or velocity.length() < 0.1:
		mesh_body.anim_timer = 0.0
	else:
		mesh_body.anim_speed = 1.5
		mesh_body.anim_amplitude = PI / 6
	
	if dist_from_target <= HIT_RANGE - HIT_RANGE_MARGIN and sees_target:
		mesh_body.legs_playing = 0
	else:
		mesh_body.legs_playing = 1


func rising_func(t):
	return (1 - 1 / (10 * t + 1)) * 1.1


func process_bumps(delta : float):
	for i in range(bumps.size()):
		position += bumps[i] * delta * 5
		bump_timers[i] -= delta
	
	var i = 0
	while i < bumps.size():
		if bump_timers[i] > 0:
			i += 1
		else:
			bumps.remove_at(i)
			bump_timers.remove_at(i)


func _physics_process(delta):
	if hypno_health <= 0:
		hypnotize()
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
	mesh.position = position + init_mesh_pos
	
	if not is_active():
		return
	
	if not alive:
		return
	
	var asleep = is_asleep()
	hitbox.disabled = not rising and not hypno and (not alive or (asleep and add_vel.is_zero_approx()))
	
	var dir2player = player.global_position - global_position
	var dir2player2D = Vector2(dir2player.x, dir2player.z).normalized()
	var player_dir = player.cam.transform.basis.z
	var player_dir2D = Vector2(player_dir.x, player_dir.z).normalized()
	raycast_hitbox.disabled = rising or not alive or dir2player2D.dot(player_dir2D) < player.MIN_HIT_DOT_PROD
	
	collision_area_hitbox.disabled = not alive
	
	if rising and rising_timer < RISE_TIME:
		add_vel = Vector3.ZERO
		mesh.rotation.y = spawn_ang
		rising_timer += delta
		velocity.y = 0.0
		position.y = rising_func(rising_timer / RISE_TIME) * (RISE_HEIGHT + GRAVE_DEPTH) + home.position.y - GRAVE_DEPTH
		return
	else:
		rising = 0
	
	if health <= 0:
		unhypnotize()
		home.time_left = respawn_time
		alive = 0
		respawn.start()
		position = home.position
		position.y -= GRAVE_DEPTH
	
	
	
	rot = fposmod(rot, 2 * PI)
	mesh.rotation.y = fposmod(mesh.rotation.y, 2 * PI)
	var dif = fposmod(rot - mesh.rotation.y, 2 * PI)
	var max_turn_speed
	if dist_from_target < HIT_RANGE and not hypno:
		max_turn_speed = MAX_TURN_SPEED_AIMING
	else:
		max_turn_speed = MAX_TURN_SPEED
	if dif < max_turn_speed * delta or 2 * PI - dif < max_turn_speed * delta:
		mesh.rotation.y = rot
	else:
		if dif < PI:
			mesh.rotation.y += max_turn_speed * delta
		else:
			mesh.rotation.y -= max_turn_speed * delta
	
	for area in collision_area.get_overlapping_areas():
		var dir = Vector3(position.x, 0, position.z) - \
			  Vector3(area.global_position.x, 0, area.global_position.z)
		for i in area.get_children():
			if not i is CollisionShape3D:
				continue
			if not i.shape is CylinderShape3D:
				continue
			var displacement
			if dir.dot(velocity) > 0:
				displacement = (dir.normalized() * (RADIUS + i.shape.radius - dir.length())).project(velocity.rotated(Vector3.UP, PI / 2))
			else:
				displacement = (dir.normalized() * (RADIUS + i.shape.radius - dir.length()))
			if displacement.length() < 0.5:
				position += displacement
			break
	
	process_bumps(delta)
	
	const ADD_VEL_DECAY = 10
	if add_vel.length() > ADD_VEL_DECAY * delta:
		add_vel -= add_vel.normalized() * delta * ADD_VEL_DECAY
	else:
		add_vel = Vector3.ZERO
	
	#zombie logic
	
	#determine target
	if not hypno:
		var min_dist = VIS_RANGE
		ray.target_position = ray.to_local(player.position + Vector3(0, 1.5, 0)).normalized() * VIS_RANGE
		ray.force_raycast_update()
		if ray.get_collider() == player:
			min_dist = dist_from_player
			target = player
		for hombie in get_tree().get_nodes_in_group("hypno"):
			var dist_from_hombie = Vector2(hombie.position.x, hombie.position.z).distance_to(Vector2(position.x, position.z))
			if dist_from_hombie < VIS_RANGE:
				ray.target_position = ray.to_local(hombie.position + Vector3(0, 1.5, 0)).normalized() * VIS_RANGE
				ray.force_raycast_update()
				if ray.get_collider() == hombie:
					if dist_from_hombie < min_dist and hombie.hypno_timer > 1:
						target = hombie
						min_dist = dist_from_hombie
					if hombie.dist_from_target >= dist_from_hombie:
						hombie.target = self
						hitbox.disabled = false
						hombie.dist_from_target = dist_from_hombie
	
	if target != player and target != null and (not target.alive or target.hypno == hypno):
		target = null
		alerted.visible = false
	
	if target == null:
		sees_target = false
	else:
		ray.position = Vector3(0.079, 1.642, 0.847).rotated(Vector3.UP, mesh.rotation.y)
		ray.target_position = ray.to_local(target.position + Vector3(0, 1, 0)).normalized() * VIS_RANGE
		ray.force_raycast_update()
		sees_target = ray.is_colliding() and ray.get_collider() == target
	if sees_target:
		target_pos = target.position
		attention_span_timer = 0
		alerted.visible = 1
	else:
		if alerted.visible:
			if position.distance_to(target_pos) > TARGET_RADIUS:
				attention_span_timer += delta
			else:
				attention_span_timer = ATTENTION_SPAN + 1
	if attention_span_timer > ATTENTION_SPAN:
		attention_span_timer = 0
		alerted.visible = 0
	#end of zombie logic
	
	#zombie movement
	if not add_vel.is_zero_approx():
		velocity = add_vel + Vector3(0, y_vel, 0)
		move_and_slide()
	
	if not asleep:
		var nextpos = target_pos - position
		
		if sees_target and dist_from_target < HIT_RANGE and alive and not rising:
			if aim_timer <= 0.0:
				hit_timer -= delta
				if hit_timer <= 0.2 and not mesh_body.is_playing():
					mesh_body.play("hitting", 0.4)
					fire()
					hit_timer = HIT_TIME
			else:
				if aim_timer == AIM_TIME:
					mesh_body.play("aiming", 0.2)
				aim_timer -= delta
		else:
			if aim_timer < AIM_TIME:
				mesh_body.play("aiming", -0.2)
			aim_timer = AIM_TIME
			hit_timer = HIT_TIME
		
		rot = -atan2(nextpos.z, nextpos.x) + PI / 2
		var vel_dir = Vector3.MODEL_FRONT.rotated(Vector3.UP, mesh.rotation.y)
		
		ray.position = vel_dir * 0.25 + Vector3(0, ray.position.y, 0)
		ray.target_position = Vector3(0, -5, 0)
		ray.force_raycast_update()
		ray.position = Vector3(0, ray.position.y, 0)
		if ray.is_colliding():
			velocity = SPEED * vel_dir
		else:
			velocity = Vector3(0, velocity.y, 0)
		
		if is_on_floor():
			y_vel = 0
		else:
			y_vel -= GR_ACCEL * delta
		
		velocity.y = y_vel
		
		if dist_from_target > HIT_RANGE - HIT_RANGE_MARGIN or not sees_target:
			move_and_slide()
		else:
			ray.position = Vector3(0, 1.5, 0)
			ray.target_position = Vector3(0, -1.7, 0)
			ray.force_raycast_update()
			if not ray.is_colliding():
				position.y -= 9.8 * delta
			else:
				position.y = ray.get_collision_point().y
	#end of zombie movement


func _on_respawn_timeout():
	hypno_health = 1.0
	health = HP
	update_healthbar()
	alive = 1
	target_pos = home.position
	rising = 1
	rising_timer = 0
	alerted.visible = 0

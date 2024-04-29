extends CharacterBody3D

var HP : int = 100
const HYPNO_RESISTANCE = 1.5
const HYPNO_HEALTH_DRAIN = 1
var hypno_health_drain_timer = 0.0
var SPEED = 8
const WALK_SPEED = 1
const JUMP_SPEED = 4
const CLIMB_SPEED = 2
const WALK_FREQ = 1
const MAX_TURN_SPEED = 5 * PI

const PUSH_FORCE = 2.5

const GR_ACCEL = 9.8
const RADIUS = 0.5

const VIS_RANGE = 25
const GRAVE_DEPTH = 4
const RISE_TIME = 3.7664
const RISE_HEIGHT = 0.25
const RISE_FLICKER = 0.25
const HIT_RANGE : float = 3
const HIT_TIME : float = 1
const HIT_DAMAGE : int = 25
const REVOLVER_HEAL : int = 5
const ATTENTION_SPAN : float = 10

const ACTIVE_RADIUS = 64
const TARGET_RADIUS = 0.5


var rising = 0
var health : int
var hypno_health = 1.0
var hypno_timer = 0.0
var hypnotizable : bool = true
var alive = 1
var target_pos = Vector3.ZERO
var sees_target
var climbing = 0
var prev_on_floor = 0
var rising_timer = 0.0
var hit_timer = HIT_TIME
var attention_span_timer = 0

var roaming_timer = 0.0
var pain_col = 0.0

var bumps : Array[Vector3] = []
var bump_timers : Array[float] = []


@onready var mesh_body = $mesh/mountainside_runner
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
var mesh_material = preload("res://resources/materials/enemy_mat.tres")
var blood = preload("res://scenes/environment/blood_particles.tscn")
@export var gibs : PackedScene
@onready var is_visible = $is_visible
@onready var body = $mesh/mountainside_runner/Armature/Skeleton3D/runner_body

@onready var init_mesh_pos = $mesh.global_position - position
@onready var dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
@onready var dist_from_target = dist_from_player

@onready var rot = mesh.rotation.y
var y_vel = 0.0

@export var respawn_time = 10.0
@export var spawn_ang = 0.0
@export var sedated = false
@export_range(0, 4) var min_dif = 0
var rand_roam_off

var disable_particles : bool = false
var disable_gibs : bool = false

var add_vel = Vector3.ZERO
var hypno_col = 0.0
var hypno : bool = false

var is_opengl


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
	
	is_opengl = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"
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
	
	seed(position.x + position.z)
	rand_roam_off = randf_range(0, PI * 2)
	
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
	var new_gibs = gibs.instantiate()
	new_gibs.position = position
	new_gibs.rotation.y = mesh.rotation.y
	get_tree().current_scene.add_child(new_gibs)
	new_gibs.dir = (position - player.position).normalized() * clamp(dmg / 10, 1, 10)


func pain(dmg, noblood=false, heal_player = false, player_inflicted = false):
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
	
	if sedated or hypno or sees_target:
		return
	
	alerted.visible = 1
	target_pos = player.position


func update_healthbar():
	health_label.modulate = Color(1, hypno_health, 1)
	health_label.text = str(max(0, floor(health * hypno_health)))


func _process(delta):
	dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
	if not is_active():
		mesh_body.process_mode = Node.PROCESS_MODE_DISABLED
		return
	else:
		mesh_body.process_mode = Node.PROCESS_MODE_INHERIT
	
	if health <= 0 and alive:
		home.time_left = respawn_time
		alive = 0
		if hypno:
			unhypnotize()
		respawn.start()
		position = home.position
		position.y -= GRAVE_DEPTH
	
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
	
	if rising:
		mesh_body.anim_timer = 0.0
	if is_asleep():
		mesh_body.anim_speed = 1.0
		mesh_body.anim_amplitude = PI / 12
		mesh_body.bob_amplitude = 0.0
	else:
		mesh_body.anim_speed = 1.5
		mesh_body.anim_amplitude = PI / 6
		if is_on_floor() and add_vel.is_zero_approx():
			mesh_body.bob_amplitude = 0.1
		else:
			mesh_body.bob_amplitude = 0.0
	
	if (dist_from_target <= 1.1 and player.velocity.length() < 0.1) or (dist_from_target < 0.2):
		mesh_body.legs_playing = 0
	else:
		mesh_body.legs_playing = 1


func roaming_ang_func(t):
	t = t * WALK_FREQ
	return fposmod((2 * t + sin(2 * t)) / 2, 2 * PI)

func rising_func(t):
	return (1 - 1 / (10 * t + 1)) * 1.1

var wall_check_angle = 0
func roam_physics(delta):
	if not add_vel.is_zero_approx():
		move_and_slide()
		return
	ray.target_position = Vector3.FORWARD.rotated(Vector3.UP, wall_check_angle) * RADIUS
	ray.force_raycast_update()
	if ray.is_colliding():
		bumps.push_back(-1 * ray.target_position / RADIUS)
		bump_timers.push_back(0.1)
	wall_check_angle += 1
	
	ray.target_position = Vector3(0, -2, 0)
	ray.force_raycast_update()
	if ray.is_colliding():
		var col = ray.get_collision_point().y
		var norm = ray.get_collision_normal()
		if norm.angle_to(Vector3.UP) > PI / 4:
			position += Vector3(norm.x, 0, norm.z).normalized() * delta * WALK_SPEED
		else:
			position += velocity * delta
		position.y = col
	else:
		position.y -= GR_ACCEL * delta


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
	
	if target != null:
		dist_from_target = Vector2(target.position.x, target.position.z).distance_to(Vector2(position.x, position.z))
	else:
		dist_from_target = 10000
	mesh.position = position + init_mesh_pos
	
	if not is_active():
		return
	
	if not alive:
		return
	
	var asleep = is_asleep()
	hitbox.disabled = not sedated and not rising and not hypno and (not alive or (asleep and add_vel.is_zero_approx()))
	
	var dir2player = player.global_position - global_position
	var dir2player2D = Vector2(dir2player.x, dir2player.z).normalized()
	var player_dir = player.cam.transform.basis.z
	var player_dir2D = Vector2(player_dir.x, player_dir.z).normalized()
	raycast_hitbox.disabled = hypno or rising or not alive or dir2player2D.dot(player_dir2D) < player.MIN_HIT_DOT_PROD
	
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
		if is_on_floor():
			y_vel = 0
		else:
			y_vel -= GR_ACCEL * delta
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
						hitbox.disabled = false
						hombie.target = self
	
	
	if target != player and target != null and (not target.alive or target.hypno == hypno):
		target = null
		alerted.visible = false
	
	if target == null:
		sees_target = false
	else:
		ray.target_position = ray.to_local(target.position + Vector3(0, 1.5, 0)).normalized() * VIS_RANGE
		ray.force_raycast_update()
		sees_target = not sedated and ray.get_collider() == target
	if sees_target:
		target_pos = target.position
		attention_span_timer = 0
		alerted.visible = 1
	else:
		if alerted.visible:
			if not is_on_floor() or position.distance_to(target_pos) > TARGET_RADIUS:
				attention_span_timer += delta
			else:
				attention_span_timer = ATTENTION_SPAN + 1
	if attention_span_timer > ATTENTION_SPAN:
		attention_span_timer = 0
		alerted.visible = 0
	#end of zombie logic
	
	var on_screen
	if is_opengl:
		on_screen = dir2player2D.dot(player_dir2D) > 0
	else:
		on_screen = is_visible.is_on_screen()
	
	#zombie movement
	if not add_vel.is_zero_approx():
		velocity = add_vel + Vector3(0, y_vel, 0)
		move_and_slide()
	elif asleep:
		if on_screen:
			prev_on_floor = 0
			
			roaming_timer += delta
			rot = roaming_ang_func(roaming_timer * WALK_FREQ) + rand_roam_off
			velocity = WALK_SPEED * Vector3.MODEL_FRONT.rotated(Vector3.UP, mesh.rotation.y)
			roam_physics(delta)
	else:
		#kill the zombie if it is standing on the player
		if dist_from_player < RADIUS + player.RADIUS - 0.05 and \
			position.y - player.position.y > 1.5 and position.y - player.position.y < 2.0:
				pain(100)
		
		var nextpos = target_pos - position
		
		if target != null and dist_from_target <= HIT_RANGE and alive and not rising \
		   and target.position.y - position.y > -2.1 and target.position.y - position.y < 1.2:
			if not on_screen and target == player:
				player.warning.modulate.a = 1.0
			hit_timer -= delta
			if hit_timer <= 0.35 and not mesh_body.is_playing():
				mesh_body.play("hitting", 4)
			if hit_timer <= 0:
				if target == player:
					player.pain("You were killed by a runner", HIT_DAMAGE)
				else:
					target.pain(HIT_DAMAGE)
				hit_timer = HIT_TIME
		else:
			hit_timer = HIT_TIME
		
		rot = -atan2(nextpos.z, nextpos.x) + PI / 2
		var vel_dir = Vector3.MODEL_FRONT.rotated(Vector3.UP, mesh.rotation.y)
		if (target == player and dist_from_target < 0.2) or (target != player and dist_from_target < 1.05):
			vel_dir = Vector3.ZERO
		velocity = SPEED * vel_dir.normalized()
		
		if climbing:
			y_vel = CLIMB_SPEED
		elif is_on_floor():
			y_vel = 0
		else:
			y_vel -= GR_ACCEL * delta
		
		
		if climbing:
			if not is_on_wall():
				climbing = 0
		elif is_on_wall() and is_on_floor():
			for i in range(get_slide_collision_count()):
				var col : KinematicCollision3D = get_slide_collision(i)
				if col.get_collider() == target:
					continue
				var normal = col.get_normal()
				normal.y = 0
				normal = normal.normalized()
				if col.get_angle() > PI / 4:
					ray.position.y = 0.7
					ray.target_position = -normal * RADIUS * 2
					ray.force_raycast_update()
					if not ray.is_colliding():
						y_vel = JUMP_SPEED
					elif vel_dir.dot(-normal) > 0.8:
						climbing = 1
					ray.position.y = 1.751
					break
		elif not is_on_floor() and prev_on_floor:
			y_vel = JUMP_SPEED
		prev_on_floor = is_on_floor()
		
		velocity.y = y_vel
		
		move_and_slide()
	#end of zombie movement


func _on_respawn_timeout():
	health = HP
	hypno_health = 1.0
	update_healthbar()
	alive = 1
	target_pos = home.position
	rising = 1
	rising_timer = 0
	alerted.visible = 0

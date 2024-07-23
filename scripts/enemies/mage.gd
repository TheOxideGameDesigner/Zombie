extends CharacterBody3D

var HP : int = 100
const SPEED = 5
const WALK_FREQ = 1
const MAX_TURN_SPEED = 3 * PI

const PUSH_FORCE = 2.5

const GR_ACCEL = 9.8
const RADIUS = 0.5

const VIS_RANGE = 30
const GRAVE_DEPTH = 4
const RISE_TIME = 3.7664
const RISE_HEIGHT = 0.25
const RISE_FLICKER = 0.25
const AIM_TIME : float = 0.25
const HIT_RANGE : float = 20
var ROCKET_SPEED = 20
const HIT_TIME : float = 1.5
const HIT_RANGE_MARGIN = 1.0
const PB_RANGE : float = 2
const FALLOFF : float = 0.1
const HIT_DAMAGE : int = 30
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
var attention_span_timer = 0

var pain_col = 0.0

var bumps : Array[Vector3] = []
var bump_timers : Array[float] = []


@onready var mesh_body = $mesh/mountainside_mage
@onready var player = get_tree().get_first_node_in_group("player")
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
@onready var raycast_area = $raycast_collision
@onready var collision_area_hitbox = $collision_area/collision_area_hitbox

var rocket = preload("res://scenes/props/enemies/gunner_rocket.tscn")
var mesh_material = preload("res://resources/materials/enemy_mat.tres")
var blood = preload("res://scenes/environment/blood_particles.tscn")
@export var gibs : PackedScene
@onready var body = $mesh/mountainside_mage/Armature/Skeleton3D/runner_body

@onready var dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))

@onready var rot = mesh.rotation.y
var y_vel = 0.0

@export var respawn_time = 10.0
var spawn_ang = 0.0
@export_range(0, 4) var min_dif : int = 0

var disable_particles : bool = false
var disable_gibs : bool = false

var add_vel = Vector3.ZERO

@onready var fireball = $mesh/fireball
const FB_TIME = 0.4666
var hit_timer = 0.0
var fb_timer = 0.0
const FB_POS = [Vector3(0, 0, 0.4), Vector3(0, 0, 0.3)]
var fired : bool = false


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



func add_particles(edmg):
	if disable_particles:
		return
	var new_blood = blood.instantiate()
	if edmg < health:
		new_blood.dir = velocity.rotated(Vector3.UP, ((randi() % 2) * 2 - 1) * (PI / 2 + randf_range(-PI/10, PI/10))) + Vector3(0, 0.5, 0)
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


func pain(dmg, noblood=false, heal_player = false, source = player):
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
	
	if sees_target:
		return
	
	alerted.visible = 1
	target_pos = source.position


func update_healthbar():
	health_label.text = str(max(0, health))


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


func ai(delta):
	if not alive:
		return
	
	var asleep = is_asleep()
	hitbox.disabled = not alive
	
	var dir2player = player.global_position - global_position
	var dir2player2D = Vector2(dir2player.x, dir2player.z).normalized()
	raycast_area.rotation.y = -atan2(dir2player2D.y, dir2player2D.x) + PI / 2
	raycast_hitbox.disabled = rising or not alive
	
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
		home.time_left = respawn_time
		alive = 0
		respawn.start()
		position = home.position
		position.y -= GRAVE_DEPTH
	
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
			if area.get_parent().is_in_group("lightweight"):
				displacement /= 2
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
	ray.position = Vector3(0, 1.5, 0)
	ray.target_position = ray.to_local(player.position + Vector3(0, 1, 0)).normalized() * VIS_RANGE
	ray.force_raycast_update()
	sees_target = ray.is_colliding() and ray.get_collider() == player
	if sees_target:
		target_pos = player.position
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
	
	hit_timer = max(0.0, hit_timer - delta)
	
	if not asleep:
		var nextpos = target_pos - position
		if sees_target and dist_from_player < HIT_RANGE and alive and not rising:
			if aim_timer <= 0.0 and hit_timer == 0.0:
				hit_timer = HIT_TIME
				fired = false
				fb_timer = FB_TIME
				mesh_body.play("hitting", 0.5)
			else:
				if aim_timer == AIM_TIME:
					mesh_body.play("aiming", 0.3)
				aim_timer -= delta
		else:
			if aim_timer < AIM_TIME:
				mesh_body.play("aiming", -0.3)
			aim_timer = AIM_TIME
		
		fireball.visible = fb_timer > 0.0
		
		if not fired and fb_timer == 0.0 and hit_timer > 0.0:
			fire()
			fired = true
		
		rot = -atan2(nextpos.z, nextpos.x) + PI / 2
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
		
		if dist_from_player > HIT_RANGE - HIT_RANGE_MARGIN or not sees_target:
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
	
	if not alive:
		return
	
	if pain_col > 0.0 or dist_from_player < player.SHOTGUN_PB_RANGE:
		pain_col = max(0, pain_col - delta * 2)
		const FADE_RANGE = 1
		var pb_col = clamp(lerp(0.0, 1.0, (player.SHOTGUN_PB_RANGE - dist_from_player) / FADE_RANGE) ,0.0, 1.0)
		var col = max(pain_col, pb_col) * 0.5
		body.set_instance_shader_parameter("pain", col)
	
	if rising or is_asleep() or velocity.length() < 0.1:
		mesh_body.anim_timer = 0.0
	else:
		mesh_body.anim_speed = 1.5
		mesh_body.anim_amplitude = PI / 6
	
	if dist_from_player <= HIT_RANGE - HIT_RANGE_MARGIN and sees_target:
		mesh_body.legs_playing = 0
	else:
		mesh_body.legs_playing = 1
	
	fb_timer = max(0.0, fb_timer - delta)
	if fb_timer != 0.0:
		var weight = 1 - fb_timer / FB_TIME
		fireball.scale = 0.5 * weight * Vector3.ONE
		fireball.position = lerp(FB_POS[0], FB_POS[1], weight)


func fire():
	var new_rocket = rocket.instantiate()
	new_rocket.death_message = "You were killed by a mage"
	new_rocket.SPEED = ROCKET_SPEED
	new_rocket.set_vel(player.position - position)
	new_rocket.position = FB_POS[1].rotated(Vector3.UP, mesh.rotation.y) + Vector3(0, 1, 0)
	add_child(new_rocket)
	new_rocket.top_level = 1

func _on_respawn_timeout():
	fired = false
	fireball.visible = false
	fb_timer = 0.0
	hit_timer = 0.0
	health = HP
	update_healthbar()
	alive = 1
	target_pos = home.position
	rising = 1
	rising_timer = 0
	alerted.visible = 0

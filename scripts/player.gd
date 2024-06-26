extends CharacterBody3D

@export var spectator : bool = 0

var sens = 5
var fov_min : float = 90
var fov_max : float = 110
var fov_max_spd : float = 2
const SENS_CONSTANT = 0.022
const SPEED = 10
const RADIUS = 0.45
const ACCEL = 90
const TURN_CONTROL = 95
const AIR_TURN_CONTROL = 30
const BRAKE_FACTOR = 1.5
const AIR_BRAKE_FACTOR = 3
const FRICTION = 46
const AIR_FRICTION = 12
const BOOST_LOSS = 8
const AIR_BOOST_LOSS = 6
const AIR_ACCEL = 17
const JUMP_SPEED = 4
const GR_ACCEL = 9.8
const TERMINAL_VEL = 30
const MAX_STEP_HEIGHT = 0.3

const SWAY = 0.0015
const SWAY_MAX = 3
const SWAY_VERICAL = 0.7
const SWAY_RETURN = 6

const REVOLVER_RANGE = 42
const REVOLVER_DAMAGE = 23
const REVOLVER_COOLDOWN = 0.5235
const REVOLVER_COOLDOWN_VARIATION = 0.2
const REVOLVER_MAX_HEAT = 10
const REVOLVER_HEAT_REGEN_TIME = 3
const SHOTGUN_DAMAGE = 100
const SHOTGUN_PB_RANGE = 4
const SHOTGUN_RANGE = 12
const SHOTGUN_FORCE_MIN = 6.0
const SHOTGUN_FORCE_MAX = 9.0
const SHOTGUN_FALLOFF = 0.25
const SHOTGUN_COOLDOWN = 2.1
const SHOTGUN_COOLDOWN_VARIATION = 0.6
const SHOTGUN_MAX_HEAT = 4
const SHOTGUN_HEAT_REGEN_TIME = 10
const CANNONBOMB_FORCE = 15
const CANNONBALL_CHARGE_TIME = 3
const CANNONBOMB_CHARGE_TIME = 6
const BLASTER_DAMAGE = 20
const BLASTER_SELF_DAMAGE_LOW = 1
const BLASTER_SELF_DAMAGE_HIGH = 2
const BLASTER_FORCE = 1.2
const BLASTER_COOLDOWN = 0.15
const BLASTER_COOLDOWN_SHORT = 0.075
const BLASTER_RANGE = 42
const DEATH_FADE_TIME = 1.0
const COYOTE_TIME = 0.2
const WPN_DRAW_TIME = 0.5
var wpn_draw_timer = 0.0
var bobbing = false

var damage_mul = 1.0
var speed_mul = 1.0

const MIN_HIT_DOT_PROD = 0.2

var can_jump = 1

var cooldown_timers = [0, 0, 0, 0]
var mf_lifespans = [0.2, 0.2, 0, 0, 0]

var can_float = 1

var wpn : int = 1
var prev_wpn = 2
var revolver_heat = 0.0
var shotgun_heat = 0.0

var god_mode : bool = false
var max_health : int = 100
var health : int = max_health
var coyote_timer : float = COYOTE_TIME
var time = 0.0

@onready var healthbar = $healthbar/health
@onready var healthbar_width = healthbar.size.x
@onready var health_icon = $healthbar/health_icon_fill
@onready var health_text = $healthbar/health_text
@onready var death_message = $death_screen/death_message
@onready var blood = $blood
@onready var fps_label = $fps_label
var is_opengl = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"

@onready var eye_of_anubis = $eye_of_anubis

@onready var raycast = $cam/camera/raycast
const cannonball_scene = preload("res://scenes/cannonball.tscn")
const cannonbomb_scene = preload("res://scenes/cannonbomb.tscn")
const bullet_scene = preload("res://scenes/bullet.tscn")
const key_texture = preload("res://textures/key.png")
const particles_scene = preload("res://scenes/environment/blood_particles.tscn")

@onready var viewmodel = $cam/camera/vp_cont/vp/gun_cam/viewmodel
@onready var revolver_viewmodel = $cam/camera/vp_cont/vp/gun_cam/viewmodel/revolver_viewmodel
@onready var shotgun_viewmodel = $cam/camera/vp_cont/vp/gun_cam/viewmodel/shotgun_viewmodel
@onready var cannon_viewmodel = $cam/camera/vp_cont/vp/gun_cam/viewmodel/cannon_viewmodel
@onready var blaster_viewmodel = $cam/camera/vp_cont/vp/gun_cam/viewmodel/blaster_viewmodel


@onready var cam = $cam
@onready var camera = $cam/camera
@onready var gun_cam = $cam/camera/vp_cont/vp/gun_cam
@onready var revolver_mf = $cam/camera/vp_cont/vp/gun_cam/viewmodel/revolver_viewmodel/revolver_mf
@onready var shotgun_mf = $cam/camera/vp_cont/vp/gun_cam/viewmodel/shotgun_viewmodel/shotgun_mf
@onready var color_overlay = $color_overlay

@onready var viewmodel_pos = Vector3.ZERO

@onready var enemies = get_tree().get_nodes_in_group("enemy")

@onready var warning = $warning

@export var environment : Environment
@export_file("*.tscn") var respawn_scene
@export var init_health : int = -1


var revolver_mf_timer = 0
var shotgun_mf_timer = 0
var time_after_death = 0
var has_garlic = 0
const KEYS_MAX = 32
var collected_keys : Array[bool] = []
var number_of_keys : int = 0

var config : ConfigFile = ConfigFile.new()
var disable_particles : bool = false

#anim stuff
var revolver_anim_timer = 0.0
@onready var revolver_cylinder = $cam/camera/vp_cont/vp/gun_cam/viewmodel/revolver_viewmodel/revolver_cylinder
var shotgun_anim_timer = 0.0
@onready var left_hand = $cam/camera/vp_cont/vp/gun_cam/viewmodel/shotgun_viewmodel/left_hand
var viewmodel_offset = 0.0
var viewmodel_offset_sign = 1
var viewmodel_y_bump = 0.0
var viewmodel_y_bump_lerped = 0.0


var damage_taken : int = 0

@onready var charge_rect = $charge/charge_rect
var charge_rect_time = 5


func get_garlic():
	has_garlic = 1
	$garlic.visible = 1


func knockback(dir):
	if health > 0:
		velocity += dir


func pain(msg : String, dmg, is_self_dmg = 0, no_tilt = 0, no_blood = 0):
	if health <= 0:
		return
	if not is_self_dmg:
		damage_taken += dmg
	if not no_blood:
		$blood.modulate.a = 1
	if not no_tilt:
		camera.add_tilt(-clamp(dmg, 20, 70) / 2, Vector3(0, 0, 1), 30)
	if not god_mode:
		health -= dmg
		if health <= 0:
			death_message.text = msg


func add_key(col):
	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = key_texture
	sprite.scale = Vector2.ONE * 2
	sprite.position = Vector2(228 + 100 * (number_of_keys % 4), 872 - 50 * (number_of_keys / 4))
	sprite.modulate = col
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	number_of_keys += 1


func update_wpn():
	revolver_viewmodel.visible = 0
	shotgun_viewmodel.visible = 0
	cannon_viewmodel.visible = 0
	blaster_viewmodel.visible = 0
	match wpn:
		1:
			revolver_viewmodel.visible = 1
		2:
			shotgun_viewmodel.visible = 1
		3:
			cannon_viewmodel.visible = 1
		4:
			blaster_viewmodel.visible = 1


func hurt(collider):
	match wpn:
		1:
			collider.pain(REVOLVER_DAMAGE * damage_mul, false, true)
		2:
			var dmg
			var dist = Vector2(position.x, position.z).distance_to(Vector2(collider.position.x, collider.position.z))
			if dist < SHOTGUN_PB_RANGE:
				dmg = SHOTGUN_DAMAGE
			else:
				dmg = min(SHOTGUN_DAMAGE / (SHOTGUN_FALLOFF * (dist - SHOTGUN_PB_RANGE) + 1), SHOTGUN_DAMAGE - 1)
			collider.pain(dmg * damage_mul)
		3:
			pass
		4:
			collider.pain(BLASTER_DAMAGE * damage_mul)


func find_collider(dist, pb_range = 0.0):
	#raycast.target_position = Vector3(0, 0, -dist)
	#raycast.force_raycast_update()
	#var collider = raycast.get_collider()
	#if collider != null and collider.is_in_group("enemy_raycast_collision"):
		#collider = collider.get_parent()
	#print("\nregular collider = " + str(collider))
	
	var dist_left = dist
	var colliders = []
	var forward = raycast.global_basis * Vector3(0, 0, -1)
	var requires_pb_range = false
	while true:
		raycast.target_position = Vector3(0, 0, -dist_left)
		raycast.force_raycast_update()
		#print("step begin: " + str(raycast.global_position) + " " + str(dist_left) + " " + str(raycast.hit_from_inside))
		var collider = raycast.get_collider()
		if collider == null:
			#print("hit nothing")
			break
		if collider.is_in_group("enemy_raycast_collision"):
			collider = collider.get_parent()
		if not collider.is_in_group("enemy"):
			if colliders.is_empty():
				#print("hit wall and stopped")
				raycast.position = Vector3.ZERO
				return collider
			#print("hit wall")
			break
		#print("hit enemy " + str(collider))
		dist_left -= raycast.global_position.distance_to(raycast.get_collision_point()) + 0.1
		raycast.global_position = raycast.get_collision_point() + forward * 0.1
		var dir = collider.position - position
		var dir2d = Vector2(dir.x, dir.z)
		var m = collider.RADIUS * 0.7 / dir2d.length()
		if dir2d.length() < pb_range:
			requires_pb_range = true
		elif requires_pb_range:
			#print("enemy was not in pb dist")
			break
		if dir2d.normalized().dot(Vector2(forward.x, forward.z).normalized()) > 1 / sqrt(m * m + 1):
			#print("enemy was pointed at")
			raycast.position = Vector3.ZERO
			return collider
		colliders.push_back(collider)
	raycast.position = Vector3.ZERO
	if colliders.is_empty():
		#print("no zombies?")
		return null
	else:
		#print(colliders)
		var max_dot = -2
		var max_c
		for c in colliders:
			var dir = c.position - position
			var dot = Vector2(dir.x, dir.z).normalized().dot(Vector2(forward.x, forward.z).normalized())
			if dot > max_dot:
				max_dot = dot
				max_c = c
		return max_c

func shoot():
	match wpn:
		1:
			camera.add_tilt(0.5, Vector3(1, 0, 0), 1)
			var collider = find_collider(REVOLVER_RANGE)
			if collider != null:
				if collider.is_in_group("enemy"):
					if not collider.rising:
						hurt(collider)
				else:
					if collider.is_in_group("physics"):
						collider.apply_impulse((raycast.get_collision_point() - global_position).normalized() * 3.5, raycast.get_collision_point() - collider.center_of_mass - collider.global_position)
					if not disable_particles:
						var new_particles = particles_scene.instantiate()
						new_particles.dir = raycast.get_collision_normal()
						new_particles.color = Color(0.7, 1, 1)
						add_child(new_particles)
						new_particles.global_position = raycast.get_collision_point()
						new_particles.top_level = 1
			
			revolver_heat = min(1.0, revolver_heat + 1.0 / REVOLVER_MAX_HEAT)
			cooldown_timers[0] = REVOLVER_COOLDOWN + lerp(-REVOLVER_COOLDOWN_VARIATION, REVOLVER_COOLDOWN_VARIATION, revolver_heat)
			revolver_mf_timer = mf_lifespans[0]
			
			revolver_anim_timer = REVOLVER_COOLDOWN
			
			var bullet = bullet_scene.instantiate()
			bullet.position = Vector3(0.645, -0.23, -1.111) + viewmodel_pos
			bullet.rotation.y = 0.1
			bullet.rotation.x = 0.04
			bullet.lifespan = 0.08
			gun_cam.add_child(bullet)
		2:
			camera.add_tilt(3, Vector3(1, 0, 0), 3)
			var collider = find_collider(SHOTGUN_RANGE, SHOTGUN_PB_RANGE)
			
			if collider != null:
				if collider.is_in_group("enemy"):
					hurt(collider)
					if not collider.rising:
						var dist = Vector2(position.x, position.z).distance_to(Vector2(collider.position.x, collider.position.z))
						if dist < SHOTGUN_PB_RANGE:
							var dir = cam.transform.basis.z
							knockback(Vector3(dir.x, 0.0, dir.z).normalized() * lerp(SHOTGUN_FORCE_MAX, SHOTGUN_FORCE_MIN, shotgun_heat) + Vector3(0, 2, 0))
							camera.shake(0.4, 0.75, 0.025)
				else:
					if collider.is_in_group("physics"):
						collider.apply_impulse((raycast.get_collision_point() - global_position).normalized() * 5, raycast.get_collision_point() - collider.center_of_mass - collider.global_position)
					if not disable_particles:
						var new_particles = particles_scene.instantiate()
						new_particles.dir = raycast.get_collision_normal()
						new_particles.color = Color(0.7, 1, 1)
						add_child(new_particles)
						new_particles.global_position = raycast.get_collision_point()
						new_particles.top_level = 1
			
			shotgun_heat = min(1.0, shotgun_heat + 1.0 / SHOTGUN_MAX_HEAT)
			var cooldown_var = lerp(-SHOTGUN_COOLDOWN_VARIATION, SHOTGUN_COOLDOWN_VARIATION, shotgun_heat)
			cooldown_timers[1] = SHOTGUN_COOLDOWN + cooldown_var
			shotgun_mf_timer = mf_lifespans[1]
			shotgun_anim_timer = SHOTGUN_COOLDOWN + cooldown_var
			
			const BULLETS = 6
			const SPREAD_RADIUS = 0.035
			for i in range(BULLETS):
				var ang = 2 * PI * i / BULLETS
				var dir_off = Vector3(cos(ang), sin(ang), 0) * SPREAD_RADIUS
				var bullet = bullet_scene.instantiate()
				bullet.position = Vector3(0.645, -0.23, -1.111) + viewmodel_pos
				bullet.rotation.y = 0.1 + dir_off.y
				bullet.rotation.x = 0.04 + dir_off.x
				bullet.lifespan = 0.08
				gun_cam.add_child(bullet)
			
		3:
			camera.add_tilt(1.5, Vector3(1, 0, 0), 3)
			cooldown_timers[2] = CANNONBALL_CHARGE_TIME
			charge_rect_time = CANNONBALL_CHARGE_TIME
			var new_ball = cannonball_scene.instantiate()
			new_ball.dir = -cam.transform.basis.z 
			raycast.target_position = Vector3(0, 0, -1)
			raycast.force_raycast_update()
			var cannonball_pos
			if raycast.is_colliding():
				cannonball_pos = cam.to_local(raycast.get_collision_point()) + Vector3(0, 0, 0.375)
			else:
				cannonball_pos = Vector3(0, 0, -1)
			new_ball.initial_pos = cam.to_global(cannonball_pos)
			new_ball.damage_mul = damage_mul
			cam.add_child(new_ball)
		4:
			camera.add_tilt(0.5, Vector3(1, 0, 0), 2)
			pain("You killed yourself with the blaster", BLASTER_SELF_DAMAGE_LOW, true, true, true)
			var collider = find_collider(BLASTER_RANGE)
			if collider != null:
				if collider.is_in_group("enemy"):
					if not collider.rising:
						hurt(collider)
				else:
					if collider.is_in_group("physics"):
						collider.apply_impulse((raycast.get_collision_point() - global_position).normalized() * 2.5, raycast.get_collision_point() - collider.center_of_mass - collider.global_position)
					if not disable_particles:
						var new_particles = particles_scene.instantiate()
						new_particles.dir = raycast.get_collision_normal()
						new_particles.color = Color(0.7, 1, 1)
						add_child(new_particles)
						new_particles.global_position = raycast.get_collision_point()
						new_particles.top_level = 1
			
			cooldown_timers[3] = BLASTER_COOLDOWN
			
			var bullet = bullet_scene.instantiate()
			bullet.position = Vector3(0.645, -0.23, -1.111) + viewmodel_pos
			bullet.rotation.y = 0.1 + randf_range(-0.01, 0.01)
			bullet.rotation.x = 0.04 + randf_range(-0.01, 0.01)
			bullet.lifespan = 0.08
			gun_cam.add_child(bullet)


func shoot_alt():
	if wpn == 3:
		camera.add_tilt(3, Vector3(1, 0, 0), 4)
		cooldown_timers[2] = CANNONBOMB_CHARGE_TIME
		charge_rect_time = CANNONBOMB_CHARGE_TIME
		var new_bomb = cannonbomb_scene.instantiate()
		raycast.target_position = Vector3(0, 0, -1)
		raycast.force_raycast_update()
		var cannonbomb_pos
		if raycast.is_colliding():
			cannonbomb_pos = cam.to_local(raycast.get_collision_point()) + Vector3(0, 0, 0.3)
		else:
			cannonbomb_pos = Vector3(0, 0, -1)
		new_bomb.position = cannonbomb_pos
		new_bomb.damage_mul = damage_mul
		cam.add_child(new_bomb)
		new_bomb.apply_impulse((-cam.transform.basis.z + Vector3(0, 0.2, 0)) * CANNONBOMB_FORCE)
	elif wpn == 4:
		camera.add_tilt(0.7, Vector3(1, 0, 0), 1.5)
		pain("You killed yourself with the blaster", BLASTER_SELF_DAMAGE_HIGH, true, true, true)
		
		var dir = cam.transform.basis.z.normalized() * BLASTER_FORCE
		dir.y = min(dir.y, 0.25)
		knockback(dir)
		
		var collider = find_collider(BLASTER_RANGE)
		if collider != null:
			if collider.is_in_group("enemy"):
				if not collider.rising:
					hurt(collider)
			else:
				if collider.is_in_group("physics"):
					collider.apply_impulse((raycast.get_collision_point() - global_position).normalized() * 2.5, raycast.get_collision_point() - collider.center_of_mass - collider.global_position)
				if not disable_particles:
					var new_particles = particles_scene.instantiate()
					new_particles.dir = raycast.get_collision_normal()
					new_particles.color = Color(0.7, 1, 1)
					add_child(new_particles)
					new_particles.global_position = raycast.get_collision_point()
					new_particles.top_level = 1
		
		cooldown_timers[3] = BLASTER_COOLDOWN_SHORT
			
		var bullet = bullet_scene.instantiate()
		bullet.position = Vector3(0.645, -0.23, -1.111) + viewmodel_pos
		bullet.rotation.y = 0.1 + randf_range(-0.01, 0.01)
		bullet.rotation.x = 0.04 + randf_range(-0.01, 0.01)
		bullet.lifespan = 0.08
		gun_cam.add_child(bullet)


func movement(wishdir, delta):
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider == null:
			continue
		if collider.is_in_group("lightweight"):
			if col.get_angle() <= PI / 4:
				collider.pain(100)
				velocity.y += JUMP_SPEED
				break
	
	if spectator:
		position += SPEED * 5 * Vector3(wishdir.x, 0, wishdir.y) * delta
		if Input.is_action_pressed("g_attack"):
			position.y -= SPEED * delta
		if Input.is_action_pressed("g_attack2"):
			position.y += SPEED * delta
		return
	
	var incr
	if can_jump:
		if is_on_floor():
			if Input.is_action_pressed("g_jump"):
				velocity.y = JUMP_SPEED
				viewmodel_y_bump = 1.0
		elif Input.is_action_just_pressed("g_jump"):
			if coyote_timer == 0.0:
				can_jump = 0
			velocity.y = max(velocity.y, JUMP_SPEED)
			viewmodel_y_bump = 1.0
			if wishdir != Vector2.ZERO:
				var vel_length = Vector2(velocity.x, velocity.z).length()
				velocity.x = wishdir.x * vel_length
				velocity.z = wishdir.y * vel_length
	
	if is_on_floor():
		can_jump = 1
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
	var moving_on_floor = is_on_floor() and (not can_jump or not Input.is_action_pressed("g_jump"))
	
	if Vector2(velocity.x, velocity.z).length() > SPEED * speed_mul:
		var boost_loss
		if moving_on_floor:
			boost_loss = BOOST_LOSS
		else:
			boost_loss = AIR_BOOST_LOSS
		velocity -= Vector3(velocity.x, 0, velocity.z).normalized() * boost_loss * delta
	
	var friction
	if moving_on_floor:
		friction = FRICTION * speed_mul
		incr = ACCEL * delta * speed_mul
	else:
		friction = AIR_FRICTION * speed_mul
		velocity.y = max(-TERMINAL_VEL, velocity.y - GR_ACCEL * delta)
		incr = AIR_ACCEL * delta * speed_mul
	if wishdir == Vector2.ZERO:
		if Vector2(velocity.x, velocity.z).length() >= friction * delta:
			velocity -= Vector3(velocity.x, 0, velocity.z).normalized() * friction * delta
		else:
			velocity = Vector3(0, velocity.y, 0)
	
	var vel2d = Vector2(velocity.x, velocity.z)
	if vel2d.length() == 0:
		vel2d += wishdir * incr
	else:
		var wdt = wishdir.project(vel2d)
		var wdn = wishdir.project(Vector2(-vel2d.y, vel2d.x))
		if wdt.x * vel2d.x > 0 or wdt.y * vel2d.y > 0:
			if vel2d.length() <= SPEED * speed_mul - wdt.length() * incr:
				vel2d += wdt * incr
			elif vel2d.length() < SPEED * speed_mul:
				vel2d = vel2d.normalized() * SPEED * speed_mul
		else:
			if vel2d.length() >= wdt.length() * incr:
				var brake_factor
				if is_on_floor():
					brake_factor = BRAKE_FACTOR
				else:
					brake_factor = AIR_BRAKE_FACTOR
				vel2d += wdt * incr * brake_factor
			else:
				vel2d = Vector2.ZERO
		var turn_control
		if is_on_floor():
			turn_control = TURN_CONTROL * speed_mul
		else:
			turn_control = AIR_TURN_CONTROL * speed_mul
		vel2d = Vector2(vel2d + wdn * turn_control * delta).normalized() * vel2d.length()
	
	velocity = Vector3(vel2d.x, velocity.y, vel2d.y)
	
	var prev_vel = velocity
	move_and_slide()
	
	#now check to see if the player can climb up a step
	if not moving_on_floor:
		return
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if is_equal_approx(col.get_angle(), PI / 2):
			raycast.global_position = -col.get_normal() * (RADIUS + 0.1) + global_position + Vector3(0, MAX_STEP_HEIGHT, 0)
			raycast.target_position = raycast.to_local(raycast.global_position + Vector3(0, -MAX_STEP_HEIGHT, 0))
			raycast.force_raycast_update()
			if raycast.is_colliding() and raycast.get_collision_normal().dot(Vector3.UP) > 0.9:
				global_position.y = raycast.get_collision_point().y
				velocity = Vector3(prev_vel.x, velocity.y, prev_vel.z)
			raycast.position = Vector3.ZERO
			return


func _ready():
	if environment != null:
		camera.environment = environment
	
	if spectator:
		viewmodel.visible = 0
		$crosshair.visible = 0
		$healthbar.visible = 0
		$fps_label.visible = 0
		for e in enemies:
			e.queue_free()
	
	config.load("user://settings.cfg")
	sens = config.get_value("controls", "sensitivity", 5.0)
	fov_min = config.get_value("video", "fov", 90)
	if config.get_value("video", "dynamic_fov", true):
		fov_max = fov_min * 110.0 / 90.0
	else:
		fov_max = fov_min
	camera.fov = fov_min
	god_mode = config.get_value("gameplay", "god_mode", false)
	
	
	health = max_health
	if init_health > 0:
		health = init_health
	
	disable_particles = config.get_value("video", "disable_particles", false)
	if config.get_value("video", "disable_shake", false):
		camera.disable_shake = 1
	
	var respawn_event = InputMap.action_get_events("g_respawn")[0]
	var respawn_event_text
	if respawn_event is InputEventKey:
		respawn_event_text = respawn_event.as_text_keycode()
	elif respawn_event is InputEventMouseButton:
		respawn_event_text = respawn_event.as_text()
	else:
		respawn_event_text = "UNKNOWN"
	$death_screen/respawn_guide.text = "press " + respawn_event_text + " to try again"
	
	collected_keys.resize(KEYS_MAX)
	for i in range(KEYS_MAX):
		collected_keys[i] = 0
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Input.use_accumulated_input = false
	raycast.add_exception(self)
	cam.top_level = 1
	cam.rotation.y = rotation.y
	rotation.y = 0
	
	if is_opengl:
		revolver_viewmodel.material_override = preload("res://resources/materials/level_mat.tres").duplicate()
		shotgun_viewmodel.material_override = preload("res://resources/materials/level_mat.tres").duplicate()
		cannon_viewmodel.material_override = preload("res://resources/materials/level_mat.tres").duplicate()
		blaster_viewmodel.material_override = preload("res://resources/materials/level_mat.tres").duplicate()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var r = event.relative * sens * SENS_CONSTANT
		viewmodel_pos += Vector3(clamp(-r.x, -SWAY_MAX, SWAY_MAX) * SWAY, clamp(r.y, -SWAY_MAX, SWAY_MAX) * SWAY * SWAY_VERICAL, 0);
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x - r.y, -90, 90)
		cam.rotation_degrees.y = cam.rotation_degrees.y - r.x
	elif event.is_action_pressed("g_switch"):
		var aux = prev_wpn
		prev_wpn = wpn
		wpn = aux
		wpn_draw_timer = WPN_DRAW_TIME
		update_wpn()
	elif event.is_action_pressed("g_wpn1") and wpn != 1:
		prev_wpn = wpn
		wpn = 1
		wpn_draw_timer = WPN_DRAW_TIME
		update_wpn()
	elif event.is_action_pressed("g_wpn2") and wpn != 2:
		prev_wpn = wpn
		wpn = 2
		wpn_draw_timer = WPN_DRAW_TIME
		update_wpn()
	elif event.is_action_pressed("g_wpn3") and wpn != 3:
		prev_wpn = wpn
		wpn = 3
		wpn_draw_timer = WPN_DRAW_TIME
		update_wpn()
	elif event.is_action_pressed("g_wpn4") and wpn != 4:
		prev_wpn = wpn
		wpn = 4
		wpn_draw_timer = WPN_DRAW_TIME
		update_wpn()
	elif event.is_action_pressed("g_next"):
		prev_wpn = wpn
		wpn += 1
		if wpn > 4:
			wpn = 1
		wpn_draw_timer = WPN_DRAW_TIME
		update_wpn()
	elif event.is_action_pressed("g_prev"):
		prev_wpn = wpn
		wpn -= 1
		if wpn <= 0:
			wpn = 4
		wpn_draw_timer = WPN_DRAW_TIME
		update_wpn()


func _process(delta):
	if is_opengl:
		revolver_viewmodel.material_override.albedo_color = Color(1, 1 - revolver_heat * 0.2, 1 - revolver_heat * 0.2)
		shotgun_viewmodel.material_override.albedo_color = Color(1, 1 - shotgun_heat * 0.4, 1 - shotgun_heat * 0.4)
	else:
		revolver_viewmodel.set_instance_shader_parameter("pain", revolver_heat * 0.2)
		shotgun_viewmodel.set_instance_shader_parameter("pain", shotgun_heat * 0.2)
	
	revolver_anim_timer = max(0, revolver_anim_timer - delta)
	revolver_cylinder.rotation.z = revolver_anim_timer * PI / (4 * REVOLVER_COOLDOWN)
	shotgun_anim_timer = max(0, shotgun_anim_timer - delta)
	var shotgun_anim_frac = 1 - shotgun_anim_timer / SHOTGUN_COOLDOWN
	const ANIM_PARAM1 = 0.2
	const ANIM_PARAM2 = 0.4
	const ANIM_PARAM3 = -0.8
	if shotgun_anim_frac > ANIM_PARAM1:
		if shotgun_anim_frac < ANIM_PARAM1 + ANIM_PARAM2:
			left_hand.position.z = (shotgun_anim_frac - ANIM_PARAM1) * ANIM_PARAM3 / ANIM_PARAM2
		elif shotgun_anim_frac < ANIM_PARAM1 + 2 * ANIM_PARAM2:
			left_hand.position.z = (ANIM_PARAM1 + 2 * ANIM_PARAM2 - shotgun_anim_frac) * ANIM_PARAM3 / ANIM_PARAM2
		else:
			left_hand.position.z = 0
	else:
		left_hand.position.z = 0
	
	
	warning.modulate.a -= delta
	fps_label.text = str(Engine.get_frames_per_second())
	blood.modulate.a = max(0, blood.modulate.a - delta)
	
	eye_of_anubis.modulate.a = max(0, eye_of_anubis.modulate.a - delta)
	
	health = clamp(health, 0, max_health)
	healthbar.size.x = healthbar_width * (health / float(max_health))
	var health_col = Color(1 - (health / float(max_health)), (health / float(max_health)), 0, 1)
	healthbar.color = health_col
	health_icon.modulate = health_col
	health_text.text = str(health)
	
	charge_rect.scale.y = 1 - cooldown_timers[2] / charge_rect_time
	
	if health <= 0:
		health = -1000
		if Input.is_action_just_pressed("g_respawn"):
			if respawn_scene == null:
				get_tree().reload_current_scene()
			else:
				get_tree().change_scene_to_file(respawn_scene)
		$death_screen.visible = 1
		$death_screen.modulate.a = min(1, time_after_death / DEATH_FADE_TIME)
		time_after_death += delta
		return
	
	var fov = lerp(fov_min, fov_max,
			 clamp((Vector2(velocity.x, velocity.z).length() - SPEED * speed_mul) / (SPEED * speed_mul * (fov_max_spd - 1)), 0, 1))
	camera.fov = lerp(camera.fov, fov, delta * 15)
	
	revolver_mf_timer = max(0, revolver_mf_timer - delta)
	shotgun_mf_timer = max(0, shotgun_mf_timer - delta)
	revolver_mf.visible = (revolver_mf_timer != 0 and wpn_draw_timer < 0.2)
	shotgun_mf.visible = (shotgun_mf_timer != 0 and wpn_draw_timer < 0.2)
	
	color_overlay.color.a -= delta
	
	viewmodel_pos.x -= viewmodel_pos.x * delta * SWAY_RETURN
	viewmodel_pos.y -= viewmodel_pos.y * delta * SWAY_RETURN
	
	if abs(viewmodel_offset) > 0.1 or bobbing:
		var mul = 1.0
		if not bobbing:
			mul = min(1.0, abs(viewmodel_offset))
			if viewmodel_offset * viewmodel_offset_sign > 0:
				viewmodel_offset_sign = -viewmodel_offset_sign
		viewmodel_offset += delta * viewmodel_offset_sign * 4 * mul * speed_mul
	if viewmodel_offset > 1 or viewmodel_offset < -1:
		viewmodel_offset_sign = -viewmodel_offset_sign
	viewmodel_y_bump_lerped = lerp(viewmodel_y_bump_lerped, viewmodel_y_bump * 1.5, min(delta * 15, 0.1))
	if viewmodel_y_bump > 0.0:
		viewmodel_y_bump -= delta * 3
	
	wpn_draw_timer = max(0.0, wpn_draw_timer - delta)
	viewmodel.position = viewmodel_pos + 0.05 * Vector3(cos(viewmodel_offset + PI / 2), 1 - sin(viewmodel_offset + PI / 2) - viewmodel_y_bump_lerped, 0) + Vector3(0, -1.5, 0) * pow(wpn_draw_timer / WPN_DRAW_TIME, 3)
	
	time += delta


func viewmodel_rot_func(t, dt, g):
	return (dt - t) * g * t / 2


func _physics_process(delta):
	if health <= 0:
		return
	
	for i in range(4):
		cooldown_timers[i] = max(0, cooldown_timers[i] - delta)
	
	if wpn_draw_timer < 0.2 and cooldown_timers[wpn - 1] == 0:
		if Input.is_action_pressed("g_attack"):
			shoot()
		elif Input.is_action_pressed("g_attack2"):
			shoot_alt()
	
	gun_cam.position = position
	gun_cam.rotation = cam.global_rotation
	gun_cam.rotation.x = clamp(gun_cam.rotation.x, -PI / 3, PI / 3)
	
	var wishdir = Input.get_vector("g_left", "g_right", "g_forward", "g_backward").rotated(-cam.rotation.y)
	bobbing = is_on_floor() and velocity.length_squared() > 0.1 and wishdir != Vector2.ZERO
	
	var prev_y_vel = velocity.y
	var prev_on_floor = is_on_floor()
	movement(wishdir, delta)
	if not prev_on_floor and is_on_floor() and prev_y_vel < -20:
		camera.shake(0.4, 0.75, 0.025)
	
	cam.position = global_position + Vector3(0, 1.2, 0)
	
	if cooldown_timers[0] <= 0.01:
		revolver_heat = max(0, revolver_heat - delta / REVOLVER_HEAT_REGEN_TIME)
	if cooldown_timers[1] <= 0.01:
		shotgun_heat = max(0, shotgun_heat - delta / SHOTGUN_HEAT_REGEN_TIME)

extends CharacterBody3D

@export var spectator : bool = 0

var sens = 5
var fov_min : float = 90
var fov_max : float = 110
var fov_max_spd : float = 2
const SENS_CONSTANT = 0.022
const SPEED = 10
const RADIUS = 0.475
const ACCEL = 90
const TURN_CONTROL = 95
const AIR_TURN_CONTROL = 30
const BRAKE_FACTOR = 1.5
const AIR_BRAKE_FACTOR = 3
const FRICTION = 36
const AIR_FRICTION = 12
const BOOST_LOSS = 8
const AIR_BOOST_LOSS = 6
const AIR_ACCEL = 17
const JUMP_SPEED = 4
const GR_ACCEL = 9.8
const TERMINAL_VEL = 30

const SWAY = 0.002
const SWAY_MAX = 2
const SWAY_VERICAL = 0.7
const SWAY_RETURN = 3
const HOLSTER_SPEED = 8

const REVOLVER_RANGE = 42
const REVOLVER_DAMAGE = 23
const REVOLVER_COOLDOWN = 0.4235
const SHOTGUN_DAMAGE = 100
const SHOTGUN_PB_RANGE = 4
const SHOTGUN_RANGE = 20
const SHOTGUN_FORCE = 8
const SHOTGUN_FALLOFF = 0.25
const SHOTGUN_COOLDOWN = 1.8
const CANNONBOMB_FORCE = 15
const CANNONBALL_CHARGE_TIME = 3
const CANNONBOMB_CHARGE_TIME = 5
const BLASTER_DAMAGE = 20
const BLASTER_SELF_DAMAGE_LOW = 1
const BLASTER_SELF_DAMAGE_HIGH = 2
const BLASTER_FORCE = 1.2
const BLASTER_COOLDOWN_LONG = 0.175
const BLASTER_COOLDOWN_SHORT = 0.075
const BLASTER_RANGE = 30
const BLASTER_PB_RANGE = 4
const BLASTER_FALLOFF = 0.1
const DEATH_FADE_TIME = 1.0

const MIN_HIT_DOT_PROD = 0.2

var can_jump = 1

var holstering = 0
var cooldown_timers = [0, 0, 0, 0]
var mf_lifespans = [0.2, 0.2, 0, 0]

var can_float = 1

var wpn : int = 1
var prev_wpn = 2
var wpn_vis = wpn

var god_mode : bool = false
var max_health : int = 100
var health : int = max_health

@onready var healthbar = $healthbar/health
@onready var healthbar_width = healthbar.size.x
@onready var health_icon = $healthbar/health_icon_fill
@onready var health_text = $healthbar/health_text
@onready var blood = $blood
@onready var fps_label = $fps_label

@onready var eye_of_anubis = $eye_of_anubis

@onready var raycast = $cam/camera/raycast
var cannonball_scene = preload("res://scenes/cannonball.tscn")
var cannonbomb_scene = preload("res://scenes/cannonbomb.tscn")
var bullet_scene = preload("res://scenes/bullet.tscn")
var key_texture = preload("res://textures/key.png")
var particles_scene = preload("res://scenes/environment/blood_particles.tscn")

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

@onready var viewmodel_pos = Vector3.ZERO
@onready var viewmodel_rot = Vector3.ZERO

@onready var enemies = get_tree().get_nodes_in_group("enemy")

@onready var warning = $warning

@export var environment : Environment
@export_file("*.tscn") var respawn_scene


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


var time = 0
var damage_taken : int = 0

@onready var charge_rect = $charge/charge_rect
var charge_rect_time = 5

var is_opengl


func get_garlic():
	has_garlic = 1
	$garlic.visible = 1


func knockback(dir):
	if health > 0:
		velocity += dir


func pain(dmg, is_self_dmg = 0, no_tilt = 0, no_blood = 0):
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
	wpn_vis = wpn
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
			collider.pain(REVOLVER_DAMAGE)
		2:
			var dmg
			var dist = Vector2(position.x, position.z).distance_to(Vector2(collider.position.x, collider.position.z))
			if dist < SHOTGUN_PB_RANGE:
				dmg = SHOTGUN_DAMAGE
			else:
				dmg = min(SHOTGUN_DAMAGE / (SHOTGUN_FALLOFF * (dist - SHOTGUN_PB_RANGE) + 1), SHOTGUN_DAMAGE - 1)
			collider.pain(dmg)
		3:
			pass
		4:
			var dmg
			var dist = Vector2(global_position.x, global_position.z).distance_to(Vector2(collider.global_position.x, global_position.z))
			if dist < BLASTER_PB_RANGE:
				dmg = BLASTER_DAMAGE
			else:
				dmg = BLASTER_DAMAGE / (BLASTER_FALLOFF * (dist - BLASTER_PB_RANGE) + 1)
			collider.pain(dmg)


func shoot():
	match wpn:
		1:
			camera.add_tilt(0.5, Vector3(1, 0, 0), 1)
			raycast.target_position = Vector3(0, 0, -REVOLVER_RANGE)
			raycast.force_raycast_update()
			var collider = raycast.get_collider()
			if collider != null:
				if collider.is_in_group("enemy_raycast_collision"):
					collider = collider.get_parent()
					if not collider.rising:
						hurt(collider)
				elif not disable_particles:
					var new_particles = particles_scene.instantiate()
					new_particles.dir = raycast.get_collision_normal()
					new_particles.color = Color(0.7, 1, 1)
					add_child(new_particles)
					new_particles.global_position = raycast.get_collision_point()
					new_particles.top_level = 1
			
			cooldown_timers[0] = REVOLVER_COOLDOWN
			revolver_mf_timer = mf_lifespans[0]
			
			revolver_anim_timer = REVOLVER_COOLDOWN
			
			var bullet = bullet_scene.instantiate()
			bullet.position = Vector3(0.645, -0.23, -1.111) + viewmodel_pos
			bullet.rotation.y = 0.1
			bullet.rotation.x = 0.04
			gun_cam.add_child(bullet)
		2:
			camera.add_tilt(3, Vector3(1, 0, 0), 3)
			raycast.target_position = Vector3(0, 0, -SHOTGUN_RANGE)
			raycast.force_raycast_update()
			var collider = raycast.get_collider()
			
			if collider != null:
				if collider.is_in_group("enemy_raycast_collision"):
					collider = collider.get_parent()
					hurt(collider)
					if not collider.rising:
						var dist = Vector2(position.x, position.z).distance_to(Vector2(collider.position.x, collider.position.z))
						if dist < SHOTGUN_PB_RANGE:
							var dir = cam.transform.basis.z
							knockback(Vector3(dir.x, 0.0, dir.z).normalized() * SHOTGUN_FORCE + Vector3(0, 2, 0))
							camera.shake(0.4, 0.75, 0.025)
				elif not disable_particles:
					var new_particles = particles_scene.instantiate()
					new_particles.dir = raycast.get_collision_normal()
					new_particles.color = Color(0.7, 1, 1)
					add_child(new_particles)
					new_particles.global_position = raycast.get_collision_point()
					new_particles.top_level = 1
			
			cooldown_timers[1] = SHOTGUN_COOLDOWN
			shotgun_mf_timer = mf_lifespans[1]
			shotgun_anim_timer = SHOTGUN_COOLDOWN
			
			const BULLETS = 6
			const SPREAD_RADIUS = 0.05
			for i in range(BULLETS):
				var ang = 2 * PI * i / BULLETS
				var dir_off = Vector3(cos(ang), sin(ang), 0) * SPREAD_RADIUS
				var bullet = bullet_scene.instantiate()
				bullet.position = Vector3(0.65, -0.227, -1.348) + viewmodel_pos
				gun_cam.add_child(bullet)
				bullet.rotate(Vector3.FORWARD.cross(Vector3.FORWARD + dir_off).normalized(), Vector3.FORWARD.angle_to(Vector3.FORWARD + dir_off))
			
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
			cam.add_child(new_ball)
		4:
			camera.add_tilt(0.5, Vector3(1, 0, 0), 2)
			pain(BLASTER_SELF_DAMAGE_LOW, true, true, true)
			raycast.target_position = Vector3(0, 0, -BLASTER_RANGE)
			raycast.force_raycast_update()
			var collider = raycast.get_collider()
			if collider != null:
				if collider.is_in_group("enemy_raycast_collision"):
					collider = collider.get_parent()
					if not collider.rising:
						hurt(collider)
				elif not disable_particles:
					var new_particles = particles_scene.instantiate()
					new_particles.dir = raycast.get_collision_normal()
					new_particles.color = Color(0.7, 1, 1)
					add_child(new_particles)
					new_particles.global_position = raycast.get_collision_point()
			
			cooldown_timers[3] = BLASTER_COOLDOWN_LONG
			
			var bullet = bullet_scene.instantiate()
			bullet.position = Vector3(0.645, -0.23, -1.111) + viewmodel_pos
			bullet.rotation.y = 0.1 + randf_range(-0.035, 0.035)
			bullet.rotation.x = 0.04 + randf_range(-0.035, 0.035)
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
		cam.add_child(new_bomb)
		new_bomb.apply_impulse((-cam.transform.basis.z + Vector3(0, 0.2, 0)) * CANNONBOMB_FORCE)
	elif wpn == 4:
		camera.add_tilt(0.7, Vector3(1, 0, 0), 1.5)
		pain(BLASTER_SELF_DAMAGE_HIGH, true, true, true)
		
		var dir = cam.transform.basis.z.normalized() * BLASTER_FORCE
		dir.y = min(dir.y, 0.25)
		knockback(dir)
		
		raycast.target_position = Vector3(0, 0, -BLASTER_RANGE)
		raycast.force_raycast_update()
		var collider = raycast.get_collider()
		if collider != null:
			if collider.is_in_group("enemy_raycast_collision"):
				collider = collider.get_parent()
				if not collider.rising:
					hurt(collider)
			elif not disable_particles:
				var new_particles = particles_scene.instantiate()
				new_particles.dir = raycast.get_collision_normal()
				new_particles.color = Color(0.7, 1, 1)
				add_child(new_particles)
				new_particles.global_position = raycast.get_collision_point()
				new_particles.top_level = 1
		
		cooldown_timers[3] = BLASTER_COOLDOWN_SHORT
			
		var bullet = bullet_scene.instantiate()
		bullet.position = Vector3(0.645, -0.23, -1.111) + viewmodel_pos
		bullet.rotation.y = 0.1 + randf_range(-0.035, 0.035)
		bullet.rotation.x = 0.04 + randf_range(-0.035, 0.035)
		gun_cam.add_child(bullet)


func movement(wishdir, delta):
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
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
		elif Input.is_action_just_pressed("g_jump"):
			can_jump = 0
			velocity.y = max(velocity.y, JUMP_SPEED)
			if wishdir != Vector2.ZERO:
				var vel_length = Vector2(velocity.x, velocity.z).length()
				velocity.x = wishdir.x * vel_length
				velocity.z = wishdir.y * vel_length
	
	if is_on_floor():
		can_jump = 1
	var moving_on_floor = is_on_floor() and (not can_jump or not Input.is_action_pressed("g_jump"))
	
	if Vector2(velocity.x, velocity.z).length() > SPEED:
		var boost_loss
		if moving_on_floor:
			boost_loss = BOOST_LOSS
		else:
			boost_loss = AIR_BOOST_LOSS
		velocity -= Vector3(velocity.x, 0, velocity.z).normalized() * boost_loss * delta
	
	var friction
	if moving_on_floor:
		friction = FRICTION
		incr = ACCEL * delta
	else:
		friction = AIR_FRICTION
		velocity.y = max(-TERMINAL_VEL, velocity.y - GR_ACCEL * delta)
		incr = AIR_ACCEL * delta
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
			if vel2d.length() <= SPEED - wdt.length() * incr:
				vel2d += wdt * incr
			elif vel2d.length() < SPEED:
				vel2d = vel2d.normalized() * SPEED
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
			turn_control = TURN_CONTROL
		else:
			turn_control = AIR_TURN_CONTROL
		vel2d = Vector2(vel2d + wdn * turn_control * delta).normalized() * vel2d.length()
	
	velocity = Vector3(vel2d.x, velocity.y, vel2d.y)
	
	move_and_slide()


func _ready():
	is_opengl = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"
	if is_opengl:
		$cam/camera/vp_cont.visible = 0
	else:
		$cam/camera/opengl_viewmodels.queue_free()
	
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
	for i in get_tree().get_nodes_in_group("wallbang"):
		raycast.add_exception(i)
	cam.top_level = 1
	cam.rotation.y = rotation.y
	rotation.y = 0


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
		holstering = 1
	elif event.is_action_pressed("g_wpn1") and wpn != 1:
		prev_wpn = wpn
		wpn = 1
		holstering = 1
	elif event.is_action_pressed("g_wpn2") and wpn != 2:
		prev_wpn = wpn
		wpn = 2
		holstering = 1
	elif event.is_action_pressed("g_wpn3") and wpn != 3:
		prev_wpn = wpn
		wpn = 3
		holstering = 1
	elif event.is_action_pressed("g_wpn4") and wpn != 4:
		prev_wpn = wpn
		wpn = 4
		holstering = 1
	elif event.is_action_pressed("g_next"):
		prev_wpn = wpn
		wpn += 1
		if wpn > 4:
			wpn = 1
		holstering = 1
	elif event.is_action_pressed("g_prev"):
		prev_wpn = wpn
		wpn -= 1
		if wpn <= 0:
			wpn = 4
		holstering = 1


func _process(delta):
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
			 clamp((Vector2(velocity.x, velocity.z).length() - SPEED) / (SPEED * (fov_max_spd - 1)), 0, 1))
	camera.fov = lerp(camera.fov, fov, delta * 15)
	if not holstering and cooldown_timers[wpn - 1] == 0:
		if Input.is_action_pressed("g_attack"):
			shoot()
		elif Input.is_action_pressed("g_attack2"):
			shoot_alt()
	
	revolver_mf_timer = max(0, revolver_mf_timer - delta)
	shotgun_mf_timer = max(0, shotgun_mf_timer - delta)
	revolver_mf.visible = (revolver_mf_timer != 0 and not holstering)
	shotgun_mf.visible = (shotgun_mf_timer != 0 and not holstering)
	if is_opengl:
		$cam/camera/opengl_viewmodels/revolver_viewmodel.visible = (wpn == 1)
		$cam/camera/opengl_viewmodels/shotgun_viewmodel.visible = (wpn == 2)
		$cam/camera/opengl_viewmodels/cannon_viewmodel.visible = (wpn == 3)
		$cam/camera/opengl_viewmodels/blaster_viewmodel.visible = (wpn == 4)


func viewmodel_rot_func(t, dt, g):
	return (dt - t) * g * t / 2


func _physics_process(delta):
	time += delta
	
	viewmodel_pos.x -= viewmodel_pos.x * delta * SWAY_RETURN
	viewmodel_pos.y -= viewmodel_pos.y * delta * SWAY_RETURN
	
	for i in range(4):
		cooldown_timers[i] = max(0, cooldown_timers[i] - delta)

	if holstering:
		viewmodel_pos.y -= HOLSTER_SPEED * delta
		if viewmodel_pos.y < -1.2:
			holstering = 0
			update_wpn()
	
	viewmodel.position = viewmodel_pos
	viewmodel.rotation = viewmodel_rot
	
	gun_cam.position = position
	gun_cam.rotation = cam.global_rotation
	gun_cam.rotation.x = clamp(gun_cam.rotation.x, -PI / 3, PI / 3)
	
	if health <= 0:
		return
	var wishdir = Vector2.ZERO
	if Input.is_action_pressed("g_forward"):
		wishdir += Vector2(0, -1)
	if Input.is_action_pressed("g_left"):
		wishdir += Vector2(-1, 0)
	if Input.is_action_pressed("g_backward"):
		wishdir += Vector2(0, 1)
	if Input.is_action_pressed("g_right"):
		wishdir += Vector2(1, 0)
	wishdir = wishdir.normalized().rotated(-cam.rotation.y)
	
	movement(wishdir, delta)
	cam.position = global_position + Vector3(0, 1.2, 0)

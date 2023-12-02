extends Camera3D

const FALLOFF_EXP = 2

var time : float = 0.5
var amplitude : float = 0.65
var wavelength : float = 0.025
const ANGLES = [0, 150, 330, 210, 30, 180]
const NR_ANGLES = 6
var i = 0
var timer = -1.0
var change_timer = 0.0
var first_ang : bool = 1

var disable_shake = 0

class Tilt:
	var tilt_time : float
	var max_ang : float
	var tilt_timer : float
	var tilt_axis : Vector3 = Vector3(0, 0, 1)
	func _init(ang : float, axis : Vector3, speed : float):
		tilt_time = abs(ang) / speed
		tilt_timer = tilt_time
		max_ang = deg_to_rad(ang)
		tilt_axis = axis
var tilts : Array[Tilt] = []

func shake(atime : float, aamplitude : float, awavelength : float):
	time = atime
	amplitude = aamplitude
	wavelength = awavelength
	timer = time
	first_ang = 1


func tilt_func(x):
	if x < 0.125:
		return 8 * x
	return -0.68 + 1 / (x + 0.47)
 

func add_tilt(ang : float, axis : Vector3, speed : float):
	var tilt : Tilt = Tilt.new(ang, axis, speed)
	tilts.push_back(tilt)

func _process(delta):
	if disable_shake:
		return
	var j = 0
	while j < tilts.size():
		var tilt : Tilt = tilts[j]
		if tilt.tilt_timer <= 0.0:
			tilts.remove_at(j)
		else:
			j = j + 1
			tilt.tilt_timer -= delta
	
	rotation = Vector3.ZERO
	for t in tilts:
		var ang = tilt_func(1 - t.tilt_timer / t.tilt_time) * t.max_ang
		rotation += t.tilt_axis * ang
	rotation.x = clamp(rotation.x, -PI/4, PI/4)
	rotation.y = clamp(rotation.y, -PI/4, PI/4)
	rotation.z = clamp(rotation.z, -PI/4, PI/4)
	
	if timer <= 0.0:
		position = Vector3.ZERO
	else:
		change_timer += delta
		if change_timer > wavelength:
			i = (i + 1) % NR_ANGLES
			change_timer = 0.0
			first_ang = 0
		var frac_amplitude = pow((timer / time) * amplitude, FALLOFF_EXP)
		
		var prev_pos_x = 0.0
		var prev_pos_y = 0.0
		if not first_ang:
			var prev_ang = deg_to_rad(ANGLES[posmod(i - 1, NR_ANGLES)])
			prev_pos_x = cos(prev_ang) * frac_amplitude
			prev_pos_y = sin(prev_ang) * frac_amplitude
		var lerp_frac = change_timer / wavelength
		position.x = lerp(prev_pos_x, cos(deg_to_rad(ANGLES[i])) * frac_amplitude, lerp_frac)
		position.y = lerp(prev_pos_y, sin(deg_to_rad(ANGLES[i])) * frac_amplitude, lerp_frac)
		timer -= delta

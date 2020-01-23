extends Node2D

class_name Weapon

export var hit_animation_scene : PackedScene
export var bullet_trail_scene : PackedScene
export var capsule_scene : PackedScene
export var fire_point_path : NodePath
export var capsule_ejector_path : NodePath
export var fire_sound_path : NodePath
export var empty_bullets_sound_path : NodePath
export var reload_sound_path : NodePath
export var parent_node : NodePath

export (int, "Automatic", "SemiAutomatic", "Missile") var gun_type
export (float, 0, 1) var spread_rate
export (float, 0, 5) var recoil_time
export (int, 1, 1000) var max_bullets
export (float, 0, 10) var reload_time
export var eject_capsule : bool

var can_fire : bool = true
var reloading : bool = false
var bullets : int
var raycast : RayCast2D
var recoil_timer : Timer
var reload_timer : Timer
var fire_point : Position2D
var capsule_ejector : Position2D
var fire_sound : AudioStreamPlayer2D
var reload_sound : AudioStreamPlayer2D
var empty_bullets_sound : AudioStreamPlayer2D

signal shoot
signal reloading
signal reloaded
signal hit_enemy
signal no_bullets
signal ready_to_fire
signal update_bullets(how_many)


func _ready():
	bullets = max_bullets
	fire_point = get_node(fire_point_path)
	fire_sound = get_node(fire_sound_path)
	if eject_capsule:
		capsule_ejector = get_node(capsule_ejector_path)
	empty_bullets_sound = get_node(empty_bullets_sound_path)
	reload_sound = get_node(reload_sound_path)
	recoil_timer = create_timer(recoil_time, "on_recoil_time_end")
	reload_timer = create_timer(reload_time, "on_reload_time_end")
	create_raycast()
	adjust_raycast_size()

func _process(delta):
	if gun_type == 0: # Automatic
		# Fire
		if can_fire and Input.is_action_pressed("fire"):
			if bullets > 0:
				shoot()
			else:
				empty_bullets()
		# Reload
		if Input.is_action_just_pressed("reload") and not reloading:
			reload_start()
			
	elif gun_type == 1: # Semi automatic
		# Fire
		if can_fire and Input.is_action_just_pressed("fire"):
			if bullets > 0:
				shoot()
			else:
				empty_bullets()
		# Reload
		if Input.is_action_just_pressed("reload") and not reloading:
			reload_start()

	elif gun_type == 2: # Missile
		if Input.is_action_just_pressed("fire"):
				if can_fire and bullets > 0:
					pass

func create_raycast() -> void:
	raycast = RayCast2D.new()
	raycast.position = fire_point.position
	raycast.rotation_degrees = -90
	raycast.enabled = true
	add_child(raycast)

func adjust_raycast_size() -> void:
	var size_screen : Vector2 = get_viewport().get_visible_rect().size
	raycast.set_cast_to(Vector2(0, size_screen.x))
	
func spread_bullet() -> void:
	# 22.5 degrees it's half of 45. 45 It's the max spread allowed.
	var spread_angle : float = 22.5 * spread_rate
	# Reset raycast angle before each fire.
	raycast.rotation_degrees = -90
	raycast.rotation_degrees += rand_range(-spread_angle, spread_angle)

func create_timer(time : float,  callback : String) -> Timer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	timer.connect("timeout", self, callback)
	add_child(timer)
	return timer

func shoot() -> void:
	fire_sound.play()
	emit_signal("shoot")
	emit_signal("update_bullets", bullets)
	bullets -= 1
	can_fire = false
	recoil_timer.start()
	spread_bullet()
	if eject_capsule:
		eject_capsule()
	var hit_something = raycast.get_collider()
	if hit_something:
		var collision_point = raycast.get_collision_point()
		var collide_with = raycast.get_collider()
		var collider_groups = collide_with.get_groups()
		create_trail(raycast.get_global_position(), collision_point)
		if "enemy" in collider_groups:
			emit_signal("hit_enemy")
		create_hit_animation(collision_point)

func reload_start() -> void:
	reloading = true
	can_fire = false
	reload_timer.start()
	reload_sound.play()
	emit_signal("reloading")

func empty_bullets() -> void:
	empty_bullets_sound.play()
	emit_signal("no_bullets")

func create_trail(to : Vector2, from : Vector2) -> void:
	var trail = bullet_trail_scene.instance()
	trail.setup(to, from)
	get_node(parent_node).get_owner().add_child(trail)

func create_hit_animation(collision_point : Vector2) -> void:
	var hit_animation = hit_animation_scene.instance()
	hit_animation.global_position = collision_point
	hit_animation.rotation_degrees = rand_range(0, 360)
	get_node(parent_node).get_owner().add_child(hit_animation)

func on_recoil_time_end() -> void:
	can_fire = true
	emit_signal("ready_to_fire")
	
func on_reload_time_end() -> void:
	reloading = false
	bullets = max_bullets
	can_fire = true
	emit_signal("reloaded")
	emit_signal("update_bullets", bullets)

func eject_capsule() -> void:
	var capsule = capsule_scene.instance()
	# Variável que auxilia a correção do ângulo caso o
	# braço esteja com a escala invertida
	var looking_to_right = get_parent().get_parent().scale.y
	capsule.global_position = capsule_ejector.global_position
	capsule.rotation = capsule_ejector.global_rotation * looking_to_right
	# Aplicar impulso e rotação na capsula, sempre usando o
	# 'looking_to_right' para corrigir a inversão de scale
	capsule.apply_impulse(Vector2(0,0), Vector2(-100 * looking_to_right,-200))
	capsule.add_torque(-500 * looking_to_right)
	get_node(parent_node).get_owner().add_child(capsule)
	
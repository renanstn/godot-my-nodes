extends KinematicBody2D

class_name BasicMovement2D

"""
This script provides a basic player movement,
with editable values, and options to sprint and fly.
It also emits signals for each action.

Copy this script to your project, and a new node
'BasicMovement2D' will appear in godot's list, as a
KinematicBody2D's child.

Requirements:
	The following inputs need to be created:
	- 'left'
	- 'right'
	- 'sprint'
	- 'jump'

Credits: Renan Santana Desiderio
https://github.com/Doc-McCoy
"""

const UP : Vector2 = Vector2(0, -1)

export (int, 0, 100) var GRAVITY  = 20
export (float, 0, 1000) var JUMP_FORCE = 500
export (float, 0, 500) var WALK_SPEED : int = 200
export (float, 0, 30) var ACCELERATION = 10
export (float, 0, 1) var DEACELERATION = 0.1
export (float, 0, 1) var AIR_DEACELERATION = 0.02
export (float, 0, 500) var SPRINT_SPEED : int = 200
export (float, 0, 500) var MAX_THRUST = 300
export (float, 0, 50) var THRUST_POWER = 30

export (bool) var CAN_WALK = true
export (bool) var CAN_SPRINT = true
export (bool) var CAN_JUMP = true
export (bool) var CAN_FLY = false

var motion : Vector2 = Vector2()
var max_speed : float = WALK_SPEED
var looking_to_right : bool

signal is_walking
signal is_jumping
signal is_falling
signal is_sprinting
signal is_on_ground
signal is_thrusting
signal player_flipped

# ========================================================================
func _physics_process(delta):

	motion.y += GRAVITY
	motion = transform_inputs_in_motion()
	motion = move_and_slide(motion, UP)
	emit_signals(motion)
	
func transform_inputs_in_motion() -> Vector2:

	var friction : bool = false

	# Sprint (increase max speed)
	if CAN_SPRINT and Input.is_action_pressed("sprint"):
		max_speed = WALK_SPEED + SPRINT_SPEED
	elif max_speed > WALK_SPEED and is_on_floor():
		# Gradually reduce max_speed to walk_speed
		max_speed = lerp(max_speed, 0, DEACELERATION)
		max_speed = max(max_speed, WALK_SPEED)
		pass

	# Accelerate / Deacelerate
	if CAN_WALK:
		if Input.is_action_pressed("right"):
			motion.x = min(motion.x + ACCELERATION, max_speed)
		elif Input.is_action_pressed("left"):
			motion.x = max(motion.x - ACCELERATION, -max_speed)
		else:
			friction = true

	if is_on_floor():
		# Jump
		if CAN_JUMP and Input.is_action_just_pressed("jump"):
			motion.y = -JUMP_FORCE
		# Deaceleration
		if friction:
			motion.x = lerp(motion.x, 0, DEACELERATION)
	else:
		# In air deaceleration
		motion.x = lerp(motion.x, 0, AIR_DEACELERATION)

	if CAN_FLY and Input.is_action_pressed("jump"):
		motion.y -= THRUST_POWER
		motion.y = clamp(motion.y, -MAX_THRUST, 1000)

	return motion


func emit_signals(motion : Vector2):

	if is_on_floor() and motion.x != 0:
		emit_signal("is_on_ground")
		if abs(motion.x) <= WALK_SPEED:
			emit_signal("is_walking")
		else:
			emit_signal("is_sprinting")

	if motion.x < 0 and looking_to_right:
		emit_signal("player_flipped")
		looking_to_right = false
	if motion.x > 0 and not looking_to_right:
		looking_to_right = true
		emit_signal("player_flipped")

	if motion.y < 0:
		if CAN_FLY:
			emit_signal("is_thrusting")
		else:
			emit_signal("is_jumping")
	elif motion.y > 0:
		emit_signal("is_falling")

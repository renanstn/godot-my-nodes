extends Node2D

class_name ArmPointingToMouse2D

"""
This script provides a node that is always
looking at the mouse pointer.

Copy this script to your project, and a new node
'ArmPointingToMouse2D' will appear in godot's list,
 as a Node2D's child.

Credits: Renan Santana Desiderio
https://github.com/Doc-McCoy
"""

export var FIX_ROTATION : bool = true

func _process(delta):
	look_to_mouse()
	if FIX_ROTATION:
		fix_rotation()


func look_to_mouse() -> void:
	look_at(get_global_mouse_position())


func fix_rotation():
	if global_position.x < get_global_mouse_position().x:
		set_scale(Vector2(1, 1))
	else:
		set_scale(Vector2(1, -1))

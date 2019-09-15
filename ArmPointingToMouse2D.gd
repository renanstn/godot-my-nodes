extends Node2D

class_name ArmPointingToMouse2D

export var FIX_ROTATION : bool

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

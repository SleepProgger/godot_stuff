extends TextureButton

# TODO: setget
export(Texture) var hover_texture
export(float) var blend_time = 2
var _change_speed
var _cur_value

func _ready():
	set_material( get_material().duplicate() )
	get_material().set_shader_param("Tex", hover_texture)
	get_material().set_shader_param("Blend", 0)
	connect("mouse_enter", self, "_on_mouse_enter")
	connect("mouse_exit", self, "_on_mouse_exit")
	_cur_value = 0
	
func _process(delta):
	_cur_value += delta * _change_speed
	if _cur_value <= 0:
		_cur_value = 0
		set_process(false)
	elif _cur_value >= 1:
		_cur_value = 1
		set_process(false)
	get_material().set_shader_param("Blend", _cur_value)

func _on_mouse_enter():
	_change_speed = 1.0/blend_time
	set_process(true)

func _on_mouse_exit():
	_change_speed = -(1.0/blend_time)
	set_process(true)
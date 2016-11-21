tool
extends CanvasLayer

class StatisticEntry:
	var name
	var function
	var static_label
	var label
	var format
	func _init(_name, _function, _format="%s"):
		name = _name
		function = _function
		label = Label.new()
		static_label = Label.new()
		static_label.set_text(name)
		format = _format
		
# Acts as a alternative to return variables from objects
# Use like a FuncRef
class _Get_wrapper:
	var _object
	var _variable
	func _init(object, variable):
		_object = object
		_variable = variable
	func call_func():
		return _object.get(_variable)
		
		
func _get_physic2d_object_count():
	return Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
func _get_physic3d_object_count():
	return Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
func _get_object_count():
	return Performance.get_monitor(Performance.OBJECT_COUNT)
func _get_node_count():
	return Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		

export var interval = 1.0 setget set_interval
export var running = true

export var grid_margin = Vector2(2,2) setget set_grid_margin
# TODO: fix this. We want to expose gridcontainer margin and _container margin i guess
#export var margin = Rect2(2,2,2,2) setget set_margin

export var show_fps = false setget set_show_fps
export var show_objects = false setget set_show_object_count
export var show_nodes = false setget set_show_node_count
export var show_physic2d_nodes = false setget set_show_physics2d_count
export var show_physic3d_nodes = false setget set_show_physics3d_count
export(Color) var background_color = Color("#c8545dbc") setget set_background_color
var _panel
var _grid
var _panel_style = null
var stat_entries = null
var _delta = 0

# Default stats
var _stats_fps = null
var _stats_objects = null
var _stats_nodes = null
var _stats_physics2d = null
var _stats_physics3d = null

func _ready():
	stat_entries = []
	_panel = PanelContainer.new()
	_panel_style = StyleBoxFlat.new()
	_panel_style.set_bg_color(background_color)
	_panel.set('custom_styles/panel', _panel_style)
	add_child(_panel)
	_grid = GridContainer.new()
	_grid.set_columns(2)
	_panel.add_child(_grid)
	# Default stats
	_stats_fps = _generate_stats("FPS:", OS, "get_frames_per_second")
	if show_fps:
		add_stats_entry(_stats_fps)
	_stats_objects = _generate_stats("Objects:", self, "_get_object_count")
	if show_objects:
		add_stats_entry(_stats_objects)
	_stats_nodes = _generate_stats("Nodes:", self, "_get_node_count")
	if show_nodes:
		add_stats_entry(_stats_nodes)
	_stats_physics2d = _generate_stats("2D Physic Nodes:", self, "_get_physic2d_object_count")
	if show_physic2d_nodes:
		add_stats_entry(_stats_physics2d)
	_stats_physics3d = _generate_stats("3D Physic Nodes:", self, "_get_physic3d_object_count")
	if show_physic3d_nodes:
		add_stats_entry(_stats_physics3d)
	#set_margin(margin)
	set_grid_margin(grid_margin)
	set_process(true)
	

func _set_stats_status(entry, status):
	if stat_entries == null: return false
	if stat_entries.has(entry) == status:
		return false
	if status:
		add_stats_entry(entry)
	else:
		stat_entries.erase(entry)	
	relayout()
	return true
func set_show_fps(status):
	_set_stats_status(_stats_fps, status)
	show_fps = status
func set_show_object_count(status):
	_set_stats_status(_stats_objects, status)
	show_objects = status
func set_show_node_count(status):
	_set_stats_status(_stats_nodes, status)
	show_nodes = status
func set_show_physics2d_count(status):
	_set_stats_status(_stats_physics2d, status)
	show_physic2d_nodes = status
func set_show_physics3d_count(status):
	_set_stats_status(_stats_physics3d, status)
	show_physic3d_nodes = status
		
func set_background_color(color):
	background_color = color
	if _panel_style != null:
		_panel_style.set_bg_color(color)
		_panel.update()
		
func set_interval(_interval):
	interval = _interval
	_delta = _interval
	
# NOT USED ATM
# TODO: fix and use
func set_margin(rect):
	if _grid != null:
		_grid.set_margin(MARGIN_LEFT, rect.pos.x)
		_grid.set_margin(MARGIN_RIGHT, rect.size.x)
		_grid.update()
	#margin = rect

func set_grid_margin(vector):
	if _grid != null:
		_grid.set("custom_constants/hseparation", vector.x)
		_grid.set("custom_constants/vseparation", vector.y)
		_grid.update()
	grid_margin = vector
	
func _resize_container(container):
	for child in container.get_children():
		if child extends Container:
			_resize_container(child)
	container.set_size(container.get_minimum_size())
func relayout():
	# Dirty, but good enough i guess
	for child in _grid.get_children():
		_grid.remove_child(child)
	for stat in stat_entries:
		_grid.add_child(stat.static_label)
		_grid.add_child(stat.label)
	_resize_container(_panel)
	
func _generate_stats(name, _class, function, format="%s"):
	if _class.has_method(function):
		function = funcref(_class, function)
	else:
		function = _Get_wrapper.new(_class, function)
	var stat_entry = StatisticEntry.new(name, function, format)
	return stat_entry
	
func add_stats(name, _class, function, format="%s", position=-1):
	var stat_entry = _generate_stats(name, _class, function, format)
	add_stats_entry(stat_entry, position)
	return stat_entry
	
func add_stats_entry(entry, position=-1):
	if position == -1 or position >= stat_entries.size():
		_grid.add_child(entry.static_label)
		_grid.add_child(entry.label)
		stat_entries.append(entry)
		return
	stat_entries.insert(position, entry)
	relayout()


func _process(delta):
	if ! running or stat_entries == null:
		_delta = 0
		return
	_delta += delta
	if _delta >= interval:
		for entry in stat_entries:
			entry.label.set_text(entry.format % entry.function.call_func())
		_delta -= interval # TODO: what happens with pause mode ? Set to min(_delta, interval) ?
		
		
		
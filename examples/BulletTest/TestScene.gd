extends Container

# GUI
onready var _txt_interval = get_node("PanelContainer/VBoxContainer/HBoxContainer2/txt_interval")
onready var _slider_interval = get_node("PanelContainer/VBoxContainer/HBoxContainer2/slider_interval")
onready var _txt_tower = get_node("PanelContainer/VBoxContainer/HBoxContainer3/txt_tower")
onready var _slider_tower = get_node("PanelContainer/VBoxContainer/HBoxContainer3/slider_tower")
onready var _txt_speed = get_node("PanelContainer/VBoxContainer/HBoxContainer4/txt_speed")
onready var _slider_speed = get_node("PanelContainer/VBoxContainer/HBoxContainer4/slider_speed")
onready var _run_btn = get_node("PanelContainer/VBoxContainer/HBoxContainer/btn_start")

# Internal
onready var _viewport = get_node("Container/Viewport")
onready var _stats_view = get_node("StatsOverlay")


onready var _spawners = [
	["Rigid bullet", _viewport.SPAWNER_RIGID],
	["Area bullet", _viewport.SPAWNER_AREA],
	["Kinematic bullet", _viewport.SPAWNER_KINEMATIC],
	["Bullet manager", _viewport.SPAWNER_MANAGER]
]

func _ready():
	# init stat stuff	
	_stats_view.add_stats("Bullets:", _viewport, "_bullet_count", "%s", 0)
	if type_exists("BulletManager"):
		_spawners.append(["Bullet manager c++", _viewport.SPAWNER_MANAGER_NATIVE])
	
	# Init gui stuff
	var option_box = get_node("PanelContainer/VBoxContainer/OptionButton")
	for spawner in _spawners:
		option_box.add_item(spawner[0])
		option_box.add_separator()
	option_box.connect("item_selected", self, "_bullet_type_selected")
	
	_slider_interval.connect("value_changed", self, "_slider_interval_changed")
	_txt_interval.connect("value_changed", self, "_txt_interval_changed")
	_slider_tower.connect("value_changed", self, "_slider_tower_changed")
	_txt_tower.connect("value_changed", self, "_txt_tower_changed")
	_slider_speed.connect("value_changed", self, "_slider_speed_changed")
	_txt_speed.connect("value_changed", self, "_txt_speed_changed")
	_run_btn.connect("button_down", self, "_btn_run_down")
	get_node("PanelContainer/VBoxContainer/HBoxContainer/btn_clear").connect("button_down", self, "_btn_clear")
	
	_txt_tower_changed(_txt_tower.get_value())
	_txt_interval_changed(_txt_interval.get_value())
	_txt_speed_changed(_txt_speed.get_value())
	_bullet_type_selected(0)
	
#
# GUI callbacks
#
func _slider_interval_changed(to):
	_viewport.interval = to
	_txt_interval.set_value(to)
func _txt_interval_changed(to):
	_viewport.interval = to
	_slider_interval.set_value(to)
func _slider_tower_changed(to):
	_txt_tower.set_value(to)
	_viewport.tower_count = to 
func _txt_tower_changed(to):
	_slider_tower.set_value(to)
	_viewport.tower_count = to 
func _slider_speed_changed(to):
	_txt_speed.set_value(to)
	_viewport.bullet_speed = to 
func _txt_speed_changed(to):
	_slider_speed.set_value(to)
	_viewport.bullet_speed = to 
	
func _bullet_type_selected(id):
	_viewport.set_bullet_type(_spawners[id / 2][1])
	
func _btn_run_down():
	if _viewport.toogle_run():
		_run_btn.set_text("STOP")
	else:
		_run_btn.set_text("START")
	
func _btn_clear():
	print("foo")

extends Viewport

export(Texture) var tower_sprite 
export var interval = 1.0 setget set_spawn_interval
export var tower_count = 100 setget set_tower_count
export var bullet_speed = 1.0
export var running = false

var spawner = null
var towers
var _bullet_layer
var _bullet_count = 0

onready var _consumer = get_node("Area2D")
onready var _bullet_manager = get_node("BulletManager")
var _manager_bullet # the bullet type for the manager

#
# Spawner
#

# Simple rigid body without friction and gravity.
onready var _bullet_scene_rigid = load("res://Bullet_rigid.tscn")
func _spawn_bullet_rigid(position, velocity):
	var bullet = _bullet_scene_rigid.instance()
	_bullet_layer.add_child(bullet)
	bullet.set_pos(position)
	bullet.set_rot(velocity.angle() + PI)
	bullet.set_linear_velocity(velocity)
var SPAWNER_RIGID = funcref(self, "_spawn_bullet_rigid")

# Area2D bullet moved in gdscript. Similar to a kinematic body.
onready var _bullet_scene_area = load("res://Bullet_area.tscn")
func _spawn_bullet_area(position, velocity):
	var bullet = _bullet_scene_area.instance()
	_bullet_layer.add_child(bullet)
	bullet.set_pos_(position)
	bullet.set_rot(velocity.angle() + PI)
	bullet.set_linear_velocity(velocity)
var SPAWNER_AREA = funcref(self, "_spawn_bullet_area")

# Basically the same as the Area2D bullet but with a KinematicBody
# instead of an Area2D. Performs worse.
onready var _bullet_scene_kinematic = load("res://Bullet_kinematic.tscn")
func _spawn_bullet_kinematic(position, velocity):
	var bullet = _bullet_scene_kinematic.instance()
	_bullet_layer.add_child(bullet)
	bullet.set_pos_(position)
	bullet.set_rot(velocity.angle() + PI)
	bullet.set_linear_velocity(velocity)
var SPAWNER_KINEMATIC = funcref(self, "_spawn_bullet_kinematic")

# Use our bullet manager to spawn bullets.
# Similar to the "shower of bullets" demo.
func _spawn_bullet_from_manager(position, velocity):
	_bullet_manager.spawn_bullet(_manager_bullet, position, velocity, velocity.angle() + PI )
var SPAWNER_MANAGER = funcref(self, "_spawn_bullet_from_manager")



func _init():
	# Umm wtf ? If i put this in _ready
	# it crashes as _process runs before _ready ???
	towers = []

func _ready():
	_manager_bullet = _bullet_manager.create_bullet_type_from_node(_bullet_scene_area.instance())
	_bullet_layer = Node2D.new()
	add_child(_bullet_layer)
	connect("size_changed", self, "_size_changed")
	_consumer.connect("body_enter_shape", self, "_consumer_body_shape_enter")
	_consumer.connect("area_enter_shape", self, "_consumer_area_shape_enter")
	_size_changed()
	set_process(true)
	
func start():
	running = true
func stop():
	running = false
func toogle_run():
	running = ! running
	return running

func set_spawn_interval(spawn_interval):
	interval = spawn_interval / 1000.0
	
func set_tower_count(amount):
	if amount < 1:
		return
	for tower in towers:
		remove_child(tower)
		tower.free()
	towers.clear()
	# a rect would make more sense but i wan'T my elipse
	var size = get_rect().size - (tower_sprite.get_size() / 2)
	var center = (size / 2) + (tower_sprite.get_size()/4)
	size = size / 2
	for i in range(0, 360, int(360 / amount)):
		var sprite = Sprite.new()
		sprite.set_texture(tower_sprite)
		sprite.set_pos(Vector2(size.width * cos(i) + center.x, size.height * sin(i) + center.y))
		add_child(sprite)
		towers.append(sprite)
	
func set_bullet_type(_spawner):
	spawner =_spawner
	
	
func _consumer_body_shape_enter(body_id, body, body_shape, area_shape):
	if body != null:
		#_bullet_layer.remove_child(body)
		body.queue_free()
		_bullet_count -= 1
	else: # bullet managers
		_bullet_manager.remove_bullet(body_id)
		_bullet_count -= 1
		
func _consumer_area_shape_enter(area_id, area, area_shape, self_shape):
	if area != null:
		#_bullet_layer.remove_child(area)
		area.queue_free()
		_bullet_count -= 1
	
	
func _size_changed():
	# we need to clean the bullets to ensure they are removed.
	# TODO: maybe add self destruct distance to bullets
	for child in _bullet_layer.get_children():
		if child.is_inside_tree():
			#_bullet_layer.remove_child(child)
			child.queue_free()
		else:
			# Should be good ?
			print("CHILD ALREADY REMOVED")
	_bullet_manager.clean_bullets()
	_bullet_count = 0
	set_tower_count(towers.size())
	_consumer.set_pos( (get_rect().size/2) - (_consumer.get_item_rect().size/4.0) )


var delta = 0
func _process(_delta):
	if spawner == null or ! running:
		return
	delta += _delta
	if delta < interval:
		return
	var center = _consumer.get_pos()
	for tower in towers:
		spawner.call_func(tower.get_pos(), (center - tower.get_pos()).normalized() * bullet_speed)
		_bullet_count += 1
	delta = 0

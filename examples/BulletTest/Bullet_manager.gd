extends Node2D

#
# This class is similar to the "shower of bullet" demo
# In my experience it is sometimes faster as rigid body bullets.
# TBH: not sure when atm ;)
#

#
# Thoughts:
#  - Using a bullet cache should increase the performance a bit.
#    Instead of deleting the bullet set it to sleep and move to bullet_cache.
#  - If the rotation of the bullet is not relevant: removing of draw_set_transform_matrix
#    in _draw increase the draw performance a bit.
#

var bullets = []
var _objectid2bullet = {}
var _bullet_count = 0

class BulletType:
	var shape
	var texture
	var _half_size
	# TODO: do we want the speed here or set it per bullet ?

class Bullet extends Object:
	var state = null
	var velocity = Vector2()
	var body = null
	var texture = null
	var _half_size = null
	var _kill_me = false

func create_bullet_type(shape, texture):
	var b_type = BulletType.new()
	b_type.shape = shape
	b_type.texture = texture
	b_type._half_size = texture.get_size()/2
	return b_type
	
# Converts a CollisionObject2D (or anything with a get_shape function)
# containing a sprite to a bullet type.
# Only the first shape and texture found is used.
# Translations are ignored (TODO ?)
func create_bullet_type_from_node(node):
	if not node.has_method('get_shape'):
		return false
	for child in node.get_children():
		if child extends Sprite:
			return create_bullet_type(node.get_shape(0), child.get_texture())
			
		
	
func spawn_bullet(b_type, position, velocity, rot=0):
	var bullet = Bullet.new()
	bullet.texture = b_type.texture
	bullet._half_size = b_type._half_size
	bullet.velocity = velocity
	bullet.body = Physics2DServer.body_create(Physics2DServer.BODY_MODE_KINEMATIC)
	Physics2DServer.body_set_space(bullet.body, get_world_2d().get_space())
	Physics2DServer.body_add_shape(bullet.body, b_type.shape)
	Physics2DServer.body_attach_object_instance_ID(bullet.body, bullet.get_instance_ID())	
	Physics2DServer.body_set_shape_as_trigger(bullet.body, 0, true) # Does this make sense performance wise ?
	bullet.state = Matrix32().rotated( rot )
	bullet.state.o = position
	Physics2DServer.body_set_state(bullet.body, Physics2DServer.BODY_STATE_TRANSFORM, bullet.state)
	# Save the bullet
	_objectid2bullet[bullet.get_instance_ID()] = bullet
	bullets.append(bullet)
	return bullet
	

func _draw():
	for b in bullets:
		draw_set_transform_matrix(b.state)
		draw_texture(b.texture, -b._half_size)
		#draw_texture(b.texture, b.state[2] - b._half_size)

func _process(delta):
	var tmp = []
	for b in bullets:
		if b._kill_me:
			_bullet_count -= 1
			Physics2DServer.free_rid(b.body)
			b.free()
			continue
		b.state[2] += b.velocity * delta
		Physics2DServer.body_set_state(b.body, Physics2DServer.BODY_STATE_TRANSFORM, b.state)
		tmp.append(b)
	# A linked list would be awesome.
	# Recreating lists every tick can't be performant
	bullets = tmp
	update()

func remove_bullet(instance_id):
	if ! instance_id in _objectid2bullet:
		return
	var bullet = _objectid2bullet[instance_id]
	_objectid2bullet.erase(instance_id)
	bullet._kill_me = true
	
func clean_bullets():
	for bullet in bullets:
		_objectid2bullet.erase(bullet.get_instance_ID())
		bullet._kill_me = true

func _ready():
	#set_fixed_process(true)
	set_process(true)


func _exit_tree():
	# TODO: !!!
	pass

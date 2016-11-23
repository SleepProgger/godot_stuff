extends KinematicBody2D

# TODO: should we directly use the physics2d server to update position ?

export var velocity = Vector2(0,0)
var position

func _ready():
	position = get_pos()
	set_fixed_process(true)
	
func set_pos_(pos):
	position = pos
	set_pos(pos)
	

func set_linear_velocity(vector):
	velocity = vector
	
func _fixed_process(delta):
	# Should we use move here ?
	# We don't need the collision check here tho
	position += velocity * delta
	set_pos(position)
	#move(velocity * delta)
	
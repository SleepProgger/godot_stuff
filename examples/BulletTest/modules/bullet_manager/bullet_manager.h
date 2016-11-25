#ifndef BULLET_MANAGER_H
#define BULLET_MANAGER_H

#include "reference.h"
#include "scene/2d/node_2d.h"
#include "scene/resources/texture.h"
#include "scene/resources/shape_2d.h"
#include "core/list.h"
#include "core/map.h"

class BulletType : public Object {
	OBJ_TYPE(BulletType, Object);
public:
	const Ref<Shape2D> shape;
	const Ref<Texture> texture;
	Vector2 _half_size;
	BulletType(const Ref<Shape2D>& p_shape, const Ref<Texture>& p_texture) : shape(p_shape), texture(p_texture){
		_half_size = p_texture->get_size() / 2;
	}
};


class Bullet : public Object {
	OBJ_TYPE(Bullet, Object);
public:
	Matrix32 state;
	Vector2 velocity;
	RID body;
	BulletType *type;
	bool _kill_me;
	// TODO: constructor
};



class BulletManager : public Node2D {
    OBJ_TYPE(BulletManager,Node2D);

protected:
    List<Bullet*> bullets;
    static void _bind_methods();
    void _notification(int p_what);

    void _draw();
    void _step();

public:
    BulletManager();
    BulletType* create_bullet_type(const Ref<Shape2D>& p_shape, const Ref<Texture>& p_texture);
    void spawn_bullet(Object *p_type, Vector2 position, Vector2 velocity, float rotation);
    bool remove_bullet(ObjectID instance_id);
    void clean_bullets();
    // TODO destructor
};



#endif

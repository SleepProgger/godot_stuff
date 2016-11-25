#include "bullet_manager.h"
#include "core/os/os.h"
#include "servers/physics_2d_server.h"


void BulletManager::_bind_methods() {
	ObjectTypeDB::bind_method(_MD("create_bullet_type","shape", "texture:Texture"),&BulletManager::create_bullet_type);
	ObjectTypeDB::bind_method(_MD("spawn_bullet","bullet_type:BulletType", "position", "rotation"),&BulletManager::spawn_bullet);
	ObjectTypeDB::bind_method(_MD("remove_bullet","instance_id"),&BulletManager::remove_bullet);
	ObjectTypeDB::bind_method(_MD("clean_bullets"),&BulletManager::clean_bullets);
}

BulletManager::BulletManager() {
}

BulletType* BulletManager::create_bullet_type(const Ref<Shape2D>& p_shape, const Ref<Texture>& p_texture){
	BulletType *type = memnew(BulletType(p_shape, p_texture));
	return type;
}
void BulletManager::spawn_bullet(Object *p_type, Vector2 position, Vector2 velocity, float rotation){
	BulletType *bullet_type = p_type->cast_to<BulletType>();
	Bullet *bullet = memnew(Bullet());
	bullet->_kill_me = false;
	bullet->velocity.x = velocity.x;
	bullet->velocity.y = velocity.y;
	bullet->type = bullet_type;
	bullet->state.rotate(rotation);
	bullet->state.elements[2] = position;
	Physics2DServer *ph_server = Physics2DServer::get_singleton();
	bullet->body = ph_server->body_create(Physics2DServer::BODY_MODE_KINEMATIC, false);
	// TODO: only get space once. Also this crashes when BulletManager not in tree
	ph_server->body_set_space(bullet->body, get_world_2d()->get_space());
	ph_server->body_set_state(bullet->body, Physics2DServer::BODY_STATE_TRANSFORM, bullet->state);
	ph_server->body_add_shape(bullet->body, bullet_type->shape->get_rid());
	ph_server->body_attach_object_instance_ID(bullet->body, bullet->get_instance_ID());
	// we never want bullets to collide with themself or detect collisions at all.
	ph_server->body_set_max_contacts_reported(bullet->body, 0);
	// TODO: make configurable
	ph_server->body_set_layer_mask(bullet->body, 1);
	ph_server->body_set_collision_mask(bullet->body, 2);
	bullets.push_back(bullet);
}

bool BulletManager::remove_bullet(ObjectID instance_id){
	Bullet *bullet = ObjectDB::get_instance(instance_id)->cast_to<Bullet>();
	if(bullet == NULL){
		return false;
	}
	bullet->_kill_me = true;
	return true;
}

void BulletManager::_draw(){
	Matrix32 pos;
	for(List<Bullet*>::Element *E=bullets.front();E;E=E->next()) {
		draw_set_transform_matrix(E->get()->state);
		draw_texture(E->get()->type->texture, -E->get()->type->_half_size);
	}
}

void BulletManager::_step(){
	float delta = get_process_delta_time();
	Bullet *bullet;
	Physics2DServer *ph_server = Physics2DServer::get_singleton();
	List<Bullet*>::Element *E = bullets.front();
	List<Bullet*>::Element *next_elem;
	while(E){
		bullet = E->get();
		if(bullet->_kill_me){
			next_elem = E->next();
			ph_server->free(bullet->body);
			memdelete(bullet);
			E->erase();
			E = next_elem;
			continue;
		}
		bullet->state[2] += bullet->velocity * delta;
		ph_server->body_set_state(bullet->body, Physics2DServer::BODY_STATE_TRANSFORM, bullet->state);
		E = E->next();
	}
	// TODO: do we need to do this or can we just draw here ?
	// or is there some faster way to trigger draw`?
	update();
}

void BulletManager::clean_bullets(){
	// TODO: we should lock this i guess, but for now... meeh
	Physics2DServer *ph_server = Physics2DServer::get_singleton();
	Bullet *bullet;
	List<Bullet*>::Element *E = bullets.front();
	List<Bullet*>::Element *next_elem;
	while(E){
		bullet = E->get();
		next_elem = E->next();
		ph_server->free(bullet->body);
		memdelete(bullet);
		E->erase();
		E = next_elem;
	}
}

void BulletManager::_notification(int p_what) {
	switch(p_what) {
		case NOTIFICATION_PROCESS: {
			_step();
		} break;
		case NOTIFICATION_DRAW: {
			_draw();
		} break;
	}
}

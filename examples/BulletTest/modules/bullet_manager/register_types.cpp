/*
 * register_types.cpp
 *
 *  Created on: Nov 23, 2016
 *      Author: nope
 */




#include "register_types.h"
#include "object_type_db.h"
#include "bullet_manager.h"

void register_bullet_manager_types() {
	ObjectTypeDB::register_type<BulletManager>();
	ObjectTypeDB::register_virtual_type<BulletType>();
}

void unregister_bullet_manager_types() {
   //nothing to do here
}

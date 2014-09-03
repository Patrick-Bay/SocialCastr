/* 
	Copyright 2010 OpenRTMFP
 
	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License received along this program for more
	details (or else see http://www.gnu.org/licenses/).

	This file is a part of Cumulus.
*/

#pragma once

#include "Cumulus.h"
#include "string.h"
#include <map>

namespace Cumulus {

template<class EntityType>
class Entities {
public:
	struct Compare {
	   bool operator()(const Poco::UInt8* a,const Poco::UInt8* b) const {
		   return memcmp(a,b,ID_SIZE)<0;
	   }
	};

	typedef typename std::map<const Poco::UInt8*,EntityType*,Compare> Map;
	typedef typename Map::const_iterator Iterator;

	Entities(Map& entities) : _entities(entities) {}
	~Entities(){}


	Iterator		begin() {
		return _entities.begin();
	}

	Iterator end() {
		return _entities.end();
	}

	Poco::UInt32 count() {
		return _entities.size();
	}

	EntityType* operator()(const Poco::UInt8* id) {
		Iterator it = _entities.find(id);
		if(it==_entities.end())
			return NULL;
		return it->second;
	}
private:
	Map&	_entities;
};




} // namespace Cumulus

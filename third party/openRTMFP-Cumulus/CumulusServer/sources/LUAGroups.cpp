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

#include "LUAGroups.h"
#include "Invoker.h"
#include "LUAGroup.h"
#include "Util.h"
#include "Poco/HexBinaryDecoder.h"

using namespace Cumulus;
using namespace Poco;
using namespace std;

const char*		LUAGroups::Name="Cumulus::Entities<Group>";


int LUAGroups::Pairs(lua_State* pState) {
	SCRIPT_CALLBACK(Entities<Group>,LUAGroups,groups)
		lua_getglobal(pState,"next");
		if(!lua_iscfunction(pState,-1))
			SCRIPT_ERROR("'next' should be a LUA function, it should not be overloaded")
		else {
			lua_newtable(pState);
			Entities<Group>::Iterator it;
			for(it=groups.begin();it!=groups.end();++it) {
				SCRIPT_WRITE_PERSISTENT_OBJECT(Group,LUAGroup,*it->second)
				lua_setfield(pState,-2,Cumulus::Util::FormatHex(it->second->id,ID_SIZE).c_str());
			}
		}
	SCRIPT_CALLBACK_RETURN
}


int LUAGroups::Get(lua_State *pState) {
	SCRIPT_CALLBACK(Entities<Group>,LUAGroups,groups)
		SCRIPT_READ_STRING(name,"")
		if(name=="pairs")
			SCRIPT_WRITE_FUNCTION(&LUAGroups::Pairs)
		else if(name=="count")
			SCRIPT_WRITE_NUMBER(groups.count())
		else if(name=="(") {
			SCRIPT_READ_STRING(id,"")
			Group* pGroup = NULL;
			if(id.size()==ID_SIZE)
				pGroup = groups((const UInt8*)id.c_str());
			else if(id.size()==(ID_SIZE*2)) {
				istringstream iss(id);
				UInt8 groupId[ID_SIZE];
				HexBinaryDecoder(iss).read((char*)groupId,ID_SIZE);
				pGroup = groups(groupId);
			} else
				SCRIPT_ERROR("Bad group format id %s",id.c_str())
			if(pGroup)
				SCRIPT_WRITE_PERSISTENT_OBJECT(Group,LUAGroup,*pGroup)
		}
	SCRIPT_CALLBACK_RETURN
}

int LUAGroups::Set(lua_State *pState) {
	SCRIPT_CALLBACK(Entities<Group>,LUAGroups,groups)
		SCRIPT_READ_STRING(name,"")
		lua_rawset(pState,1); // consumes key and value
	SCRIPT_CALLBACK_RETURN
}

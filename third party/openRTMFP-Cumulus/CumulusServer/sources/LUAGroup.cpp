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

#include "LUAGroup.h"
#include "Group.h"
#include "LUAClient.h"
#include "Util.h"

using namespace std;
using namespace Cumulus;
using namespace Poco;

const char*		LUAGroup::Name="Cumulus::Group";


int LUAGroup::IPairs(lua_State* pState) {
	SCRIPT_CALLBACK(Group,LUAGroup,group)
		lua_getglobal(pState,"next");
		if(!lua_iscfunction(pState,-1))
			SCRIPT_ERROR("'next' should be a LUA function, it should not be overloaded")
		else {
			lua_newtable(pState);
			GroupIterator it;
			UInt32 index=0;
			for(it=group.begin();it!=group.end();++it) {
				SCRIPT_WRITE_PERSISTENT_OBJECT(Client,LUAClient,**it)
				lua_rawseti(pState,-2,++index);
			}
		}
	SCRIPT_CALLBACK_RETURN
}

int LUAGroup::Get(lua_State *pState) {
	SCRIPT_CALLBACK(Group,LUAGroup,group)
		SCRIPT_READ_STRING(name,"")
		if(name=="id") {
			SCRIPT_WRITE_STRING(Cumulus::Util::FormatHex(group.id,ID_SIZE).c_str());
		} else if(name=="rawId") {
			SCRIPT_WRITE_BINARY(group.id,ID_SIZE);
		} else if(name=="size") {
			SCRIPT_WRITE_NUMBER(group.size());
		} else if(name=="ipairs") {
			SCRIPT_WRITE_FUNCTION(&LUAGroup::IPairs);
		}
	SCRIPT_CALLBACK_RETURN
}

int LUAGroup::Set(lua_State *pState) {
	SCRIPT_CALLBACK(Group,LUAGroup,group)
		SCRIPT_READ_STRING(name,"")
		lua_rawset(pState,1); // consumes key and value
	SCRIPT_CALLBACK_RETURN
}





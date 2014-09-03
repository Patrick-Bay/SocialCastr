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

#include "Script.h"
#include "Peer.h"

class LUAInvoker {
public:
	static const char* Name;

	static void ID(std::string& id);

	static int Get(lua_State *pState);
	static int Set(lua_State *pState);

private:
	static int	ToAMF(lua_State *pState);
	static int	ToAMF0(lua_State *pState);
	static int	FromAMF(lua_State *pState);

	static int	CreateTCPClient(lua_State *pState);
	static int	Publish(lua_State *pState);
	static int	AbsolutePath(lua_State *pState);
};

inline void LUAInvoker::ID(std::string& id) {
	id = "cumulus";
}



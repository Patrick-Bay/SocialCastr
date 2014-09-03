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
#include "Publication.h"

namespace Cumulus {

class Publications {
public:
	Publications(std::map<std::string,Publication*>& publications);
	virtual ~Publications();

	typedef std::map<std::string,Publication*>::iterator Iterator;

	Poco::UInt32 count();
	Iterator begin();
	Iterator end();

	Iterator operator()(Poco::UInt32 id);
	Iterator operator()(const std::string& name);

private:
	std::map<std::string,Publication*>&	_publications;
};

inline Poco::UInt32 Publications::count() {
	return _publications.size();
}

inline Publications::Iterator Publications::begin() {
	return _publications.begin();
}

inline Publications::Iterator Publications::end() {
	return _publications.end();
}

inline Publications::Iterator Publications::operator()(const std::string& name){
	return _publications.find(name);
}


} // namespace Cumulus

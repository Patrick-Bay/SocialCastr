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

#include "PacketWriter.h"
#include "Logs.h"

using namespace std;
using namespace Poco;

namespace Cumulus {

PacketWriter::PacketWriter(const UInt8* buffer,UInt32 size) : _memory((char*)buffer,size),BinaryWriter(_memory),_pOther(NULL),_size(size) {
}

// Consctruction by copy
PacketWriter::PacketWriter(PacketWriter& other) : _pOther(&other),_memory(other._memory),BinaryWriter(_memory),_size(other._size) {
	
}

PacketWriter::~PacketWriter() {
	flush();
}

void PacketWriter::limit(UInt32 length) {
	if(length==0)
		length = _size;
	if(length>_size) {
		WARN("Limit '%d' more upper than buffer size '%d' bytes",length,_size);
		length = _size;
	}
	_memory.resize(length);
}

void PacketWriter::clear(UInt32 pos) {
	reset(pos);
	_memory.written(pos);
}

void PacketWriter::flush() {
	if(_pOther && _memory.written()>_pOther->_memory.written())
		_pOther->_memory.written(_memory.written());
	BinaryWriter::flush();
}


} // namespace Cumulus

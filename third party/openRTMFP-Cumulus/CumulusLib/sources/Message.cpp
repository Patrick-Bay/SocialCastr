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

#include "Message.h"
#include "string.h"

using namespace std;
using namespace Poco;
using namespace Poco::Net;

namespace Cumulus {

Message::Message(istream& istr,bool repeatable) : _reader(istr),repeatable(repeatable) {
	
}


Message::~Message() {

}

BinaryReader& Message::reader(UInt32& size) {
	map<UInt32,UInt32>::const_iterator it = fragments.begin();
	size =  init(it==fragments.end() ? 0 : it->first);
	return _reader;
}

BinaryReader& Message::reader(UInt32 fragment,UInt32& size) {
	size =  init(fragment);
	return _reader;
}

MessageBuffered::MessageBuffered() : rawWriter(_stream),amfWriter(rawWriter),Message(_stream,true) {
	
}


MessageBuffered::~MessageBuffered() {

}


UInt32 MessageBuffered::init(UInt32 position) {
	_stream.resetReading(position);
	return _stream.size();
}

MessageUnbuffered::MessageUnbuffered(const UInt8* data,UInt32 size,const UInt8* memAckData,UInt32 memAckSize) : _stream((const char*)data,size),Message(_stream,false),_bufferAck(memAckSize) {
	memcpy(_bufferAck.begin(),memAckData,memAckSize);
	_pMemAck = new MemoryInputStream(_bufferAck.begin(),memAckSize);
	_pReaderAck = new BinaryReader(*_pMemAck);
}


MessageUnbuffered::~MessageUnbuffered() {
	delete _pReaderAck;
	delete _pMemAck;
}

UInt32 MessageUnbuffered::init(UInt32 position) {
	_stream.reset(position);
	return _stream.available();
}

BinaryReader& MessageUnbuffered::memAck(UInt32& size) {
	size = _pMemAck->available();
	return *_pReaderAck;
}

MessageNull::MessageNull() {
	rawWriter.stream().setstate(ios_base::eofbit);
}

MessageNull::~MessageNull() {
}





} // namespace Cumulus

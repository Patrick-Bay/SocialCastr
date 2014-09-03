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

#include "MemoryStream.h"


using namespace std;
using namespace Poco;

namespace Cumulus {

ScopedMemoryClip::ScopedMemoryClip(MemoryStreamBuf& buffer,UInt32 offset) : _offset(offset),_buffer(buffer) {
	if(_offset>=_buffer._bufferSize)
		_offset = _buffer._bufferSize-1;
	if(_offset<0)
		_offset=0;
	clip(_offset);
}
ScopedMemoryClip::~ScopedMemoryClip() {
	clip(-(Int32)_offset);
}

void ScopedMemoryClip::clip(Int32 offset) {
	char* gpos = _buffer.gCurrent();

	_buffer._pBuffer += offset;
	_buffer._bufferSize -= offset;
	
	int ppos = _buffer.pCurrent()-_buffer._pBuffer;

	_buffer.setg(_buffer._pBuffer,gpos,_buffer._pBuffer + _buffer._bufferSize);

	_buffer.setp(_buffer._pBuffer,_buffer._pBuffer + _buffer._bufferSize);
	_buffer.pbump(ppos);

	if(_buffer._written<offset)
		_buffer._written=0;
	else
		_buffer._written-=offset;
	if(_buffer._written>_buffer._bufferSize)
		_buffer._written=_buffer._bufferSize;
}

MemoryStreamBuf::MemoryStreamBuf(char* pBuffer, UInt32 bufferSize): _pBuffer(pBuffer),_bufferSize(bufferSize),_written(0) {
	setg(_pBuffer, _pBuffer,_pBuffer + _bufferSize);
	setp(_pBuffer, _pBuffer + _bufferSize);
}

MemoryStreamBuf::MemoryStreamBuf(MemoryStreamBuf& other): _pBuffer(other._pBuffer),_bufferSize(other._bufferSize),_written(other._written) {
	setg(_pBuffer,other.gCurrent(),_pBuffer + _bufferSize);
	setp(_pBuffer,_pBuffer + _bufferSize);
	pbump((int)(other.pCurrent()-_pBuffer));
}


MemoryStreamBuf::~MemoryStreamBuf() {
}

void MemoryStreamBuf::next(UInt32 size) {
	pbump(size);
	gbump(size);
}

void MemoryStreamBuf::position(UInt32 pos) {
	written(); // Save nb char written
	setp(_pBuffer,_pBuffer + _bufferSize);
	if(pos>_bufferSize)
		pos = _bufferSize;
	pbump((int)pos);
	setg(_pBuffer,_pBuffer+pos,_pBuffer + _bufferSize);
}

void MemoryStreamBuf::resize(UInt32 newSize) {
	_bufferSize = newSize;
	int pos = gCurrent()-_pBuffer;
	if(pos>_bufferSize)
		pos = _bufferSize;
	setg(_pBuffer,_pBuffer+pos,_pBuffer + _bufferSize);
	pos = pCurrent()-_pBuffer;
	if(pos>_bufferSize)
		pos = _bufferSize;
	setp(_pBuffer,_pBuffer + _bufferSize);
	pbump(pos);
}

UInt32 MemoryStreamBuf::written() {
	int written = pCurrent()-begin();
	if(written<0)
		written=0;
	if(written>_written) 
		_written = (UInt32)written;
	return _written;
}

void MemoryStreamBuf::written(UInt32 size) {
	_written=size;
}

int MemoryStreamBuf::overflow(int_type c) {
	return EOF;
}

int MemoryStreamBuf::underflow() {
	return EOF;
}

int MemoryStreamBuf::sync() {
	return 0;
}


MemoryIOS::MemoryIOS(char* pBuffer, UInt32 bufferSize):_buf(pBuffer, bufferSize) {
	poco_ios_init(&_buf);
}
MemoryIOS::MemoryIOS(MemoryIOS& other):_buf(other._buf) {
	poco_ios_init(&_buf);
}

MemoryIOS::~MemoryIOS() {
}

void MemoryIOS::reset(UInt32 newPos) {
	if(newPos>=0)
		rdbuf()->position(newPos);
	clear();
}

UInt32 MemoryIOS::available() {
	int result = rdbuf()->size() - (current()-begin());
	if(result<0)
		return 0;
	return (UInt32)result;
}



MemoryInputStream::MemoryInputStream(const char* pBuffer, UInt32 bufferSize): 
	MemoryIOS(const_cast<char*>(pBuffer), bufferSize), istream(rdbuf()) {
}

MemoryInputStream::MemoryInputStream(MemoryInputStream& other):
	MemoryIOS(other), istream(rdbuf()) {
}

MemoryInputStream::~MemoryInputStream() {
}


MemoryOutputStream::MemoryOutputStream(char* pBuffer, UInt32 bufferSize): 
	MemoryIOS(pBuffer, bufferSize), ostream(rdbuf()) {
}
MemoryOutputStream::MemoryOutputStream(MemoryOutputStream& other):
	MemoryIOS(other), ostream(rdbuf()) {
}

MemoryOutputStream::~MemoryOutputStream(){
}


} // namespace Cumulus

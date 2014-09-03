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
#include "Poco/Timestamp.h"
#include <list>

namespace Cumulus {

class Sample;
class QualityOfService {
public:
	QualityOfService();
	virtual ~QualityOfService();

	void add(Poco::UInt32 time,Poco::UInt32 received,Poco::UInt32 lost);
	void reset();

	const Poco::UInt32	droppedFrames;
	const double		lostRate;
	const Poco::UInt32	latency;
private:
	std::list<Sample*>	_samples;
	Poco::UInt32		_prevTime;
	Poco::Timestamp		_reception;

	Poco::UInt32		_num;
	Poco::UInt32		_den;
};


} // namespace Cumulus

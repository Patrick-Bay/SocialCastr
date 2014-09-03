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
#include "Group.h"
#include "Streams.h"
#include "Edges.h"
#include "Entities.h"

namespace Cumulus {

class Invoker : public Entity {
	friend class Peer; // Peer manage _clients and _groups list!
	friend class Handshake; // Peer manage _edges list!
	friend class FlowStream; // FlowStream manage _streams list!
	friend class FlowConnection; // FlowConnection manage _streams list!
public:
	Invoker();
	virtual ~Invoker();

	// invocations
	Entities<Client>		clients;
	Entities<Group>			groups;
	Edges					edges;
	Publications			publications;


	Publication&			publish(const std::string& name);
	void					unpublish(const Publication& name);

	void					addBanned(const Poco::Net::IPAddress& ip);
	void					clearBannedList();
	bool					isBanned(const Poco::Net::IPAddress& ip);

	// properties
	const Poco::UInt32		udpBufferSize;
	const Poco::UInt32		keepAlivePeer;
	const Poco::UInt32		keepAliveServer;
	const Poco::UInt8		edgesAttemptsBeforeFallback;
private:
	virtual Peer&													myself()=0;
	std::map<std::string,Publication*>								_publications;
	Streams															_streams;
	std::set<const Publication*>									_publishers;
	Entities<Group>::Map											_groups;
	std::map<std::string,Edge*>										_edges;
	Entities<Client>::Map											_clients;
	std::set<Poco::Net::IPAddress>									_bannedList;
};

inline void Invoker::addBanned(const Poco::Net::IPAddress& ip) {
	_bannedList.insert(ip);
}

inline void Invoker::clearBannedList() {
	_bannedList.clear();
}

inline bool Invoker::isBanned(const Poco::Net::IPAddress& ip) {
	return _bannedList.find(ip)!=_bannedList.end();
}


} // namespace Cumulus

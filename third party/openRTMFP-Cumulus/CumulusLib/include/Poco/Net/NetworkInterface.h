//
// NetworkInterface.h
//
// $Id: //poco/1.4/Net/include/Poco/Net/NetworkInterface.h#4 $
//
// Library: Net
// Package: Sockets
// Module:  NetworkInterface
//
// Definition of the NetworkInterface class.
//
// Copyright (c) 2005-2006, Applied Informatics Software Engineering GmbH.
// and Contributors.
//
// Permission is hereby granted, free of charge, to any person or organization
// obtaining a copy of the software and accompanying documentation covered by
// this license (the "Software") to use, reproduce, display, distribute,
// execute, and transmit the Software, and to prepare derivative works of the
// Software, and to permit third-parties to whom the Software is furnished to
// do so, all subject to the following:
// 
// The copyright notices in the Software and this entire statement, including
// the above license grant, this restriction and the following disclaimer,
// must be included in all copies of the Software, in whole or in part, and
// all derivative works of the Software, unless such copies or derivative
// works are solely in the form of machine-executable object code generated by
// a source language processor.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
// SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
// FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//


#ifndef Net_NetworkInterface_INCLUDED
#define Net_NetworkInterface_INCLUDED


#include "Poco/Net/Net.h"
#include "Poco/Net/IPAddress.h"
#include "Poco/Mutex.h"
#include <vector>


namespace Poco {
namespace Net {


class NetworkInterfaceImpl;


class Net_API NetworkInterface
	/// This class represents a network interface.
	/// 
	/// NetworkInterface is used with MulticastSocket to specify
	/// multicast interfaces for sending and receiving multicast
	/// messages.
	/// 
	/// The class also provides static member functions for
	/// enumerating or searching network interfaces.
{
public:
	typedef std::vector<NetworkInterface> NetworkInterfaceList;
	
	enum IPVersion
	{
		IPv4_ONLY,    /// Return interfaces with IPv4 address only
		IPv6_ONLY,    /// Return interfaces with IPv6 address only
		IPv4_OR_IPv6  /// Return interfaces with IPv4 or IPv6 address
	};

	NetworkInterface();
		/// Creates a NetworkInterface representing the
		/// default interface.
		///
		/// The name is empty, the IP address is the wildcard
		/// address and the index is zero.
	
	NetworkInterface(const NetworkInterface& interfc);
		/// Creates the NetworkInterface by copying another one.

	~NetworkInterface();
		/// Destroys the NetworkInterface.

	NetworkInterface& operator = (const NetworkInterface& interfc);
		/// Assigns another NetworkInterface.
		
	void swap(NetworkInterface& other);
		/// Swaps the NetworkInterface with another one.	
		
	int index() const;
		/// Returns the interface index.
		///
		/// Only supported if IPv6 is available.
		/// Returns -1 if IPv6 is not available.
		
	const std::string& name() const;
		/// Returns the interface name.
		
	const std::string& displayName() const;
		/// Returns the interface display name.
		///
		/// On Windows platforms, this is currently the network adapter
		/// name. This may change to the "friendly name" of the network
		/// connection in a future version, however. 
		///
		/// On other platforms this is the same as name().
		
	const IPAddress& address() const;
		/// Returns the IP address bound to the interface.
		
	const IPAddress& subnetMask() const;
		/// Returns the IPv4 subnet mask for this network interface.
		
	const IPAddress& broadcastAddress() const;
		/// Returns the IPv4 broadcast address for this network interface.
		
	bool supportsIPv4() const;
		/// Returns true if the interface supports IPv4.
		
	bool supportsIPv6() const;
		/// Returns true if the interface supports IPv6.	
		
	static NetworkInterface forName(const std::string& name, bool requireIPv6 = false);
		/// Returns the NetworkInterface for the given name.
		/// 
		/// If requireIPv6 is false, an IPv4 interface is returned.
		/// Otherwise, an IPv6 interface is returned.
		///
		/// Throws an InterfaceNotFoundException if an interface
		/// with the give name does not exist.

	static NetworkInterface forName(const std::string& name, IPVersion ipVersion);
		/// Returns the NetworkInterface for the given name.
		/// 
		/// The ipVersion argument can be used to specify whether
		/// an IPv4 (IPv4_ONLY) or IPv6 (IPv6_ONLY) interface is required, 
		/// or whether the caller does not care (IPv4_OR_IPv6).
		
	static NetworkInterface forAddress(const IPAddress& address);
		/// Returns the NetworkInterface for the given IP address.
		///
		/// Throws an InterfaceNotFoundException if an interface
		/// with the give address does not exist.

	static NetworkInterface forIndex(int index);
		/// Returns the NetworkInterface for the given interface index.
		/// If an index of 0 is specified, a NetworkInterface instance
		/// representing the default interface (empty name and
		/// wildcard address) is returned.
		///
		/// Throws an InterfaceNotFoundException if an interface
		/// with the given index does not exist (or IPv6 is not
		/// available).
		
	static NetworkInterfaceList list();
		/// Returns a list with all network interfaces
		/// on the system.
		///
		/// If there are multiple addresses bound to one interface,
		/// multiple NetworkInterface instances are created for
		/// the same interface.

protected:
	NetworkInterface(const std::string& name, const std::string& displayName, const IPAddress& address, int index = -1);
		/// Creates the NetworkInterface.

	NetworkInterface(const std::string& name, const std::string& displayName, const IPAddress& address, const IPAddress& subnetMask, const IPAddress& broadcastAddress, int index = -1);
		/// Creates the NetworkInterface.
		
	NetworkInterface(const std::string& name, const IPAddress& address, int index = -1);
		/// Creates the NetworkInterface.

	NetworkInterface(const std::string& name, const IPAddress& address, const IPAddress& subnetMask, const IPAddress& broadcastAddress, int index = -1);
		/// Creates the NetworkInterface.
		
	IPAddress interfaceNameToAddress(const std::string& interfaceName) const;
		/// Determines the IPAddress bound to the interface with the given name.
		
	int interfaceNameToIndex(const std::string& interfaceName) const;
		/// Determines the interface index of the interface with the given name.

private:
	NetworkInterfaceImpl* _pImpl;
	
	static Poco::FastMutex _mutex;
};


} } // namespace Poco::Net


#endif // Net_NetworkInterface_INCLUDED

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

#include "Middle.h"
#include "Logs.h"
#include "Util.h"
#include "RTMFP.h"
#include "AMFWriter.h"
#include "AMFReader.h"
#include "Poco/Format.h"
#include "Poco/RandomStream.h"
#include <openssl/evp.h>
#include <openssl/hmac.h>
#include "string.h"

using namespace std;
using namespace Poco;
using namespace Poco::Net;

namespace Cumulus {

Middle::Middle(UInt32 id,
				UInt32 farId,
				const Peer& peer,
				const UInt8* decryptKey,
				const UInt8* encryptKey,
				Handler& handler,
				const Sessions&	sessions,
				Target& target) : ServerSession(id,farId,peer,decryptKey,encryptKey,(Invoker&)handler),_pMiddleAesDecrypt(NULL),_pMiddleAesEncrypt(NULL),_isPeer(target.isPeer),
					_middleId(0),_sessions(sessions),_firstResponse(false),_queryUrl("rtmfp://"+target.address.toString()+peer.path),_middlePeer(peer),_target(target) {

	Util::UnpackUrl(_queryUrl,(string&)_middlePeer.path,(map<string,string>&)_middlePeer.properties);

	// connection to target
	_socket.setReceiveBufferSize(_invoker.udpBufferSize);_socket.setSendBufferSize(_invoker.udpBufferSize);
	_socket.connect(target.address);

	INFO("Handshake Target");

	memcpy(_middleCertificat,"\x02\x1D\x02\x41\x0E",5);
	RandomInputStream().read((char*)&_middleCertificat[5],64);
	memcpy(&_middleCertificat[69],"\x03\x1A\x02\x0A\x02\x1E\x02",7);

	////  HANDSHAKE TARGET  /////

	PacketWriter& packet = handshaker();

	if(_isPeer) {
		_pMiddleDH = target.pDH;
		memcpy((UInt8*)_middlePeer.id,target.id,ID_SIZE);

		packet.write8(0x22);
		packet.write8(0x21);
		packet.write8(0x0F);
		packet.writeRaw(target.peerId,ID_SIZE);
	} else {
		packet.write8(_queryUrl.size()+2);
		packet.write8(_queryUrl.size()+1);
		packet.write8(0x0A);
		packet.writeRaw(_queryUrl);
	}

	// tag
	RandomInputStream().read((char*)packet.begin()+packet.position(),16);
	packet.clear(packet.position()+16);

	sendHandshakeToTarget(0x30);
}

Middle::~Middle() {
	if(_pMiddleAesDecrypt)
		delete _pMiddleAesDecrypt;
	if(_pMiddleAesEncrypt)
		delete _pMiddleAesEncrypt;
}

bool Middle::decode(PacketReader& packet) {
	if(farId==0)
		return RTMFP::Decode(packet);
	return Session::decode(packet);
}
void Middle::encode(PacketWriter& packet) {
	if(farId==0) {
		RTMFP::Encode(packet);
		return;
	}
	Session::encode(packet);
}

PacketWriter& Middle::handshaker() {
	PacketWriter& writer(ServerSession::writer());
	writer.clear(12);
	return writer;
}

void Middle::targetHandshakeHandler(UInt8 type,PacketReader& packet) {

	switch(type) {
		case 0x70: {

			string tag;
			packet.readString8(tag);

			// response	
			string cookie;
			packet.readString8(cookie);

			string targetCertificat;
			UInt8 nonce[KEY_SIZE+4]={0x81,0x02,0x1D,0x02};
			if(_isPeer) {
				packet.next(4);
				memcpy(&nonce[4],_target.publicKey,KEY_SIZE);
				RTMFP::ComputeDiffieHellmanSecret(_pMiddleDH,packet.current(),KEY_SIZE,_sharedSecret);
				// DEBUG("Middle Shared Secret : %s",Util::FormatHex(_sharedSecret,sizeof(_sharedSecret)).c_str());
			} else {
				packet.readRaw(packet.available(),targetCertificat);
				_pMiddleDH = RTMFP::BeginDiffieHellman(&nonce[4]);
				EVP_Digest(nonce,sizeof(nonce),(UInt8*)_middlePeer.id,NULL,EVP_sha256(),NULL);
			}

			
			// request reply
			PacketWriter& request = handshaker();
			request << id; // id session, we use the same that Cumulus id session for Flash client
			request.writeString8(cookie); // cookie
			request.write7BitValue(sizeof(nonce));
			request.writeRaw(nonce,sizeof(nonce));
			request.write7BitValue(sizeof(_middleCertificat));
			request.writeRaw(_middleCertificat,sizeof(_middleCertificat));
			request.write8(0x58);
			sendHandshakeToTarget(0x38);
			
			break;
		}
		case 0x71: {

			string tag;
			packet.readString8(tag);

			if(_pMiddleAesDecrypt) {
				// P2P handshake
				PacketWriter& response = writer();
				response.write8(0x71);
				response.write16((UInt16)packet.available()+tag.size()+1);
				response.writeString8(tag);
				response.writeRaw(packet.current(),packet.available());

				// to send in handshake mode!
				UInt32 oldFarId = farId;
				(UInt32&)farId = 0;
				flush(0x0b,false);
				(UInt32&)farId = oldFarId;

			}  else {
				// redirection request
				PacketReader content(packet);
				WARN("Man-in-middle mode leaks : redirection request, restart Cumulus with a url pertinant chooses among the following list");
				while(content.available()) {
				   if(content.read8()==0x01) {
					   UInt8 a=content.read8(),b=content.read8(),c=content.read8(),d=content.read8();
					   printf("%u.%u.%u.%u:%hu",a,b,c,d,content.read16());
					   cout << endl;
				   }
				}
				
				ServerSession::fail("Redirection 'man in the middle' request"); // to prevent the other side
				kill(); // In this redirection request case, the target session has never existed!
			}

			break;
		}
		case 0x78: {

			// response
			packet >> _middleId;
			_targetNonce.resize(packet.read7BitValue());
			packet.readRaw(&_targetNonce[0],_targetNonce.size());
			
			if(!_isPeer)
				RTMFP::EndDiffieHellman(_pMiddleDH,&_targetNonce[_targetNonce.size()-KEY_SIZE],KEY_SIZE,_sharedSecret);

			UInt8 requestKey[AES_KEY_SIZE];
			UInt8 responseKey[AES_KEY_SIZE];
			RTMFP::ComputeAsymetricKeys(_sharedSecret,_middleCertificat,sizeof(_middleCertificat),&_targetNonce[0],_targetNonce.size(),requestKey,responseKey);
			_pMiddleAesEncrypt = new AESEngine(requestKey,AESEngine::ENCRYPT);
			_pMiddleAesDecrypt = new AESEngine(responseKey,AESEngine::DECRYPT);

			DEBUG("Middle Shared Secret : %s",Util::FormatHex(_sharedSecret,sizeof(_sharedSecret)).c_str());

			// DEBUG("Peer/Middle/Target id : %s/%s/%s",Util::FormatHex(this->peer().id,ID_SIZE).c_str(),Util::FormatHex(_middlePeer.id,ID_SIZE).c_str(),Util::FormatHex(_target.peerId,ID_SIZE).c_str());
			break;
		}

		default: {
			ERROR("Unknown Target handshake type '%02x'",type);
		}
	}
}

void Middle::sendHandshakeToTarget(UInt8 type) {
	PacketWriter& packet(ServerSession::writer());
	packet.reset(6);
	packet.write8(0x0b);
	packet << RTMFP::TimeNow();
	packet << type;
	packet.write16((UInt16)packet.length()-packet.position()-2);

	Logs::Dump(packet,6,format("Middle to %s handshaking",_target.address.toString()).c_str(),true);

	RTMFP::Encode(packet);
	RTMFP::Pack(packet,0);
	_socket.sendBytes(packet.begin(),(int)packet.length());
	writer(); // To delete the handshake response!
}

PacketWriter& Middle::requester() {
	PacketWriter& writer(ServerSession::writer());
	writer.clear(6);
	writer.limit(PACKETSEND_SIZE-4);
	return writer;
}

PacketWriter& Middle::writer() {
	PacketWriter& writer(ServerSession::writer());
	writer.clear(11);
	writer.limit(PACKETSEND_SIZE-4);
	return writer;
}

void Middle::packetHandler(PacketReader& packet) {
	if(!_pMiddleAesEncrypt) {
		DEBUG("500ms sleeping to wait target handshaking");
		Thread::sleep(500); // to wait the target handshake response
		manage();
	}

	// Middle to target
	PacketWriter& request = requester();

	UInt8 marker = packet.read8();
	request << marker;

	request << packet.read16();

	if((marker|0xF0) == 0xFD)
		request.write16(packet.read16()); // time echo

	int pos = request.position();

	UInt8 type = packet.available()>0 ? packet.read8() : 0xFF;
	while(type!=0xFF) {
		UInt16 size = packet.read16();
		PacketReader content(packet.current(),size);

		PacketWriter out(request.begin()+request.position(),request.available()); // 3 for future type and size
		out.clear(3);

		if(type==0x10) {

			out.write8(content.read8());
			UInt32 idFlow = content.read7BitValue();out.write7BitValue(idFlow);
			UInt32 stage = content.read7BitValue();out.write7BitValue(stage);

			if(idFlow==0x02 && stage==0x01) {
				if(!_isPeer) {
				
					/// Replace NetConnection infos

					out.writeRaw(content.current(),14);content.next(14);

					// first string
					string tmp;
					content.readString16(tmp);out.writeString16(tmp);

					AMFWriter writer(out);
					writer.amf0Preference=true;
					AMFReader reader(content);
					writer.writeNumber(reader.readNumber()); // double
					
					AMFSimpleObject obj;
					reader.readSimpleObject(obj);
					
					/// Replace tcUrl
					if(obj.has("tcUrl"))
						obj.setString("tcUrl",_queryUrl);
					
					writer.writeSimpleObject(obj);

				} else {

					out.writeRaw(content.current(),3);content.next(3);
					UInt16 netGroupHeader = content.read16();out.write16(netGroupHeader);
					if(netGroupHeader==0x4752) {
						out.writeRaw(content.current(),71);content.next(71);
						
						Entities<Group>::Iterator it;
						for(it = _invoker.groups.begin();it!=_invoker.groups.end();++it) {
	
							Group& group = *it->second;						
			
							Group::Iterator itP;
							for(itP=group.begin();itP!=group.end();++itP) {
								if((**itP)==_target.id) {
									UInt8 result1[AES_KEY_SIZE];
									UInt8 result2[AES_KEY_SIZE];
									HMAC(EVP_sha256(),_sharedSecret,KEY_SIZE,&_targetNonce[0],_targetNonce.size(),result1,NULL);
									HMAC(EVP_sha256(),group.id,ID_SIZE,result1,AES_KEY_SIZE,result2,NULL);
									out.writeRaw(result2,AES_KEY_SIZE);content.next(AES_KEY_SIZE);
									out.writeRaw(content.current(),4);content.next(4);
									out.writeRaw(_target.peerId,ID_SIZE);content.next(ID_SIZE);
									break;
								}
							}
							if(itP!=group.end())
								break;

						}
						if(it==_invoker.groups.end())
							ERROR("Handshake NetGroup packet between peers without corresponding Group");
						
					}
				}
			}

		}  else if(type == 0x4C) {
			 kill();
		}  else if(type == 0x51) {
			//printf("%s\n",Util::FormatHex(content.current(),content.available()).c_str());
		}
		out.writeRaw(content.current(),content.available());

		packet.next(size);

		if(out.length()>=3) {
			request<<type;
			size = out.length()-3;
			request.write16(size);request.next(size);
		}


		type = packet.available()>0 ? packet.read8() : 0xFF;
	}

	if(request.length()>pos)
		sendToTarget();
}

void Middle::sendToTarget() {
	if(!_pMiddleAesEncrypt) {
		CRITIC("Send to target packet impossible because the middle hanshake has certainly failed, the target address is may be bad");
		return;
	}
	
	PacketWriter& packet(ServerSession::writer());

	Logs::Dump(packet,6,format("Middle to %s",_target.address.toString()).c_str(),true);

	_firstResponse = true;
	RTMFP::Encode(*_pMiddleAesEncrypt,packet);
	RTMFP::Pack(packet,_middleId);
	_socket.sendBytes(packet.begin(),(int)packet.length());
}

void Middle::targetPacketHandler(PacketReader& packet) {

	if(_firstResponse)
		_recvTimestamp.update(); // To emulate a long ping corresponding, otherwise client send multiple times each packet
	_firstResponse = false;

	UInt8 marker = packet.read8();
	
	UInt16 timestamp = packet.read16(); // time

	if((marker|0xF0) == 0xFE)
		_timeSent = packet.read16(); // time echo

	PacketWriter& packetOut = writer();

	int pos = packetOut.position();

	UInt8 type = packet.available()>0 ? packet.read8() : 0xFF;

	UInt32 idFlow,stage;
	UInt8 nbPeerSent = 0;

	while(type!=0xFF) {
		int posType = packetOut.position();
		packetOut.write8(type);

		UInt16 size = packet.read16();
		PacketReader content(packet.current(),size);packetOut.write16(size);
		
		if(type==0x10 || type==0x11) {
			UInt8 flag = content.read8();packetOut.write8(flag);
			if(type==0x10) {
				idFlow = content.read7BitValue();packetOut.write7BitValue(idFlow);
				stage = content.read7BitValue();packetOut.write7BitValue(stage);
			} else
				++stage;

			packetOut.write7BitValue(content.read7BitValue());
			
			if(!(flag&MESSAGE_WITH_BEFOREPART)) {

				if(flag&MESSAGE_HEADER) {
					UInt8 len = content.read8(); packetOut.write8(len);
					while(len!=0) {
						packetOut.writeRaw(content.current(),len);
						content.next(len);
						len = content.read8(); packetOut.write8(len);
					}
				}

				UInt8 flagType = content.read8(); packetOut.write8(flagType);
				if(flagType==0x09) {
					UInt32 time = content.read32(); packetOut.write32(time);
					//TRACE("Timestamp/Flag video : %u/%2x",time,*content.current());
				} else if(flagType==0x08) {
					UInt32 time = content.read32(); packetOut.write32(time);
					//TRACE("Timestamp/Flag audio : %u/%2x",time,*content.current());
				} else if(flagType==0x04) {
					packetOut.write32(content.read32());
					UInt16 a = content.read16(); packetOut.write16(a);
					UInt32 b = content.read32(); packetOut.write32(b);
					UInt32 c = content.read32(); packetOut.write32(c);
					//TRACE("Bound %u : %u %u %u",idFlow,a,b,c);
				}

				if(flagType==0x0b && stage==0x01 && ((marker==0x4e && idFlow==0x03) || (marker==0x8e && idFlow==0x05))) {
					/// Replace "middleId" by "peerId"	

					UInt8 middlePeerIdWanted[ID_SIZE];
					content.readRaw(middlePeerIdWanted,ID_SIZE);

					++nbPeerSent;

					Sessions::Iterator it;
					for(it=_sessions.begin();it!=_sessions.end();++it) {
						Middle* pMiddle = (Middle*)it->second;
						if(pMiddle->middlePeer() == middlePeerIdWanted) {
							memcpy(middlePeerIdWanted,pMiddle->peer.id,ID_SIZE);
							break;
						}
					}
					packetOut.writeRaw(middlePeerIdWanted,ID_SIZE);	

				} else if(flagType == 0x01) {

					packetOut.writeRaw(content.current(),68);content.next(68);
					
					Entities<Group>::Iterator it;
					for(it = _invoker.groups.begin();it!=_invoker.groups.end();++it) {

						Group& group = *it->second;						
			
						Group::Iterator itP;
						for(itP=group.begin();itP!=group.end();++itP) {
							if((**itP)==_target.id) {
								UInt8 result1[AES_KEY_SIZE];
								UInt8 result2[AES_KEY_SIZE];
								HMAC(EVP_sha256(),_target.sharedSecret,KEY_SIZE,&_target.initiatorNonce[0],_target.initiatorNonce.size(),result1,NULL);
								HMAC(EVP_sha256(),group.id,ID_SIZE,result1,AES_KEY_SIZE,result2,NULL);
								packetOut.writeRaw(result2,AES_KEY_SIZE);content.next(AES_KEY_SIZE);
								packetOut.writeRaw(content.current(),4);content.next(4);
								packetOut.writeRaw(peer.id,ID_SIZE);content.next(ID_SIZE);
								break;
							}
						}
						if(itP!=group.end())
							break;

					}
				
					if(it==_invoker.groups.end())
						ERROR("Handshake NetGroup packet between peers without corresponding Group");

				}
			}

		} else if(type == 0x0F) {
			packetOut.writeRaw(content.current(),3);content.next(3);
			UInt8 peerId[ID_SIZE];
			content.readRaw(peerId,ID_SIZE);

			if(memcmp(peerId,peer.id,ID_SIZE)!=0 && memcmp(peerId,_middlePeer.id,ID_SIZE)!=0)
				WARN("The p2pHandshake target packet doesn't match the peerId (or the middlePeerId)");
			// Replace by the peer.id
			packetOut.writeRaw(peer.id,ID_SIZE);
		}

		packetOut.writeRaw(content.current(),content.available());
		packet.next(size);

		type = packet.available()>0 ? packet.read8() : 0xFF;
	}

	if(nbPeerSent>0)
		INFO("%02x peers sending",nbPeerSent);

	if(packetOut.length()>pos)
		flush();

}


void Middle::manage() {
	if(died)
		return;

	while(_socket.available()>0) {

		int len = 0;
		try {
			len = _socket.receiveBytes(_buffer,sizeof(_buffer));
		} catch(Exception& ex) {
			ERROR("Middle socket reception error : %s",ex.displayText().c_str());
			return;
		}

		PacketReader packet(_buffer,len);

		if(packet.available()<RTMFP_MIN_PACKET_SIZE) {
			ERROR("Middle from %s : invalid packet",_target.address.toString().c_str());
			return;
		}

		UInt32 id = RTMFP::Unpack(packet);

		// Handshaking
		if(id==0 || !_pMiddleAesDecrypt) {
			if(!RTMFP::Decode(packet)) {
				ERROR("Target handshake decrypt error");
				return;
			}

			Logs::Dump(packet,format("Middle from %s handshaking",_target.address.toString()).c_str(),true);

			UInt8 marker = packet.read8();
			if(marker!=0x0B) {
				ERROR("Target handshake received with a marker different of '0b'");
				return;
			}

			packet.read16(); // time

			UInt8 type = packet.read8();
			UInt16 size = packet.read16();
			PacketReader content(packet.current(),size);
			targetHandshakeHandler(type,content);
			return;
		}

		if(!RTMFP::Decode(*_pMiddleAesDecrypt,packet)) {
			ERROR("Target to middle : Decrypt error");
			return;
		}

	//	TRACE("Target to middle : session d'identification '%u'",id);
		Logs::Dump(packet,format("Middle from %s",_target.address.toString()).c_str(),true);

		targetPacketHandler(packet);
	}

}

void Middle::failSignal() {
	ServerSession::failSignal();
	if(_pMiddleAesEncrypt) {
		PacketWriter& request = requester();
		request.write8(0x4a);
		request << RTMFP::TimeNow();
		request.write8(0x4c);
		request.write16(0);
		sendToTarget();
	}
}



} // namespace Cumulus
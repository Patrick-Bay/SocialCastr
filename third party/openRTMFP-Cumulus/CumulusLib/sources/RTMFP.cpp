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

#include "RTMFP.h"
#include "PacketWriter.h"
#include "Util.h"
#include "MemoryStream.h"
#include "Poco/BinaryWriter.h"
#include "Poco/StreamCopier.h"
#include "Logs.h"
#include <openssl/evp.h>
#include <openssl/hmac.h>
#include <string.h>

#define TIMESTAMP_SCALE 4

using namespace std;
using namespace Poco;

namespace Cumulus {

AESEngine RTMFP::s_aesDecrypt(RTMFP_SYMETRIC_KEY,AESEngine::DECRYPT);
AESEngine RTMFP::s_aesEncrypt(RTMFP_SYMETRIC_KEY,AESEngine::ENCRYPT);


UInt8 g_dh1024p[] = {
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xC9, 0x0F, 0xDA, 0xA2, 0x21, 0x68, 0xC2, 0x34,
	0xC4, 0xC6, 0x62, 0x8B, 0x80, 0xDC, 0x1C, 0xD1,
	0x29, 0x02, 0x4E, 0x08, 0x8A, 0x67, 0xCC, 0x74,
	0x02, 0x0B, 0xBE, 0xA6, 0x3B, 0x13, 0x9B, 0x22,
	0x51, 0x4A, 0x08, 0x79, 0x8E, 0x34, 0x04, 0xDD,
	0xEF, 0x95, 0x19, 0xB3, 0xCD, 0x3A, 0x43, 0x1B,
	0x30, 0x2B, 0x0A, 0x6D, 0xF2, 0x5F, 0x14, 0x37,
	0x4F, 0xE1, 0x35, 0x6D, 0x6D, 0x51, 0xC2, 0x45,
	0xE4, 0x85, 0xB5, 0x76, 0x62, 0x5E, 0x7E, 0xC6,
	0xF4, 0x4C, 0x42, 0xE9, 0xA6, 0x37, 0xED, 0x6B,
	0x0B, 0xFF, 0x5C, 0xB6, 0xF4, 0x06, 0xB7, 0xED,
	0xEE, 0x38, 0x6B, 0xFB, 0x5A, 0x89, 0x9F, 0xA5,
	0xAE, 0x9F, 0x24, 0x11, 0x7C, 0x4B, 0x1F, 0xE6,
	0x49, 0x28, 0x66, 0x51, 0xEC, 0xE6, 0x53, 0x81,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};

RTMFP::RTMFP() {

}

RTMFP::~RTMFP() {
}


UInt16 RTMFP::CheckSum(PacketReader& packet) {
	int sum = 0;
	int pos = packet.position();
	while(packet.available()>0)
		sum += packet.available()==1 ? packet.read8() : packet.read16();
	packet.reset(pos);

  /* add back carry outs from top 16 bits to low 16 bits */
  sum = (sum >> 16) + (sum & 0xffff);     /* add hi 16 to low 16 */
  sum += (sum >> 16);                     /* add carry */
  return ~sum; /* truncate to 16 bits */
}


bool RTMFP::Decode(AESEngine& aesDecrypt,PacketReader& packet) {
	// Decrypt
	aesDecrypt.process(packet.current(),packet.current(),packet.available());
	return ReadCRC(packet);
}

bool RTMFP::ReadCRC(PacketReader& packet) {
	// Check the first 2 CRC bytes 
	packet.reset(4);
	UInt16 sum = packet.read16();
	return (sum == CheckSum(packet));
}


void RTMFP::Encode(AESEngine& aesEncrypt,PacketWriter& packet) {
	if(!aesEncrypt.null) {
		// paddingBytesLength=(0xffffffff-plainRequestLength+5)&0x0F
		int paddingBytesLength = (0xFFFFFFFF-packet.length()+5)&0x0F;
		// Padd the plain request with paddingBytesLength of value 0xff at the end
		packet.reset(packet.length());
		string end(paddingBytesLength,(UInt8)0xFF);
		packet.writeRaw(end);
	}

	WriteCRC(packet);
	
	// Encrypt the resulted request
	aesEncrypt.process(packet.begin()+4,packet.begin()+4,packet.length()-4);
}

void RTMFP::WriteCRC(PacketWriter& packet) {
	// Compute the CRC and add it at the beginning of the request
	PacketReader reader(packet.begin(),packet.length());
	reader.next(6);
	UInt16 sum = CheckSum(reader);
	packet.reset(4);packet << sum;
}

UInt32 RTMFP::Unpack(PacketReader& packet) {
	packet.reset();
	UInt32 id=0;
	for(int i=0;i<3;++i)
		id ^= packet.read32();
	packet.reset(4);
	return id;
}

void RTMFP::Pack(PacketWriter& packet,UInt32 farId) {
	PacketReader reader(packet.begin(),packet.length());
	reader.next(4);
	packet.reset(0);
	packet.write32(reader.read32()^reader.read32()^farId);
}

DH* RTMFP::BeginDiffieHellman(UInt8* pubKey) {
	DH*	pDH = DH_new();
	pDH->p = BN_new();
	pDH->g = BN_new();

	BN_set_word(pDH->g, 2); //group DH 2
	BN_bin2bn(g_dh1024p,KEY_SIZE,pDH->p); //prime number
	if(!DH_generate_key(pDH))
		CRITIC("Generation DH key failed!");

	// It's our key public part
	BN_bn2bin(pDH->pub_key,pubKey);
	return pDH;
}

void RTMFP::ComputeDiffieHellmanSecret(DH* pDH,const UInt8* farPubKey,UInt16 farPubKeySize,UInt8* sharedSecret) {
	BIGNUM *bnFarPubKey = BN_bin2bn(farPubKey,farPubKeySize,NULL);
	if(DH_compute_key(sharedSecret, bnFarPubKey,pDH)<=0)
		ERROR("Diffie Hellman exchange failed : dh compute key error");
	BN_free(bnFarPubKey);
}

void RTMFP::EndDiffieHellman(DH* pDH,const UInt8* farPubKey,UInt16 farPubKeySize,UInt8* sharedSecret) {
	ComputeDiffieHellmanSecret(pDH,farPubKey,farPubKeySize,sharedSecret);
	EndDiffieHellman(pDH);
}

void RTMFP::ComputeAsymetricKeys(const UInt8* sharedSecret, const UInt8* initiatorNonce,UInt16 initNonceSize,
														    const UInt8* responderNonce,UInt16 respNonceSize,
														    UInt8* requestKey,UInt8* responseKey) {
	UInt8 mdp1[AES_KEY_SIZE];
	UInt8 mdp2[AES_KEY_SIZE];

	// doing HMAC-SHA256 of one side
	HMAC(EVP_sha256(),responderNonce,respNonceSize,initiatorNonce,initNonceSize,mdp1,NULL);
	// doing HMAC-SHA256 of the other side
	HMAC(EVP_sha256(),initiatorNonce,initNonceSize,responderNonce,respNonceSize,mdp2,NULL);

	// now doing HMAC-sha256 of both result with the shared secret DH key
	HMAC(EVP_sha256(),sharedSecret,KEY_SIZE,mdp1,AES_KEY_SIZE,requestKey,NULL);
	HMAC(EVP_sha256(),sharedSecret,KEY_SIZE,mdp2,AES_KEY_SIZE,responseKey,NULL);
}

UInt16 RTMFP::Time(Timestamp::TimeVal timeVal) {
	return (UInt16)(timeVal/(1000*TIMESTAMP_SCALE));
}




}  // namespace Cumulus

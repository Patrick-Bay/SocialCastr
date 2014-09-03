//
// MultipartReader.h
//
// $Id: //poco/1.4/Net/include/Poco/Net/MultipartReader.h#1 $
//
// Library: Net
// Package: Messages
// Module:  MultipartReader
//
// Definition of the MultipartReader class.
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


#ifndef Net_MultipartReader_INCLUDED
#define Net_MultipartReader_INCLUDED


#include "Poco/Net/Net.h"
#include "Poco/BufferedStreamBuf.h"
#include <istream>


namespace Poco {
namespace Net {


class MessageHeader;


class Net_API MultipartStreamBuf: public Poco::BufferedStreamBuf
	/// This is the streambuf class used for reading from a multipart message stream.
{
public:
	MultipartStreamBuf(std::istream& istr, const std::string& boundary);
	~MultipartStreamBuf();
	bool lastPart() const;
	
protected:
	int readFromDevice(char* buffer, std::streamsize length);

private:
	enum 
	{
		STREAM_BUFFER_SIZE = 1024
	};

	std::istream& _istr;
	std::string   _boundary;
	bool          _lastPart;
};


class Net_API MultipartIOS: public virtual std::ios
	/// The base class for MultipartInputStream.
{
public:
	MultipartIOS(std::istream& istr, const std::string& boundary);
	~MultipartIOS();
	MultipartStreamBuf* rdbuf();
	bool lastPart() const;

protected:
	MultipartStreamBuf _buf;
};


class Net_API MultipartInputStream: public MultipartIOS, public std::istream
	/// This class is for internal use by MultipartReader only.
{
public:
	MultipartInputStream(std::istream& istr, const std::string& boundary);
	~MultipartInputStream();
};



class Net_API MultipartReader
	/// This class is used to split a MIME multipart
	/// message into its single parts.
	///
	/// The format of multipart messages is described
	/// in section 5.1 of RFC 2046.
	///
	/// To split a multipart message into its parts,
	/// do the following:
	///   - Create a MultipartReader object, passing it
	///     an input stream and optionally a boundary string.
	///   - while hasNextPart() returns true, call nextPart()
	///     and read the part from stream().
	///
	/// Always ensure that you read all data from the part
	/// stream, otherwise the MultipartReader will fail to
	/// find the next part.
{
public:
	explicit MultipartReader(std::istream& istr);
		/// Creates the MultipartReader and attaches it to the
		/// given input stream. 
		///
		/// The boundary string is determined from the input
		/// stream. The message must not contain a preamble
		/// preceding the first encapsulation boundary.

	MultipartReader(std::istream& istr, const std::string& boundary);
		/// Creates the MultipartReader and attaches it to the
		/// given input stream. The given boundary string is
		/// used to find message boundaries.

	~MultipartReader();
		/// Destroys the MultipartReader.

	void nextPart(MessageHeader& messageHeader);
		/// Moves to the next part in the message and stores the
		/// part's header fields in messageHeader.
		///
		/// Throws an MultipartException if there are no more parts
		/// available, or if no boundary line can be found in
		/// the input stream.
		
	bool hasNextPart();
		/// Returns true iff more parts are available.
		///
		/// Before the first call to nextPart(), returns
		/// always true.
		
	std::istream& stream() const;
		/// Returns a reference to the reader's stream that
		/// can be used to read the current part.
		///
		/// The returned reference will be valid until
		/// nextPart() is called or the MultipartReader
		/// object is destroyed.

	const std::string& boundary() const;
		/// Returns the multipart boundary used by this reader.

protected:
	void findFirstBoundary();
	void guessBoundary();
	void parseHeader(MessageHeader& messageHeader);
	bool readLine(std::string& line, std::string::size_type n);
	
private:
	MultipartReader();
	MultipartReader(const MultipartReader&);
	MultipartReader& operator = (const MultipartReader&);

	std::istream&         _istr;
	std::string           _boundary;
	MultipartInputStream* _pMPI;
};


} } // namespace Poco::Net


#endif // Net_MultipartReader_INCLUDED

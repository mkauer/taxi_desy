/*
 * ThriftAutoClient.cpp
 *
 *  Created on: Oct 12, 2017
 *      Author: kossatz
 */

#include "ThriftAutoClient.hpp"
#include <thrift/transport/TBufferTransports.h>
#include <thrift/protocol/TBinaryProtocol.h>
#include <iostream>
//#include "glog/logging.h"

using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;

ThriftAutoClientBase::ThriftAutoClientBase(const std::string& endpoint, int port)
: m_endpoint(endpoint), m_port(port), m_isOpened(false),
  m_connTimeout(DEFAULT_THRIFT_CONNECT_TIMEOUT)
{
}

//virtual
ThriftAutoClientBase::~ThriftAutoClientBase()
{
	if (m_transport) m_transport->close();
}


void ThriftAutoClientBase::createConnection()
{
	m_isOpened=false;
	m_socket=boost::shared_ptr<TSocket>(new TSocket(m_endpoint, m_port));

	m_socket->setConnTimeout(m_connTimeout);
	m_socket->setSendTimeout(DEFAULT_THRIFT_SEND_TIMEOUT);
//	m_socket->setRecvTimeout(HESS1U_DEFAULT_THRIFT_RECV_TIMEOUT);
	m_socket->setLinger((DEFAULT_THRIFT_SOCKET_LINGER>0),DEFAULT_THRIFT_SOCKET_LINGER);

	m_transport = boost::shared_ptr<TTransport>(new TBufferedTransport(m_socket));
	m_protocol = boost::shared_ptr<TProtocol>(new TBinaryProtocol(m_transport));
	m_transport->open();
	m_isOpened=true;
}

bool ThriftAutoClientBase::_isConnected()
{
	if (!m_isOpened) return false;
	else {
		bool p=false;
		try {
			p=testConnection();
		} catch(...) {
		}
	  return p && m_socket->isOpen();
    }
}

void ThriftAutoClientBase::checkConnection()
{
  try {
	  if (!_isConnected()) createConnection();
  } catch (TException& tx) {
//	  DVLOG(1) << "Could not connect to " << m_endpoint << ":" << m_port;
	  return;
  }
}

// returns true, if connection is exstablished
bool ThriftAutoClientBase::isConnected()
{
  try {
	  checkConnection();
	  return _isConnected();
  } catch (TException& tx) {
	  return false;
  }
}

boost::shared_ptr<apache::thrift::transport::TSocket>& ThriftAutoClientBase::socket()
{
	checkConnection();
	return m_socket;
}

// return transport instance
boost::shared_ptr<apache::thrift::transport::TTransport>& ThriftAutoClientBase::transport()
{
	checkConnection();
	return m_transport;
}


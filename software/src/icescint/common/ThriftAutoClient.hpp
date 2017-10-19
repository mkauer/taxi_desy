#ifndef SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_SERVER_THRIFTAUTOCLIENT_HPP_
#define SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_SERVER_THRIFTAUTOCLIENT_HPP_

#include <stdexcept>
#include <sstream>
#include <thrift/transport/TSocket.h>
#include <thrift/transport/TTransport.h>
#include <thrift/transport/TBufferTransports.h>
#include <thrift/protocol/TBinaryProtocol.h>
#include <boost/function.hpp>

//#include "thriftSlowControl/gen-cpp/icescint_slowcontrol.h"
//#include "thriftSlowControl/gen-cpp/slowcontrol_types.h"

#define DEFAULT_THRIFT_CONNECT_TIMEOUT 1000
#define DEFAULT_THRIFT_SEND_TIMEOUT 1000
#define DEFAULT_THRIFT_RECV_TIMEOUT 1000
#define DEFAULT_THRIFT_SOCKET_LINGER 100

typedef apache::thrift::transport::TTransportException TTransportException;


#define THRIFT_SAFE_BLOCK( STUFF... ) try { STUFF } catch (TTransportException &e) \
		{ \
			std::cerr << __FUNCTION__ << " throws a transport exception: '" << e.what() << "'"; \
		} catch (std::exception& e) { LOG(WARNING) << __FUNCTION__ << " throws std::exception: '" << e.what() << "'"; }

class ThriftAutoClientBase
{
public:
protected:
	boost::shared_ptr<apache::thrift::transport::TSocket> m_socket;
	boost::shared_ptr<apache::thrift::transport::TTransport> m_transport;
	boost::shared_ptr<apache::thrift::protocol::TProtocol> m_protocol;

	std::string m_endpoint;
	int m_port;
	int m_isOpened;
	bool _isConnected();
	virtual void createConnection();
	virtual bool testConnection() = 0;

	int m_connTimeout;
public:

	void setConnTimeout(int timeout)
	{
		m_connTimeout=timeout;
		if (m_socket) m_socket->setConnTimeout(m_connTimeout);
	}
	const std::string& getEndpoint() const
	{
		return m_endpoint;
	}
	int getPort() const
	{
		return m_port;
	}

	ThriftAutoClientBase(const std::string& endpoint, int port);
	virtual ~ThriftAutoClientBase();

	void checkConnection();

	// returns true, if connection is established
	bool isConnected();

	// return socket instance
	boost::shared_ptr<apache::thrift::transport::TSocket>& socket();
	// return transport instance
	boost::shared_ptr<apache::thrift::transport::TTransport>& transport();

};

// Template class to manage a thrift connection
// With automatic connection recovery
template<class INTERFACE>
class ThriftAutoClient : public ThriftAutoClientBase
{
public:
	typedef boost::function<void (INTERFACE*)> CALLBACK;
private:
	boost::shared_ptr<INTERFACE> m_client;
	CALLBACK m_callBack;
public:
	typedef INTERFACE ClientInterface;

	ThriftAutoClient(const std::string& endpoint, int port, CALLBACK _callBack)
	 : ThriftAutoClientBase(endpoint, port), m_callBack(_callBack)
	{
	}
	ThriftAutoClient(const std::string& endpoint, int port)
	 : ThriftAutoClientBase(endpoint, port)
	{
	}

	virtual void createConnection()
	{
		ThriftAutoClientBase::createConnection();
	    m_client = boost::shared_ptr<INTERFACE> (new INTERFACE(m_protocol));
	}

	virtual bool testConnection()
	{
		if (!m_client) return false;
		if (!m_callBack) return true;
		try {
			// test the connection by calling a interface function
			m_callBack(m_client.get());
			return true;
		} catch(...) {
			return false;
		}
	}

	// returns the interface,
	// if connection is not valid, might throw exceptions
	INTERFACE& interface()
	{
		checkConnection();
		if (!m_client) throw std::runtime_error("client.get(): returns null -> no client instantiated!");
		return *m_client.get();
	}

	inline INTERFACE& slc() { return interface(); }

	typedef boost::shared_ptr< ThriftAutoClient<INTERFACE> > shared_ptr ;

	static shared_ptr create(const std::string& endpoint, int port, CALLBACK _callBack)
	{
		return shared_ptr(new ThriftAutoClient<INTERFACE>(endpoint, port, _callBack));
	}
	static shared_ptr create(const std::string& endpoint, int port)
	{
		return shared_ptr(new ThriftAutoClient<INTERFACE>(endpoint, port));
	}
};

// More Simple Implementation of a Template class to manage a thrift connection
// Without automatic connection recovery
template<class INTERFACE>
class ThriftSimpleClient
{
private:
	boost::shared_ptr<apache::thrift::transport::TSocket> m_socket;
	boost::shared_ptr<apache::thrift::transport::TTransport> m_transport;
	boost::shared_ptr<apache::thrift::protocol::TProtocol> m_protocol;

	std::string m_endpoint;
	int m_port;

	boost::shared_ptr<INTERFACE> m_client;
public:
	typedef INTERFACE ClientInterface;

	ThriftSimpleClient(const std::string& endpoint, int port)
	: m_endpoint(endpoint), m_port(port)
	{
		using namespace apache::thrift;
		using namespace apache::thrift::protocol;
		using namespace apache::thrift::transport;

		m_socket=boost::shared_ptr<TSocket>(new TSocket(m_endpoint, m_port));

		m_socket->setConnTimeout(DEFAULT_THRIFT_CONNECT_TIMEOUT);
		m_socket->setSendTimeout(DEFAULT_THRIFT_SEND_TIMEOUT);
		m_socket->setRecvTimeout(DEFAULT_THRIFT_RECV_TIMEOUT);
		m_socket->setLinger((DEFAULT_THRIFT_SOCKET_LINGER>0),DEFAULT_THRIFT_SOCKET_LINGER);

		m_transport = boost::shared_ptr<TTransport>(new TBufferedTransport(m_socket));
		m_protocol = boost::shared_ptr<TProtocol>(new TBinaryProtocol(m_transport));
	    m_client = boost::shared_ptr<INTERFACE> (new INTERFACE(m_protocol));

		try {
			m_transport->open();
	    } catch (TException& tx) {
	    	// could not open connection
   			//	  DVLOG(1) << "Could not connect to " << m_endpoint << ":" << m_port;
	    	m_transport->close();
	    }
	}

	bool isConnected()
	{
		return m_transport->isOpen();
	}

	inline operator bool() { return isConnected(); }

	~ThriftSimpleClient()
	{
		m_transport->close();
		m_socket->close();
	}

	const std::string& getEndpoint() const
	{
		return m_endpoint;
	}
	int getPort() const
	{
		return m_port;
	}

	// return socket instance
	boost::shared_ptr<apache::thrift::transport::TSocket>& socket()
	{
		return m_socket;
	}
	// return transport instance
	boost::shared_ptr<apache::thrift::transport::TTransport>& transport()
	{
		return m_transport;
	}

	// returns the interface,
	// if connection is not valid, might throw exceptions
	INTERFACE& interface()
	{
		if (!m_client) throw std::runtime_error("client.get(): returns null -> no client instantiated!");
		return *m_client.get();
	}

	inline INTERFACE& slc() { return interface(); }

	typedef boost::shared_ptr< ThriftSimpleClient<INTERFACE> > shared_ptr ;

	static shared_ptr create(const std::string& endpoint, int port)
	{
		return shared_ptr(new ThriftSimpleClient<INTERFACE>(endpoint, port));
	}
};


#endif /* SOURCE_DIRECTORY__TAXI_ICESCINT_ICESCINT_SLOWCONTROL_SERVER_THRIFTAUTOCLIENT_HPP_ */

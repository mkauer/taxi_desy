/*
 * zmq_verbose_socket.hpp
 *
 *  Created on: Dec 3, 2015
 *      Author: marekp
 */

#ifndef ZMQ_VERBOSE_SOCKET_HPP_
#define ZMQ_VERBOSE_SOCKET_HPP_

#include <string>
#include "zmq.hpp"
#include "hess1u/common/signals.hpp"

namespace zmq {

// a socket delegator class for zmq::socket_t that adds verbose output
class verbose_socket_t
{
    socket_t _socket;
    std::string   _name;

    const char* sockoptToString(int option)
    {
    	switch(option)
    	{
    	case ZMQ_LINGER: 	return "linger time";
    	case ZMQ_RCVHWM: 	return "receive hwm";
    	case ZMQ_RCVTIMEO: 	return "receive timeout";
    	case ZMQ_AFFINITY: 	return "affinity";
    	case ZMQ_SNDHWM: 	return "send hwm";
    	case ZMQ_SNDTIMEO: 	return "send timeout";
    	case ZMQ_SUBSCRIBE: return "subscribe filter";
    	case ZMQ_UNSUBSCRIBE: return "unsubscribe";

    	default:
    		return "unknown option";
    	}
    }

public:

    socket_t& socket()
    {
    	return _socket;
    }

    void setName(const char* name_)
    {
    	_name=name_;
    }

    inline verbose_socket_t (zmq::context_t &context_, int type_)
    : _socket(context_, type_), _name("zmqsocket")
    {
    }

//#ifdef ZMQ_HAS_RVALUE_REFS
//    inline socket_t(verbose_socket_t&& rhs) : ptr(rhs.ptr)
//    {
//        rhs.ptr = NULL;
//    }
//    inline socket_t& operator=(socket_t&& rhs)
//    {
//        std::swap(ptr, rhs.ptr);
//        return *this;
//    }
//#endif

    inline operator void* ()
    {
        return (void*)_socket;
    }

    inline void close()
    {
		try {
	    	_socket.close();
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.close()";
			throw;
		}
    }

    inline void setsockopt (int option_, const void *optval_,
        size_t optvallen_)
    {
		try {
	    	_socket.setsockopt(option_, optval_, optvallen_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.setsockopt(" << sockoptToString(option_) << ")";
			throw;
		}
    }

    inline void getsockopt (int option_, void *optval_,
        size_t *optvallen_)
    {
		try {
	    	_socket.getsockopt(option_, optval_, optvallen_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.getsockopt(" << sockoptToString(option_) << ")";
			throw;
		}
    }

    inline void bind (const char *addr_)
    {
		try {
	    	_socket.bind(addr_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.bind(\"" << addr_ << "\")";
			throw;
		}
    }

    inline void unbind (const char *addr_)
    {
		try {
	    	_socket.unbind(addr_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.unbind(\"" << addr_ << "\")";
			throw;
		}
    }

    inline void connect (const char *addr_)
    {
		try {
	    	_socket.connect(addr_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.connect(\"" << addr_ << "\")";
			throw;
		}
    }

    inline void disconnect (const char *addr_)
    {
		try {
	    	_socket.disconnect(addr_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.disconnect(\"" << addr_ << "\")";
			throw;
		}
    }

    inline bool connected()
    {
		try {
	    	return _socket.connected();
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return false;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.connected()";
			throw;
		}
    }

    inline size_t send (const void *buf_, size_t len_, int flags_ = 0)
    {
		try {
	    	return _socket.send(buf_, len_, flags_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return 0;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.send()";
			throw;
		}
    }

    inline bool send (message_t &msg_, int flags_ = 0)
    {
		try {
	    	return _socket.send(msg_, flags_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return 0;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.send()";
			throw;
		}
    }

    inline size_t recv (void *buf_, size_t len_, int flags_ = 0)
    {
		try {
	    	return _socket.recv(buf_, len_, flags_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return 0;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.recv()";
			throw;
		}
    }

    inline bool recv (message_t *msg_, int flags_ = 0)
    {
		try {
	    	return _socket.recv(msg_, flags_);
		} catch(zmq::error_t &e) {
			if (hess1u::signals::isInterrupted()) {
				DVLOG(1) << "received interrupt in " << __FUNCTION__ ;
				return 0;
			}

			LOG(ERROR) << "throws " << e.what() << " on " << _name << " in socket.recv()";
			throw;
		}
    }
};

}

//  Convert string to 0MQ string and send to socket
static bool
s_send (zmq::verbose_socket_t & socket, const std::string & string) {
	return s_send(socket.socket(), string);
}

static std::string
s_recv (zmq::verbose_socket_t & socket) {
    return s_recv(socket.socket());
}




#endif /* ZMQ_VERBOSE_SOCKET_HPP_ */

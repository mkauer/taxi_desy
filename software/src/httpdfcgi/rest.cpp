/*
 * rest.cpp
 *
 *  Created on: Jan 27, 2017
 *      Author: marekp
 */

#include <fstream>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <fastcgi++/request.hpp>
#include <fastcgi++/manager.hpp>
#include "intlk/InterlockSystem.hpp"
#include "hal/hardware/channel/ModuleChannelId.hpp"
#include "hal/hardware/channel/ChannelHelper.hpp"
#include "driver/i4/hal/counterfeature.h"
#include "driver/i4/hal/bus_user.h"
//#include "logging.h"
#include "boost/filesystem.hpp"
#include "hal/hardware/ControllerModule.hpp"

void error_log(const char* msg) {
	using namespace std;
	using namespace boost;
	static ofstream error;
	if (!error.is_open()) {
		error.open("/tmp/errlog", ios_base::out | ios_base::app);
		error.imbue(locale(error.getloc(), new posix_time::time_facet()));
	}
	error << '[' << posix_time::second_clock::local_time() << "] " << msg
			<< endl;
}

class ErrorMsg
{
public:
	std::stringstream buffer;

	typedef boost::shared_ptr<ErrorMsg> ptr;

	static ptr create()
	{
		return ptr(new ErrorMsg());
	}

	~ErrorMsg()
	{
		error_log(buffer.str().c_str());
	}
};

template <class DATA>
ErrorMsg::ptr operator<<(ErrorMsg::ptr _msg, const DATA& _data)
{
	_msg->buffer << _data;
	return _msg;
}

static inline ErrorMsg::ptr log()
{
	return ErrorMsg::create();
}

class GetPutHandler: public Fastcgipp::Request<char> {
	inline void sendError(const std::string& errorMsg) {
		out << "{ \"success\" : 0, \"message\" : \"" + errorMsg + "\" }" << std::endl;
	}
	inline void sendSuccess() {
		out << "{ \"success\" : 1 }" << std::endl;
	}

	void printSignalAttributes(intlk::hw::PChannel ch)
	{
		using namespace intlk;

		intlk::InterlockSystem& intlk = getLocalInterlockSystem();

		hw::Interlock& interlock = intlk.getHardware();

		const intlkdata::Signal* signal = intlk.getSignalById(
				ch->getModuleChannelId());

		out << "\"id\":\"s" << ch->getModuleChannelId().slot() << ".";
		out << (ch->getModuleChannelId().isInput()?"i":"") << (ch->getModuleChannelId().isOutput()?"o":"");
		out << ch->getModuleChannelId().index() << "\",";
		out << "\"s\":\"" << ch->getModuleChannelId().slot() << "\",";
		out << "\"c\":\"" << ch->getModuleChannelId().index() << "\",";
		out << "\"d\":\""
				<< (ch->getModuleChannelId().isInput() ? "in" : "")
				<< (ch->getModuleChannelId().isOutput() ? "out" : "")
				<< "\",";

		out << "\"signalname\":\"";
		if (signal)
			out << signal->signalname();
		else
			"unknown";
		out << "\",";

		out << "\"mask\":\"";
		hw::PInputChannel inp = hw::InputChannel::cast(ch);
		if (inp) {
			out << interlock.getController()->getChannelMask( ch->getModuleChannelId());
		} else {
			out << "";
		}
		out << "\",";

		out << "\"adc\":\"";
		values::PValue val = ch->getValue(hw::ChannelFeature::ADC_VALUE);
		if (val) {
			out << val->get();
		} else {
			out << "";
		}
		out << "\",";

		out << "\"max\":\"";
		val = ch->getValue(hw::ChannelFeature::ADC_MAX);
		if (val) {
			out << val->get();
		} else {
			out << "";
		}
		out << "\",";

		out << "\"min\":\"";
		val = ch->getValue(hw::ChannelFeature::ADC_MIN);
		if (val) {
			out << val->get();
		} else {
			out << "";
		}

		out << "\"";

	}

	bool getHandler() {
		out << "Content-Type: application/json; charset=ISO-8859-1\r\n";
		out << "Access-Control-Allow-Origin: *\r\n\r\n";

		using namespace intlk;

		intlk::InterlockSystem& intlk = getLocalInterlockSystem();

		hw::Interlock& interlock = intlk.getHardware();

		std::vector<hw::PChannel> channelList = interlock.getChannels();

		out << "[";

		int count = 0;
		for (int i = 0; i < channelList.size(); i++) {
			hw::PChannel ch = channelList[i];
			if (!ch)
				continue;

			out << "{";

			printSignalAttributes(ch);

			out << "}";

			if (i < channelList.size() - 1)
				out << ",";
			out << "\n";

		}
		out << "]";

		return true;
	}

	bool putHandler() {
		out << "Content-Type: application/json; charset=ISO-8859-1\r\n";
		out << "Access-Control-Allow-Origin: *\r\n\r\n";

		log() << "get size: " << environment().gets.size();

		log() << "posts size: " << environment().posts.size();

		log() << "data: "<< message().data ;

		std::map<std::string, std::string> parameters;
		for (Fastcgipp::Http::Environment<char>::Posts::const_iterator it =
				environment().posts.begin(); it != environment().posts.end();
				++it) {
			parameters[it->first] = it->second.value;
			log() << "post parameter '" << it->first << "' = " << it->second.value;
		}
		if (parameters.find("id") == parameters.end()) {
			sendError("Missing id");
			log() << "Missing id";
		} else {

			using namespace intlk;
			intlk::hw::ModuleChannelId id;

			intlk::hw::EditModeScope editMode(getLocalInterlockSystem().getHardware()); // Entering Edit Mode
			if (!editMode.isEditModeActive()) {
				sendError("cannot switch to edit mode");
				return true;
			}

			if (!intlk::hw::stringToModuleChannelId(parameters["id"], id)) {
				sendError("given id is bad formed");
				return true;
			}

			log() << "update signal " << parameters["id"];

			if (parameters.find("mask") != parameters.end()) {
				if (parameters["mask"] == "MASKED") {
					log() << "set mask signal " << parameters["id"];
					intlk::getLocalInterlockSystem().getHardware().getController()->setChannelMask(id, intlk::signals::MASK_MASKED);
				} else if (parameters["mask"] == "NOT MASKED") {
					log() << "unmask signal " << parameters["id"];
					intlk::getLocalInterlockSystem().getHardware().getController()->setChannelMask(id, intlk::signals::MASK_NOT_MASKED);
				} else {
					sendError("invalid mask value");
					return true;
				}

			}

			intlk::hw::PChannel ch=intlk::getLocalInterlockSystem().getHardware().getChannel(id);

			if (!ch) {
				sendError("Signal with given id does not exist");
				return true;
			}

			out << "{ \"success\" : 1, ";

			printSignalAttributes(ch);

			out << "}";

		}
		return true;
	}

	bool response() {
		if (environment().requestMethod == Fastcgipp::Http::HTTP_METHOD_PUT) {
			log() << "put method called ";

	//		LOG(INFO) << "put method called!";
			return putHandler();
		}
		if (environment().requestMethod == Fastcgipp::Http::HTTP_METHOD_GET) {
			log() << "get method called ";
	//		LOG(INFO) << "get method called!";
			return getHandler();
		}

	//	LOG(INFO) << "unsupported handler called!";

		out << "Content-Type: application/json; charset=ISO-8859-1\r\n\r\n";
		sendError("request type not supported!");

		return true;
	}
};

int main() {

	i4bus_init(NULL);

//	google::InitGoogleLogging("i4rest.fcgi");
//	google::SetStderrLogging(google::GLOG_FATAL);
//
//	//google::FLAGS_balsologtostderr=0;
//
//	FLAGS_logtostderr=0;
//	FLAGS_alsologtostderr=0;
//
//	fLI::FLAGS_max_log_size=2; // 2mb
//	fLB::FLAGS_stop_logging_if_full_disk=true;


	//intlk::initLogging("i4rest.fcgi");

	try {
		Fastcgipp::Manager<GetPutHandler> fcgi;
		fcgi.handler();
	} catch (std::exception& e) {
		error_log(e.what());
	}
	return 0;
}

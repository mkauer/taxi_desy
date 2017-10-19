#include <fstream>
#include <boost/date_time/posix_time/posix_time.hpp>
#include "boost/filesystem.hpp"

#include <map>

#include <fastcgi++/request.hpp>
#include <fastcgi++/manager.hpp>

#include "hal/smc.h"

#define TAXI_REG_CTRL 		0x00
#define TAXI_REG_DTHR       0x04
#define TAXI_REG_PHVRB  	0x0A
#define TAXI_REG_TRGRT_CTRL  0x12
#define TAXI_REG_TRGRT       0x14
#define TAXI_REG_TRG_CH      0x16
#define TAXI_TSTMP0_ADDR     0x0C
#define TAXI_TSTMP1_ADDR     0x0E
#define TAXI_TSTMP2_ADDR     0x10
#define TAXI_SERDES_PTR_ADDR 0x28
#define TAXI_SERDES_ADDR     0x7e


namespace fs = boost::filesystem;

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

class StatusPage: public Fastcgipp::Request<char> {

	bool response() {
		out << "Content-Type: application/json; charset=ISO-8859-1\r\n";
		out << "Access-Control-Allow-Origin: *\r\n\r\n";

		out << "{" << std::endl;
#define TAXI_REG_CTRL 		0x00
#define TAXI_REG_DTHR       0x04
#define TAXI_REG_PHVRB  	0x0A
#define TAXI_REG_TRGRT_CTRL  0x12
#define TAXI_REG_TRGRT       0x14
#define TAXI_REG_TRG_CH      0x16
#define TAXI_TSTMP0_ADDR     0x0C
#define TAXI_TSTMP1_ADDR     0x0E
#define TAXI_TSTMP2_ADDR     0x10
#define TAXI_SERDES_PTR_ADDR 0x28
#define TAXI_SERDES_ADDR     0x7e

#define JSON_REG(NAME, ADDR) out << ("reg_" NAME  ": ") << IORD_16DIRECT(0, ADDR) << "," << std::endl;

		JSON_REG("ctrl", TAXI_REG_CTRL);
		JSON_REG("dthr", TAXI_REG_DTHR);
		JSON_REG("phvrb", TAXI_REG_PHVRB);
		JSON_REG("trgrt_ctrl", TAXI_REG_TRGRT_CTRL);
		JSON_REG("trgrt", TAXI_REG_TRGRT);
		JSON_REG("trg_ch", TAXI_REG_TRG_CH);
		JSON_REG("tstmp0addr", TAXI_TSTMP0_ADDR);
		JSON_REG("tstmp1addr", TAXI_TSTMP1_ADDR);
		JSON_REG("tstmp2addr", TAXI_TSTMP2_ADDR);
		JSON_REG("serdes_ptr_addr", TAXI_SERDES_PTR_ADDR);
		JSON_REG("serdes_addr", TAXI_SERDES_ADDR);


		out << "}" << std::endl;
		return true;
	}
};

// The main function is easy to set up
int main() {

	smc_driver_error_t err;

	err = smc_open(0);
	if (err!=ERROR_NONE) {
		std::cerr << "cannot open bus driver!" << std::endl;
		return 1;
	}

	try {
		Fastcgipp::Manager<StatusPage> fcgi;
		fcgi.handler();
	} catch (std::exception& e) {
		std::cerr << "exception: " << e.what() << std::endl;
	} catch (...) {
		std::cerr << "unknown exception!" << std::endl;
	}
}

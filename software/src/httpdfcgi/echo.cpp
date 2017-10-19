#include <fstream>
#include <boost/date_time/posix_time/posix_time.hpp>
#include "boost/filesystem.hpp"

#include <map>

#include <fastcgi++/request.hpp>
#include <fastcgi++/manager.hpp>

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

class SessionData {
public:
	std::string username;
	std::string password;
};

typedef Fastcgipp::Http::Sessions<SessionData> Sessions;

class Echo: public Fastcgipp::Request<char> {
	class EWrongPassword: public std::exception {
	public:
		const char* what() const throw () {
			return "Wrong Password";
		}
	};

	static Sessions sessions;
	Sessions::iterator session;
	bool hasSession() {
		return session != sessions.end();
	}

	void initializeSession() {
		using namespace Fastcgipp;
		sessions.cleanup();

		session = sessions.find(environment().findCookie("SESSIONID").data());

		const std::string& command = environment().findGet("command");

		setloc(
				std::locale(getloc(),
						new boost::posix_time::time_facet(
								"%a, %d-%b-%Y %H:%M:%S GMT")));

		if (command == "login") {
			const std::string& username = environment().findGet("username");
			const std::string& password = environment().findGet("password");

			if (username != "admin" && password != "interlock") {
				// Wrong authentification

				out << "Content-Type: text/html; charset=utf-8\r\n";
				out << "\r\n"; // End of HTTP Header

				out << "Wrong Username or Password\r\n";

				throw EWrongPassword();
			}

			SessionData sessionData;
			sessionData.username = username;
			sessionData.password = password;

			session = sessions.generate(sessionData);

			out << "Set-Cookie: SESSIONID=" << encoding(URL) << session->first
					<< encoding(NONE) << "; expires="
					<< sessions.getExpiry(session) << '\n';
			return;
		}

		if (session != sessions.end()) {
			if (command == "logout") {
				out
						<< "Set-Cookie: SESSIONID=deleted; expires=Thu, 01-Jan-1970 00:00:00 GMT;\n";
				sessions.erase(session);
				session = sessions.end();
//				handleNoSession();
			} else {
				session->first.refresh();
				out << "Set-Cookie: SESSIONID=" << encoding(URL)
						<< session->first << encoding(NONE) << "; expires="
						<< sessions.getExpiry(session) << '\n';
				//			handleSession();
			}
		} else {
			//	handleNoSession();
		}
	}

	void printEcho() {
		using namespace Fastcgipp;

		out
				<< "<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />";
		out << "<title>fastcgi++: Echo in UTF-8</title></head><body>";
		out << "<h1>Environment Parameters</h1>";
		out << "<p><b>FastCGI Version:</b> " << Protocol::version << "<br />";
		out << "<b>fastcgi++ Version:</b> " << version << "<br />";
		out << "<b>Hostname:</b> " << encoding(HTML) << environment().host
				<< encoding(NONE) << "<br />";
		out << "<b>User Agent:</b> " << encoding(HTML)
				<< environment().userAgent << encoding(NONE) << "<br />";
		out << "<b>Accepted Content Types:</b> " << encoding(HTML)
				<< environment().acceptContentTypes << encoding(NONE)
				<< "<br />";
		out << "<b>Accepted Languages:</b> " << encoding(HTML)
				<< environment().acceptLanguages << encoding(NONE) << "<br />";
		out << "<b>Accepted Characters Sets:</b> " << encoding(HTML)
				<< environment().acceptCharsets << encoding(NONE) << "<br />";
		out << "<b>Referer:</b> " << encoding(HTML) << environment().referer
				<< encoding(NONE) << "<br />";
		out << "<b>Content Type:</b> " << encoding(HTML)
				<< environment().contentType << encoding(NONE) << "<br />";
		out << "<b>Root:</b> " << encoding(HTML) << environment().root
				<< encoding(NONE) << "<br />";
		out << "<b>Script Name:</b> " << encoding(HTML)
				<< environment().scriptName << encoding(NONE) << "<br />";
		out << "<b>Request URI:</b> " << encoding(HTML)
				<< environment().requestUri << encoding(NONE) << "<br />";
		out << "<b>Request Method:</b> " << encoding(HTML)
				<< environment().requestMethod << encoding(NONE) << "<br />";
		out << "<b>Content Length:</b> " << encoding(HTML)
				<< environment().contentLength << encoding(NONE) << "<br />";
		out << "<b>Keep Alive Time:</b> " << encoding(HTML)
				<< environment().keepAlive << encoding(NONE) << "<br />";
		out << "<b>Server Address:</b> " << encoding(HTML)
				<< environment().serverAddress << encoding(NONE) << "<br />";
		out << "<b>Server Port:</b> " << encoding(HTML)
				<< environment().serverPort << encoding(NONE) << "<br />";
		out << "<b>Client Address:</b> " << encoding(HTML)
				<< environment().remoteAddress << encoding(NONE) << "<br />";
		out << "<b>Client Port:</b> " << encoding(HTML)
				<< environment().remotePort << encoding(NONE) << "<br />";
		out << "<b>If Modified Since:</b> " << encoding(HTML)
				<< environment().ifModifiedSince << encoding(NONE) << "</p>";
		out << "<h1>Path Data</h1>";
		if (environment().pathInfo.size()) {
			std::string preTab;
			for (Http::Environment<char>::PathInfo::const_iterator it =
					environment().pathInfo.begin();
					it != environment().pathInfo.end(); ++it) {
				out << preTab << encoding(HTML) << *it << encoding(NONE)
						<< "<br />";
				preTab += "&nbsp;&nbsp;&nbsp;";
			}
		} else
			out << "<p>No Path Info</p>";
		out << "<h1>GET Data</h1>";
		if (environment().gets.size())
			for (Http::Environment<char>::Gets::const_iterator it =
					environment().gets.begin(); it != environment().gets.end();
					++it)
				out << "<b>" << encoding(HTML) << it->first << encoding(NONE)
						<< ":</b> " << encoding(HTML) << it->second
						<< encoding(NONE) << "<br />";
		else
			out << "<p>No GET data</p>";

		out << "<h1>Cookie Data</h1>";
		if (environment().cookies.size())
			for (Http::Environment<char>::Cookies::const_iterator it =
					environment().cookies.begin();
					it != environment().cookies.end(); ++it)
				out << "<b>" << encoding(HTML) << it->first << encoding(NONE)
						<< ":</b> " << encoding(HTML) << it->second
						<< encoding(NONE) << "<br />";
		else
			out << "<p>No Cookie data</p>";
		out << "<h1>POST Data</h1>";
		if (environment().posts.size()) {
			for (Http::Environment<char>::Posts::const_iterator it =
					environment().posts.begin();
					it != environment().posts.end(); ++it) {
				out << "<h2>" << encoding(HTML) << it->first << encoding(NONE)
						<< "</h2>";
				if (it->second.type == Http::Post<char>::form) {
					out << "<p><b>Type:</b> form data<br />";
					out << "<b>Value:</b> " << encoding(HTML)
							<< it->second.value << encoding(NONE) << "</p>";
				}

				else {
					out << "<p><b>Type:</b> file<br />";
					out << "<b>Filename:</b> " << encoding(HTML)
							<< it->second.filename << encoding(NONE)
							<< "<br />";
					out << "<b>Content Type:</b> " << encoding(HTML)
							<< it->second.contentType << encoding(NONE)
							<< "<br />";
					out << "<b>Size:</b> " << it->second.size() << "<br />";
					out << "<b>Data:</b></p><pre>";
					out.dump(it->second.data(), it->second.size());
					out << "</pre>";
				}
			}
		} else
			out << "<p>No POST data</p>";
		out << "</body></html>";
	}

	bool response() {
		try {
			initializeSession();

			out << "Content-Type: text/html; charset=utf-8\r\n";
			out << "\r\n"; // End of HTTP Header

			printEcho();

/*
			if (!hasSession()) {
				fs::path file = "/opt/taxi/www/signin.html";
				size_t fileSize = fs::file_size(file);

				std::ifstream signinSite(file.string().c_str());
				out.dump(signinSite);

				return true;
			}

			// We have a Session!
			out << "Hello " << session->second.username << "!\r\n"; // End of HTTP Header
*/

		} catch (EWrongPassword& e) {
			// do nothing just exit
		}

	}
};

Sessions Echo::sessions(1200, 1200);

// The main function is easy to set up
int main() {
	try {
		Fastcgipp::Manager<Echo> fcgi;
		fcgi.handler();
	} catch (std::exception& e) {
		std::cerr << "exception: " << e.what() << std::endl;
	} catch (...) {
		std::cerr << "unknown exception!" << std::endl;
	}
}

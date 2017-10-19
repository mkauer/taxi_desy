PRINC := "${@int(PRINC) + 1}"

BOOST_LIBS += "\
	atomic \
	chrono \
	random \
	timer \
	"
BOOST_LIBS += "serialization"
// tool program reboot slaves

#include <iostream>
#include <string>
#include <fstream>
#include <vector>
#include <stdlib.h>
#include <signal.h>

#include <boost/program_options.hpp>

#include "common/SimpleCurses.hpp"
#include "common/CpuLoad.hpp"
#include "common/NetworkStatistic.hpp"


using namespace sc;

void printRow(Table& t, const char* name, float value)
{
	setFg(cyan);
	printf(name);
	t.nextColumn();
	setFg(white);
	printf("%d%%",(int)(100*value));
	t.nextColumn();
	for (int i=0;i<20;i++) {
		if ((i/(float)20)<value) printf("#"); else printf(".");
	}
}
/* This flag controls termination of the main loop. */
volatile sig_atomic_t keep_going = 1;

/* The signal handler just clears the flag and re-enables itself. */
void catch_signal (int sig) {
  keep_going = 0;
}

int main(int argc, char** argv)
{
	using namespace std;


	CpuLoad load;
	NetworkStatistic net;
	load.update(); sleep(1);
	net.update(); sleep(1);
	// catch signals
	struct sigaction sigact;
	sigact.sa_handler = catch_signal;
	sigemptyset(&sigact.sa_mask);
	sigact.sa_flags = 0;
	sigaction(SIGINT, &sigact, NULL);
	sigaction(SIGTERM, &sigact, NULL);
	sigaction(SIGHUP, &sigact, NULL);

	while(keep_going) {
		load.update();
		net.update();
		clear();
		Table t(1,1);
		t.addColumn(7);
		t.addColumn(15);

		t.nextRow(); printRow(t, "user",load.user()/((float)load.total()));
		t.nextRow(); printRow(t, "nice",load.nice()/((float)load.total()));
		t.nextRow(); printRow(t, "system",load.system()/((float)load.total()));
		t.nextRow(); printRow(t, "idle",load.idle()/((float)load.total()));
		t.nextRow(); printRow(t, "iowait",load.iowait()/((float)load.total()));
		t.nextRow(); printRow(t, "irq",load.irq()/((float)load.total()));
		t.nextRow(); printRow(t, "softirq",load.softirq()/((float)load.total()));
		t.nextRow(); printf("net rx %f kb",net.rx_bytes_per_sec() / 1024);
		t.nextRow(); printf("net tx %f kb",net.tx_bytes_per_sec() / 1024);

		printf("\n"); // flush

		sleep(1);
	}


	return 0;
}

/***************************************************************************** 
 * File		  i4_bus_driver.c
 * created on 10.02.2012
 *****************************************************************************
 * Author:	M.Eng. Dipl.-Ing(FH) Marek Penno, EL/1L23, Tel:033762/77275 marekp
 * Email:	marek.penno@desy.de
 * Mail:	DESY, Platanenallee 6, 15738 Zeuthen
 *****************************************************************************
 * Description
 * 
 * Changes:
 *  - Added Support for choosing different bus devices
 *  - Added save close/opening
 *
 * 2013-06-14 MP Bug fix FPGA Error Readback
 *
 ****************************************************************************/

#include "smc.h"

#include <string.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include <stdlib.h>
#include <stdio.h>

#include "smc_ioctl_defines.h"

#define MAGIC 	0xAA55A5FE

typedef struct {
	// file handle
	unsigned int 	magic;
	int 			bus_handle;
} smcbus_driver_t;

static smcbus_driver_t driver_instance;

static int smc_isValid()
{
	return (driver_instance.magic==MAGIC)?1:0;
}

// returns true, if bus is open
int smc_isOpen()
{
	if (!smc_isValid()) return 0;
	if (driver_instance.bus_handle<=0) return 0;
	return 1;
}

// opening the device
smc_driver_error_t smc_open(const char* devname)
{
	if (smc_isOpen()) smc_close();
	memset(&driver_instance,0,sizeof(driver_instance));
	driver_instance.magic=MAGIC;
	smc_driver_error_t status=ERROR_NONE;

	if (!devname) devname=SMCBUS_DEVICE;

	//printf("Opening device '%s'. \n", devname);
	// open io memory device
	driver_instance.bus_handle = open(devname, O_RDWR);
	if(driver_instance.bus_handle < 1) {
		fprintf(stderr,"Error opening device '%s'. Please check, if smc device driver is loaded.\n", devname);
		status=ERROR_OPENING_DEVICE;
		goto error_open_device;
	}

	return ERROR_NONE;

	close(driver_instance.bus_handle);
	driver_instance.bus_handle=0;

	error_open_device:

	return status;
}

// close the device
void smc_close()
{
	if (!smc_isOpen()) return;
	close(driver_instance.bus_handle);
}

// function checks, if bus is open and does halt the program if bus is not open
// --> early fail strategy
void smc_assertIsOpen()
{
	if (smc_isOpen()) return;

	printf("### ERROR ### smc bus device not open! Internal program error!\n");

	exit(1);
}

// reads from smc memory location
unsigned short smc_rd16(unsigned int _addr)
{
	ioctl_smc_rdwr_t cmd;
	cmd.address=_addr;
	int ret = ioctl(driver_instance.bus_handle, IOCTL_SMC_RD16, &cmd);
	if (ret == 0) {
		return cmd.value;
	} else {
		printf("### ERROR ### smc_rd16 error! Internal program error!\n");
		exit(1);

		return 0xDEAF;
	}
}

// reads from smc memory location
unsigned int smc_rd32(unsigned int _addr)
{
	ioctl_smc_rdwr_t cmd;
	cmd.address=_addr;
	int ret = ioctl(driver_instance.bus_handle, IOCTL_SMC_RD32, &cmd);
	if (ret == 0) {
		return cmd.value;
	} else {
		printf("### ERROR ### smc_rd32 error! Internal program error!\n");
		exit(1);

		return 0xDEADBEAF;
	}
}

// writes to smc memory location
void smc_wr16(unsigned int _addr, unsigned short _value)
{
	ioctl_smc_rdwr_t cmd;
	cmd.address=_addr;
	cmd.value=_value;
	int ret = ioctl(driver_instance.bus_handle, IOCTL_SMC_WR16, &cmd);
	if (ret != 0) {
		printf("### ERROR ### smc_wr16 error! Internal program error!\n");
		exit(1);
	}
}

// writes to smc memory location
void smc_wr32(unsigned int _addr, unsigned int _value)
{
	ioctl_smc_rdwr_t cmd;
	cmd.address=_addr;
	cmd.value = _value;
	int ret = ioctl(driver_instance.bus_handle, IOCTL_SMC_WR32, &cmd);
	if (ret != 0) {
		printf("### ERROR ### smc_wr32 error! Internal program error!\n");
		exit(1);
	}
}

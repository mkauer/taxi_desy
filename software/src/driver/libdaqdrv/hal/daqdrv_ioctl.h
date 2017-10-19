/*****************************************************************************
* File		daqdrv_ioctl.h
* created on 14.07.2017
*****************************************************************************
* Author:	M.Eng. Dipl.-Ing(FH) Marek Penno, EL/1L23, Tel:033762/77275
* Email:	marek.penno@desy.de
* Mail:		DESY, Platanenallee 6, 15738 Zeuthen
*****************************************************************************
* Description
*
* IOCTL command definition for the daqdrv kernel driver.
*
* Shared between kernel driver and user support library
*
****************************************************************************/

#ifndef DAQDRV_IOCTL_H_
#define DAQDRV_IOCTL_H_

#include <linux/ioctl.h>

#include "daqdrv_defines.h"

typedef struct
{
	unsigned int timeout_ms; // 1 second has 100 jiffis (on the system used in hess1u) so dont use values < 10
	daqdrv_shared_data_t* hess_data;
} daqdrv_ioctl_wait_for_irq_t;

typedef struct
{
	daqdrv_statistic_t* statistic;
} daqdrv_ioctl_read_statistic_t;

typedef struct
{
	size_t wr_positon;
} daqdrv_ioctl_get_write_position_t;

#define DAQDRV_IOCTL_WAIT_FOR_IRQ 		_IOR('H', 1, daqdrv_ioctl_wait_for_irq_t*)
#define DAQDRV_IOCTL_CLEAR_RING_BUFFER	_IO('H', 9)
#define DAQDRV_IOCTL_READ_STATISTIC		_IOR('H', 7, daqdrv_ioctl_read_statistic_t*)
#define DAQDRV_IOCTL_GET_WR_POSITION	_IOR('H', 8, daqdrv_ioctl_get_write_position_t*)

#endif /* DAQ_IOCTL_H_ */

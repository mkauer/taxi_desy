/*
 * smc_ioctl_defines.h
 *
 *  Created on: Feb 23, 2017
 *      Author: marekp
 */

#ifndef TAXI_KERNELDRIVER_SMC_IOCTL_DEFINES_H_
#define TAXI_KERNELDRIVER_SMC_IOCTL_DEFINES_H_

typedef struct {
	unsigned int address;
	unsigned int value;
} ioctl_smc_rdwr_t;

#define IOCTL_SMC_RD16 _IOR('H', 1, ioctl_smc_rdwr_t)
#define IOCTL_SMC_RD32 _IOR('H', 2, ioctl_smc_rdwr_t)
#define IOCTL_SMC_WR16 _IOW('H', 3, ioctl_smc_rdwr_t)
#define IOCTL_SMC_WR32 _IOW('H', 4, ioctl_smc_rdwr_t)

#endif /* SOURCE_DIRECTORY__TAXI_KERNELDRIVER_SMC_IOCTL_DEFINES_H_ */

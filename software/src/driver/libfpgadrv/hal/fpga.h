/*
 * fpga.hpp
 *
 *  Created on: 24.07.2014
 *      Author: marekp
 */

#ifndef HAL_FPGA_H_
#define HAL_FPGA_H_

#ifdef __cplusplus
	extern "C" {
#endif

// unconfigures the fpga, needed to configure the fpga new
int fpga_unconfigureFirmware(const char* _device=0);

// copyies the file into the fpga device
int fpga_loadFirmware(const char* _firmware, const char* _device=0);

#ifdef __cplusplus
	}
#endif

#endif /* FPGA_H_ */

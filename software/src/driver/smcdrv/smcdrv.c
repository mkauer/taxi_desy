// Kernel Includes
#include <linux/module.h>
#include <linux/vmalloc.h>
#include <linux/delay.h>
#include <linux/kernel.h>
#include <linux/debugfs.h>
#include <linux/init.h>
#include <linux/uaccess.h>
#include <linux/mm.h>
#include <linux/mutex.h>
#include <linux/platform_device.h>
#include <linux/cdev.h>
#include <linux/file.h>
#include <linux/types.h>
#include <linux/fs.h>		/* for struct file_operations */
#include <linux/io.h>		/* ioremap and friends */
#include <linux/version.h>
#include <linux/time.h>
#include <linux/jiffies.h>

// irq handling
#include <linux/interrupt.h>
#include <linux/irqflags.h>
#include <linux/irqreturn.h>
#include <linux/irq.h>
#include <linux/dma-mapping.h>
#include <asm/irq.h>
#include <asm/uaccess.h>

// machine dependend includes
#include <mach/hardware.h>
#include <mach/board.h>
#include <mach/gpio.h>
#include <mach/at91_pio.h>
#include <mach/at91_pmc.h>
#include <mach/at91sam9_smc.h>

//
//#include "stdio.h"
#include "debug.h"
#include "tools.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("desy");
MODULE_DESCRIPTION("driver for the smc bus interface");

#ifdef __CDT_PARSER__
#define __init
#define __exit
#define __user
#endif

// Driver Definitions

#define DRIVER_VERSION 			"Release 0.1"
#define DRIVER_NAME    			"SMC_DRIVER"

// For smc bus device
#define SMC_DEV_NAME 			"smcbus"
#define SMC_DEV_MINOR			0
#define SMC_DEV_MINOR_COUNT 	1

// PIN Definitions
#define TEST_PIN_1				AT91_PIN_PB20	// Test Pin on Test Connector, may have spikes if taskit kernel is used (pin used for r/w led?!)
#define TEST_PIN_2				AT91_PIN_PB21	// Test Pin on Test Connector
#define TEST_PIN_3				AT91_PIN_PB22	// Test Pin on Test Connector
#define TEST_PIN_4				AT91_PIN_PB23	// Test Pin on Test Connector

#include "smcif.h"


// exported driver functions for bus access

// *** Helper Functions for direct SMC bus Access ***
uint32_t smcbusstart()
{
	return SMC_MEM_START;
}
void smcbuswr32(size_t offset, uint32_t data)
{
	// TODO: check offset range
	smc_bus_write32(offset, data);
}
void smcbuswr16(size_t offset, uint16_t data)
{
	smc_bus_write16(offset, data);
}
uint32_t smcbusrd32(size_t offset)
{
	return smc_bus_read32(offset);
}
uint16_t smcbusrd16(size_t offset)
{
	return smc_bus_read16(offset);
}

EXPORT_SYMBOL(smcbusstart);
EXPORT_SYMBOL(smcbuswr32);
EXPORT_SYMBOL(smcbuswr16);
EXPORT_SYMBOL(smcbusrd32);
EXPORT_SYMBOL(smcbusrd16);

//--- pins ---------------------------------------------------------------------
// initialize test pins
static inline void initTestPins(void)
{
	// configure nCOnfig Pin
	at91_set_gpio_output(TEST_PIN_1, 0);
	at91_set_gpio_output(TEST_PIN_2, 0);
	at91_set_gpio_output(TEST_PIN_3, 0);
	at91_set_gpio_output(TEST_PIN_4, 0);
}

typedef struct
{
	dev_t 			devno; // Major Minor Device Number
	struct cdev 	cdev; // Character device
	struct device*	device;
} chrdrv_t;

// Device Structure
typedef struct
{
	chrdrv_t 		chrdrv;
	struct class*	sysfs_class; 	// Sysfs class
	size_t 			offset;
} smc_device_t;

// Static Instance of the complete device
static smc_device_t smc_device_instance;

#include "smc_chardev.h"

// Initialize the Kernel Module
static int __init smcdriver_init(void)
{
	INFO("*** smc driver - version '" DRIVER_VERSION " compiled at " __DATE__ " time:" __TIME__ "' loaded ***\n");

	int err;

	initTestPins();

	err = smc_initialize();
	if (err)
	{
		ERR("error initialzing smc bus interface\n");
		goto err_smc_bus;
	}

	err = smc_chrdrv_create(&smc_device_instance);
	if (err)
	{
		ERR("error initialzing smc char device\n");
		goto err_smc_chrdrv;
	}

	return 0;

err_smc_chrdrv:

	smc_uninitialize();

err_smc_bus:

	return err;
}

// Deinitialize the Kernel Module
static void __exit smcdriver_exit(void)
{
	smc_chrdrv_destroy(&smc_device_instance);

	smc_uninitialize();

	INFO("*** smc driver - version '" DRIVER_VERSION " compiled at " __DATE__ " Time:" __TIME__ "' unloaded ***\n");
}

module_init(smcdriver_init);
module_exit(smcdriver_exit);

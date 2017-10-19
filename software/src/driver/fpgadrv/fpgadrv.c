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

MODULE_LICENSE("GPL");
MODULE_AUTHOR("desy");
MODULE_DESCRIPTION("fpga bitbang firmware loader for altera and xilinx fpga");

#ifdef __CDT_PARSER__
#define __init
#define __exit
#define __user
// add to includes: /var/oe/develop/oe-9g45/openembedded-core/build/tmp-eglibc/work/stamp9g45-angstrom-linux-gnueabi/linux-3.0-r1/linux-3.0/include
// add to includes: /var/oe/develop/oe-9g45/openembedded-core/build/tmp-eglibc/work/stamp9g45-angstrom-linux-gnueabi/linux-3.0-r1/linux-3.0/arch/arm/mach-at91/include
// add to includes: /var/oe/develop/oe-9g45/openembedded-core/build/tmp-eglibc/work/stamp9g45-angstrom-linux-gnueabi/linux-3.0-r1/linux-3.0/arch/arm/include
#endif

#define WRN(fmt...) do { if(printk_ratelimit()) printk(KERN_WARNING " " DRIVER_NAME " "  ": " fmt); } while(0)
#define ERR(fmt...) do { if(printk_ratelimit()) printk(KERN_ERR " " DRIVER_NAME ": " fmt); } while(0)
#define INFO(fmt...) do { printk(KERN_INFO " " DRIVER_NAME ": " fmt); } while(0)
//#define INFO(fmt...) do {} while(0)
#define DBG(fmt...) do { if(printk_ratelimit()) printk(DRIVER_NAME ": " fmt); } while(0)

// Driver Definitions

#define DRIVER_VERSION 			"release 0.2"

#define DRIVER_NAME    			"FPGA_DRIVER"

// For fpga firmware loading device
#define FPGA_DEV_NAME 			"fpga"
#define FPGA_DEV_MINOR			0
#define FPGA_DEV_MINOR_COUNT 	1

//#define PDB_FPGA_nCONFIG	AT91_PIN_PD11

// board id pins to identify hardware board
#define BOARD_ID_PIN0		AT91_PIN_PB24
#define BOARD_ID_PIN1		AT91_PIN_PB25
#define BOARD_ID_PIN2		AT91_PIN_PB26
#define BOARD_ID_PIN3		AT91_PIN_PB27

typedef struct
{
	dev_t devno; 		// Major Minor Device Number
	struct cdev cdev; 	// Character device
	struct device *device;
} chrdrv_t;

// Device Structure
typedef struct
{
	chrdrv_t fpga_driver;

	struct class *sysfs_class; // Sysfs class

} fpga_device_t;

// Static Instance of the complete device
static fpga_device_t fpga_device_instance;

#include "fpga_char_bus.h"

// Initialize the Kernel Module
static int __init fpga_driver_init(void)
{

	INFO("*** fpga driver - version '" DRIVER_VERSION " compiled at " __DATE__ ", " __TIME__ "' loaded ***\n");

	int err;
	err=0;

	fpga_device_t* mydev=&fpga_device_instance;

	memset(mydev,0,sizeof(fpga_device_t));

	INFO("Initialize fpga device\n");

	/* Create sysfs entries - on udev systems this creates the dev files */
	mydev->sysfs_class = class_create(THIS_MODULE, DRIVER_NAME);
	if (IS_ERR(mydev->sysfs_class))
	{
		err = PTR_ERR(mydev->sysfs_class);
		ERR("Error creating fpgadrv class %d.\n", err);
		goto err_sysclass;
	}

	// configure board id pins
	at91_set_gpio_input(BOARD_ID_PIN0, 1); // Activate as input, pull up active
	at91_set_gpio_input(BOARD_ID_PIN1, 1); // Activate as input, pull up active
	at91_set_gpio_input(BOARD_ID_PIN2, 1); // Activate as input, pull up active
	at91_set_gpio_input(BOARD_ID_PIN3, 1); // Activate as input, pull up active

	// configure nCOnfig Pin
	at91_set_gpio_output(FPGA_nCONFIG, 1); // Activate as Output and set level to VCC

	msleep(10); // ## ??

	err = fpga_chrdrv_create(mydev->sysfs_class, &mydev->fpga_driver);
	if (err)
	{
		ERR("error initialzing fpga char device\n");
		goto err_fpga_drv;
	}

err_fpga_drv:

	return err;

err_sysclass:

	return err;
}

// Deinitialize the Kernel Module
static void __exit fpga_driver_exit(void)
{
	fpga_chrdrv_destroy(fpga_device_instance.sysfs_class, &fpga_device_instance.fpga_driver);

	class_destroy(fpga_device_instance.sysfs_class);

	INFO("*** fpga driver - version '" DRIVER_VERSION " compiled at " __DATE__ ", " __TIME__ "' unloaded ***\n");
}

module_init(fpga_driver_init);
module_exit(fpga_driver_exit);

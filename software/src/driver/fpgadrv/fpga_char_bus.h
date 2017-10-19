#ifndef FPGA_CHRDRV_H_
#define FPGA_CHRDRV_H_

#include <linux/mm.h>
#include <linux/version.h>
// ----------------------------------- Character Device Driver Interface ------------------

#define FPGA_TYPE_Spartan_6
//#define FPGA_TYPE_Cyclone_IV
//#define FPGA_TYPE_Stratix_III

#define FPGA_SPI_PIN_OUT 2 // 1=="prototype v1"; 2=="prototype v2"

#if FPGA_SPI_PIN_OUT == 1
 #define FPGA_PROGRAMMING_TEXT "SPI pin out for hess1u 8 channel prototype v1!"
 #define FPGA_CONFIG_DONE			AT91_PIN_PB20 // shared with TEST_PIN_1
 #define FPGA_CLK					AT91_PIN_PB21 // shared with TEST_PIN_2
 #define FPGA_MOSI					AT91_PIN_PB22 // shared with TEST_PIN_3
 #define FPGA_nSTATUS				AT91_PIN_PB23 // shared with TEST_PIN_4
 #define FPGA_nCONFIG				AT91_PIN_PD11

#elif FPGA_SPI_PIN_OUT == 2
 #define FPGA_PROGRAMMING_TEXT "SPI pin out hess1u"
 #define FPGA_CONFIG_DONE			AT91_PIN_PB3
 #define FPGA_CLK					AT91_PIN_PB2
 #define FPGA_MOSI					AT91_PIN_PB1
 #define FPGA_nSTATUS				AT91_PIN_PD25
 #define FPGA_nCONFIG				AT91_PIN_PD28
#endif

#if defined(FPGA_TYPE_Cyclone_IV)
 #define TCFG_US 		1	// hat to be >500ns
 #define TCF2ST0_US		1	// needs 0 - 500ns
 #define TSTATUS_US		240	// needs 45 - 230us
 #define TST2CK_US		5	// hat to be >2us
 #define MSB_FIRST		0
#endif
#if defined(FPGA_TYPE_Spartan_6)
 #define TCFG_US 		1	// hat to be >500ns
 #define TCF2ST0_US		1	// needs 0 - 500ns
 #define TSTATUS_US		240	// needs 45 - 230us
 #define TST2CK_US		5	// hat to be >2us
 #define MSB_FIRST		1
#endif
#if defined(FPGA_TYPE_Stratix_III)
 #define TCFG_US 		5	// hat to be >2us
 #define TCF2ST0_US		2	// needs 0 - 800ns
 #define TSTATUS_US		110	// needs 10 - 100us
 #define TST2CK_US		5	// hat to be >2us
 #define MSB_FIRST		0
#endif
// Char Driver Implementation

inline void send0(void)
{
	at91_set_gpio_value(FPGA_CLK,0); 	// clear bit
	at91_set_gpio_value(FPGA_MOSI,0); // clear bit
	at91_set_gpio_value(FPGA_CLK,1); 	// set bit
}
inline void send1(void)
{
	at91_set_gpio_value(FPGA_CLK,0);	// clear bit
	at91_set_gpio_value(FPGA_MOSI,1);	// set bit
	at91_set_gpio_value(FPGA_CLK,1);	// set bit
}

void fpga_stopReconfiguration(void)
{
	send0();
	send0();
	send0();
}

void fpga_startReconfiguration(void)
{
	at91_set_gpio_value(FPGA_nCONFIG,0);	// clear bit
	udelay(TCFG_US);
	at91_set_gpio_value(FPGA_nCONFIG,1);	// set bit

	udelay(TSTATUS_US);
	if(at91_get_gpio_value(FPGA_nSTATUS) == 1)
	{
		INFO("nStatus needs less than %d us\n", TSTATUS_US);
	}
	else
	{
		ERR("nStatus needs more than %d us\n", TSTATUS_US);
	}
	udelay(TST2CK_US);
}

static size_t fpga_writeBytes(const void* src, size_t size)
{
	uint8_t* _src = (uint8_t*) src;
	size_t i = 0;

	if(MSB_FIRST == 0)
	{
		for (i = 0; i < size; i++)
		{
			((*_src) & (1<<0)) ? send1() : send0();
			((*_src) & (1<<1)) ? send1() : send0();
			((*_src) & (1<<2)) ? send1() : send0();
			((*_src) & (1<<3)) ? send1() : send0();
			((*_src) & (1<<4)) ? send1() : send0();
			((*_src) & (1<<5)) ? send1() : send0();
			((*_src) & (1<<6)) ? send1() : send0();
			((*_src) & (1<<7)) ? send1() : send0();

			_src++;
		}
	}
	else
	{
		for (i = 0; i < size; i++)
		{
			((*_src) & (1<<7)) ? send1() : send0();
			((*_src) & (1<<6)) ? send1() : send0();
			((*_src) & (1<<5)) ? send1() : send0();
			((*_src) & (1<<4)) ? send1() : send0();
			((*_src) & (1<<3)) ? send1() : send0();
			((*_src) & (1<<2)) ? send1() : send0();
			((*_src) & (1<<1)) ? send1() : send0();
			((*_src) & (1<<0)) ? send1() : send0();

			_src++;
		}
	}

	return i;
}

#define COPY_BUF_SIZE 128 // r

static size_t fpga_copyFromUserToFpga(const void* _usrSrc, size_t _size)
{
	unsigned char buf[COPY_BUF_SIZE]; // local buffer, using stack allocation to be thread safe
	unsigned char* usrSrc = (unsigned char*) _usrSrc;
	size_t bytesToBeCopied = _size;
	size_t bytesCopied = 0;
	size_t blockSize = 0;

	while (bytesToBeCopied)
	{
		if (bytesToBeCopied > COPY_BUF_SIZE)
		{
			blockSize = COPY_BUF_SIZE;
		}
		else
		{
			blockSize = bytesToBeCopied;
		}

		if (copy_from_user(buf, usrSrc, blockSize))
		{
			DBG("copy_from_user_to_fpga: write was not completed\n");
			return -EFAULT;
		}

		size_t bytesWritten = fpga_writeBytes(buf, blockSize);
//		DBG("%d bytes written... %d left\n",bytesWritten, _size-bytesWritten);
		bytesCopied += bytesWritten;

		usrSrc += bytesWritten;
		bytesToBeCopied -= bytesWritten;
	}

//	DBG("%d bytes written at this write call...\n",bytesCopied);
	return bytesCopied;
}

static int fpga_chrdrv_open(struct inode * node, struct file *f)
{
	DBG("fpga_bus_open\n");
//	hess1u_device_t* dev;

//	dev = container_of(node->i_cdev, hess1u_device_t, fpga_driver.cdev);
//	f->private_data = dev;

	at91_set_gpio_output(FPGA_nCONFIG, 0);
	at91_set_gpio_input(FPGA_nSTATUS, 0);
	at91_set_gpio_output(FPGA_CLK, 0);
	at91_set_gpio_output(FPGA_MOSI, 0);
	at91_set_gpio_input(FPGA_CONFIG_DONE, 0);

	fpga_startReconfiguration();

	return 0;
}

static int fpga_chrdrv_release(struct inode *node, struct file *f)
{
	fpga_stopReconfiguration();

	at91_set_gpio_output(FPGA_MOSI,0);
	at91_set_gpio_output(FPGA_CLK,0);

	mdelay(200); // wait for fpga to boot and irq pin to stop toggle

	DBG("fpga_bus_release\n");
	return 0;
}

static ssize_t fpga_chrdrv_write(struct file *f, const char __user *_buf, size_t _size, loff_t *_offs)
{
	ssize_t retVal = 0;
//	hess1u_device_t* dev = f->private_data;

	// lock the resource
//	if (down_interruptible(&dev->sem)) return -ERESTART;

	retVal = fpga_copyFromUserToFpga(_buf, _size);

	if (retVal<0)
	{
		// fault occured, write was not completed
		DBG("fault occured, write was not completed\n");
		goto out;
	}

	if(retVal != _size)
	{
		DBG("retVal != _size\n");
	}

	*_offs+=retVal;

	out:
//	up(&dev->sem); // free the resource

	return retVal;
}

static loff_t fpga_chrdrv_llseek(struct file *f, loff_t offs, int whence)
{
	DBG("fpga_chrdrv_llseek not implemented");
	return 0;
}

typedef struct
{
	int usage_count;
} fpga_private_data_t;

// **************************************** Character Device Instance Definiton

// Char Driver File Operations
static struct file_operations fpga_user_fops =
	{	.open = fpga_chrdrv_open, // handle opening the file-node
		.release = fpga_chrdrv_release, // handle closing the file-node
//		.read = fpga_chrdrv_read, // handle reading
		.write = fpga_chrdrv_write, // handle writing
		.llseek = fpga_chrdrv_llseek, // handle seeking in the file
//		.unlocked_ioctl = fpga_chrdrv_ioctl, // handle special i/o operations
		};

// Initialization of the Character Device
static int fpga_chrdrv_create(struct class *_sysfs_class, chrdrv_t* _device)
{
	int err = 0;
	char name[30];
	chrdrv_t* chrdrv = _device;

	INFO("install device for fpga programming\n");
	if (!_sysfs_class || !_device)
	{
		ERR("Null pointer argument(s)!\n");
		goto err_dev;
	}

	/* Allocate major and minor numbers for the driver */
	err = alloc_chrdev_region(&chrdrv->devno, FPGA_DEV_MINOR, FPGA_DEV_MINOR_COUNT, FPGA_DEV_NAME);
	if (err)
	{
		ERR("Error allocating Major Number for driver.\n");
		goto err_region;
	}

	DBG("Major Number: %d\n", MAJOR(chrdrv->devno));

	/* Register the driver as a char device */
	cdev_init(&chrdrv->cdev, &fpga_user_fops);
	chrdrv->cdev.owner = THIS_MODULE;
//	DBG("char device allocated 0x%x\n",(unsigned int)chrdrv->cdev);
	err = cdev_add(&chrdrv->cdev, chrdrv->devno, FPGA_DEV_MINOR_COUNT);
	if (err)
	{
		ERR("cdev_all failed\n");
		goto err_char;
	}
	DBG("Char device added\n");
	DBG(FPGA_PROGRAMMING_TEXT);

	sprintf(name, "%s0", FPGA_DEV_NAME);

	// create devices
	chrdrv->device = device_create(_sysfs_class, NULL, MKDEV(MAJOR(chrdrv->devno), 0), NULL, name, 0);

	if (IS_ERR(chrdrv->device))
	{
		ERR("fpga_driver: Error creating sysfs device\n");
		err = PTR_ERR(chrdrv->device);
		goto err_class;
	}

	return 0;

	err_class: cdev_del(&chrdrv->cdev);
	err_char: unregister_chrdev_region(chrdrv->devno, FPGA_DEV_MINOR_COUNT);
	err_region:

	err_dev: return err;
}

// Initialization of the Character Device
static void fpga_chrdrv_destroy(struct class *_sysfs_class, chrdrv_t* _device)
{
	chrdrv_t* chrdrv = _device;
	device_destroy(_sysfs_class, MKDEV(MAJOR(chrdrv->devno), 0));

	/* Unregister device driver */
	cdev_del(&chrdrv->cdev);

	/* Unregiser the major and minor device numbers */
	unregister_chrdev_region(chrdrv->devno, FPGA_DEV_MINOR_COUNT);
}

#endif /* FPGA_CHRDRV_H_ */

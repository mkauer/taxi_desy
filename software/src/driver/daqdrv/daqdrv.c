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

#include "debug.h"
#include "tools.h"
#include "smcbus.h"
#include "dma.h"

#include "daqdrv_ioctl.h"

//#include "hess1u/common/hal/types.h"
//#include "hess1u/common/hal/bits.h"
//#include "hess1u/common/hal/bus.h"
//#include "hess1u/common/hal/offsets.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("desy");
MODULE_DESCRIPTION("daq driver");

enum _DMA_TYPES_{ _NO_DMA_ = 0, _DMA_ = 1 };
static int s_nDMAtype  = _DMA_;

enum _STATS_TYPES_{ _NO_STATS_ = 0, _MIN_STATS_ = 1, _FULL_STATS_ = 2 };
static int param_stats = _NO_STATS_;

static int test_data = 0;

static int dma_buffer_count 		= 48;
static int dma_chunk_size  			= 18*4096*15; // nice 1mb chunks, IF aligned to 18 bytes (event size)
static int dma_buffer_size_total_mb	= 50;

module_param_named(dma,   s_nDMAtype, int, S_IRUGO | S_IWUSR);
module_param_named(stats, param_stats, int, S_IRUGO | S_IWUSR);
module_param_named(testdata, test_data, int, S_IRUGO | S_IWUSR);

module_param_named(dma_buffer_count, dma_buffer_count, int, S_IRUGO | S_IWUSR);
module_param_named(dma_chunk_size,  dma_chunk_size,  int, S_IRUGO | S_IWUSR);
module_param_named(dma_buffer_size_total_mb,  dma_buffer_size_total_mb,  int, S_IRUGO | S_IWUSR);

#ifdef __CDT_PARSER__
#define __init
#define __exit
#define __user
// add to includes: /var/oe/develop/oe-9g45/openembedded-core/build/tmp-eglibc/work/stamp9g45-angstrom-linux-gnueabi/linux-3.0-r1/linux-3.0/include
// add to includes: /var/oe/develop/oe-9g45/openembedded-core/build/tmp-eglibc/work/stamp9g45-angstrom-linux-gnueabi/linux-3.0-r1/linux-3.0/arch/arm/mach-at91/include
// add to includes: /var/oe/develop/oe-9g45/openembedded-core/build/tmp-eglibc/work/stamp9g45-angstrom-linux-gnueabi/linux-3.0-r1/linux-3.0/arch/arm/include
#endif

// Driver Definitions

#define DRIVER_VERSION 			"Release 0.1"

#define DRIVER_NAME    			"DAQ_DRIVER"

// For DAQ IRQ Device
#define DAQ_DEV_NAME 			"daqdrv"
#define DAQ_DEV_MINOR			0
#define DAQ_DEV_MINOR_COUNT 	1

#define DAQ_IRQ_PIN				AT91_PIN_PC1
#define DAQ_IRQ_PIN_NUMBER 		(1 << 1) // pc1
// Further Definitions

#define FPGA_EVENTCOUNTER_MAX 65535

// Control Source code Options
#define TEST_CODE 				0		// Activate Test Code, if set to 0, should never be used with productive release
#define TEST_IRQ				0		// if 1, IRQ TEst Functions are active
#define IRQ_ENABLED				1		// set to 1 to activate IRQ functionality

#define DAQ_DEVICE_ENABLED		1		// if 1, DAQ Device is enabled
#define DEBUGFS_ENABLED			1		// if 1, debugfs is enabled


//--- pins ---------------------------------------------------------------------

typedef struct
{
	dev_t devno; 		// Major Minor Device Number
	struct cdev cdev; 	// Character device
	struct device *device;
} chrdrv_t;

// Device Structure
typedef struct
{
	chrdrv_t daq_driver;

	struct class *sysfs_class; // Sysfs class

	struct semaphore sem;
	size_t offset;
} daq_device_t;

// Static Instance of the complete device
static daq_device_t daq_device_instance;

//--- daq ---------------------------------------------------------------------
//-----------------------------------------------------------------------------
//#include "hess1u/common/hal/commands.h"
#include "daq_irq.h"

// ----------------------------------- Character Device Driver Interface ------------------

// Char Driver Implementation
typedef struct
{
	int usage_count;
	daqfifo_device_t* irqDevice;
} daq_private_data_t;

static daq_private_data_t g_daq_private_data =
{
	.usage_count = 0,
	.irqDevice = &daqfifo_instance
};

static int daq_chrdrv_open(struct inode * node, struct file *f)
{
	daq_device_t* dev;

	dev = container_of(node->i_cdev, daq_device_t, daq_driver.cdev);
	f->private_data = dev;

	return 0;
}

static int daq_chrdrv_release(struct inode *node, struct file *f)
{
	return 0;
}

/*
static ssize_t daq_chrdrv_read(struct file *f, char __user *buf, size_t size, loff_t *offs)
{
	ssize_t retVal = 0;

	daq_device_t* dev = f->private_data;
	unsigned int myoffs = dev->offset;

	//	DBG("daq user_read offs: 0x%p + 0x%x + 0x%x = 0x%x size:%d\n",dev->mappedIOMem, dev->offset, (int)*offs, myoffs, size);

	// lock the resource
	if (down_interruptible(&dev->sem)) { return -ERESTART; }

	// Check File Size
	if ((myoffs) >= SMC_MEM_LEN) { goto out; }

	// Limit Count
	if ((myoffs + size) >= SMC_MEM_LEN) { size = SMC_MEM_LEN - myoffs; }

	retVal = copy_from_io_to_user_16bit(buf, VOID_PTR(smc_bus_virt_base_address, myoffs), size);

	if (retVal<0) { goto out; }

	*offs += retVal; // Is this realy needed?

out:
	up(&dev->sem); // free the resource

	return retVal;
}

static ssize_t daq_chrdrv_write(struct file *f, const char __user *buf, size_t size, loff_t *offs)
{
	ssize_t retVal = 0;
	daq_device_t* dev = f->private_data;

	unsigned int myoffs = dev->offset;

	// lock the resource
	if (down_interruptible(&dev->sem)) { return -ERESTART; }

	// Check File Size
	//        if ((myoffs + dev->offset) >= dev->IOMemSize) goto out;
	if ((myoffs) >= SMC_MEM_LEN) { goto out; }

	// Limit Count
	if ((myoffs + size) >= SMC_MEM_LEN) size = SMC_MEM_LEN - myoffs;

	retVal = copy_from_user_to_io_16bit(VOID_PTR(smc_bus_virt_base_address, myoffs), buf, size);
	if (retVal<0) { goto out; } // fault occured, write was not completed

	*offs += retVal;

out:
	up(&dev->sem);// free the resource

	return retVal;
}

static loff_t daq_chrdrv_llseek(struct file *f, loff_t offs, int whence)
{
	daq_device_t* dev = f->private_data;
	unsigned int myoffs = offs;
	//	DBG("daq user_llseek offs: 0x%x  whence: %d\n", myoffs, whence);
	switch (whence)
	{
	case SEEK_SET:
		if (offs >= (SMC_MEM_LEN))
		{
			// out of range seeking
			return -1;
		}
		dev->offset = offs;
		return offs;
		break;

	case SEEK_CUR:
		if ((dev->offset + offs) >= (SMC_MEM_LEN))
		{
			// out of range seeking
			return -1;
		}
		dev->offset += offs;
		return dev->offset;
		break;

	case SEEK_END:
		if ((dev->offset) >= (SMC_MEM_LEN))
		{
			// out of range seeking
			return -1;
		}
		dev->offset = SMC_MEM_LEN - myoffs;
		return dev->offset;
		break;

	default:
		return -EINVAL;
	}

	return 0;
}*/

//--- mmap -------------------------------------------------------------------------
static void daq_vma_open(struct vm_area_struct *vma)
{
	daq_private_data_t* data = vma->vm_private_data;
	data->usage_count++;
}

static void daq_vma_close(struct vm_area_struct *vma)
{
	daq_private_data_t* data = vma->vm_private_data;
	data->usage_count--;
}

static struct vm_operations_struct daq_remap_vm_ops =
{
	.open = daq_vma_open,
	.close = daq_vma_close,
	//.fault = daq_vma_fault,
};

static int daq_chrdrv_mmap(struct file *f, struct vm_area_struct *vma)
{
	unsigned long size = vma->vm_end - vma->vm_start;
//	printk(KERN_INFO "remap_pfn_range pgoffs:%d size: %u \n", vma->vm_pgoff, size);

	vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);

	if (!daqfifo_instance.shared_data) {
		printk(KERN_ERR "remap_pfn_range failed, daq data not allocated yet\n");
		return -EIO;
	}

	if (vma->vm_pgoff==0) {
		//size = size > sizeof(hess_ring_buffer_t) ? sizeof(hess_ring_buffer_t) : size;
		// if memory is kmalloc allocated

		// io_remap_pfn_range
		if (io_remap_pfn_range(vma, vma->vm_start, virt_to_phys((void *)daqfifo_instance.shared_data) >> PAGE_SHIFT, size, vma->vm_page_prot) < 0)
		{
			printk(KERN_ERR "remap_pfn_range failed\n");
			return -EIO;
		}

//		printk(KERN_INFO "magic: 0x%x\n", g_srqDevice.hess_data->magic);

	} else {
		if ((vma->vm_pgoff*PAGE_SIZE) % daqfifo_instance.shared_data->mmap_chunk_span !=0 ) {
			printk(KERN_ERR "map request to buffer chunk must be aligned to mmap_chunk_span!\n");
			return -EIO;
		}
		int chunkIndex=((vma->vm_pgoff*PAGE_SIZE) / daqfifo_instance.shared_data->mmap_chunk_span) - 1;

		if (chunkIndex<0) {
			printk(KERN_ERR "map request to buffer chunk must start at 1*mmap_chunk_span!\n");
			return -EIO;
		}

		if (chunkIndex>=daqfifo_instance.shared_data->chunkCount) {
			printk(KERN_ERR "map request to buffer chunk must be below chunkCount*mmap_chunk_span!\n");
			return -EIO;
		}

		if (size>daqfifo_instance.shared_data->mmap_chunk_span) {
			printk(KERN_ERR "map request size to buffer chunk must be exactly mmap_chunk_span!\n");
			return -EIO;
		}

		if (io_remap_pfn_range(vma, vma->vm_start, virt_to_phys((void *)daqfifo_instance.m_chunks[chunkIndex].data) >> PAGE_SHIFT, size, vma->vm_page_prot) < 0)
		{
			printk(KERN_ERR "remap_pfn_range failed\n");
			return -EIO;
		}

		// ring buffer chunk mapped successfull
	}

//	if (s_nDMAtype==_NO_DMA_) {
//		// if memory is kmalloc allocated
//		if (remap_pfn_range(vma, vma->vm_start, virt_to_phys((void *)g_srqDevice.hess_data) >> PAGE_SHIFT, size, vma->vm_page_prot) < 0)
//		{
//			printk(KERN_ERR "remap_pfn_range failed\n");
//			return -EIO;
//		}
//	} else {
//		// if memory is dma coherrent allocated memory
//		if (remap_pfn_range(vma, vma->vm_start, vmalloc_to_pfn((void *)daqfifo_instance.hess_data) , size, vma->vm_page_prot) < 0)
//		{
//			printk(KERN_ERR "remap_pfn_range dma memory failed\n");
//			return -EIO;
//		}
//	}

	vma->vm_private_data = &g_daq_private_data;
	vma->vm_ops = &daq_remap_vm_ops;
	daq_vma_open(vma);

	return 0;
}

//--- mmap end -------------------------------------------------------------------------

// ----------------------------------- IOCTL Interface ---------------------
static int daq_ioctl_cmd_wait_for_irq(unsigned long arg) // ## name
{
	daqdrv_ioctl_wait_for_irq_t cmd;

	//DBG("ioctl wait for irq command\n");

	if (copy_from_user(&cmd, (daqdrv_ioctl_wait_for_irq_t*)arg, sizeof(daqdrv_ioctl_wait_for_irq_t)))
	{
		ERR("error copying data from userspace");
		return -EACCES;
	}

	//DBG( " timeout %d ms == %d jiffis (1 secound has %d jiffis)\n", cmd.timeout_ms, cmd.timeout_ms * HZ / 1000, HZ);

	// wait for the irq
	uint32_t lastCount = daqfifo_readIrqCount();

	// recalculate timeout into jiffis

	//    setTestPin(1,0);
	//    wait_event(srqDevice.waitQueue, (lastCount!=srqDevice.irq_count));
	int result = wait_event_interruptible_timeout(daqfifo_instance.waitQueue, (lastCount != daqfifo_instance.statistic.total_irq_count), cmd.timeout_ms * HZ / 1000);
	if (result == -ERESTARTSYS)
	{
		// System wants to shutdown, so we just exit
		return -ERESTARTSYS;
	}
	if (result == 0)
	{
		//        setTestPin(1,1);
		// Timeout occured, we just return to user process
		return -ETIMEDOUT;
	}
	//    setTestPin(1,1);

	return 0; // ## warum nicht result?
}

static int daq_ioctl_cmd_read_statistic(unsigned long arg) // ## name
{
	if (copy_to_user((void*)arg, &daqfifo_instance.statistic, sizeof(daqdrv_statistic_t)))
	{
		ERR("error copying data to userspace");
		return -EACCES;
	}

	return sizeof(daqdrv_statistic_t); // ## warum nicht result?
}

static int daq_ioctl_cmd_get_wr_position(void) // ## name
{
	return daqfifo_instance.shared_data->wrOffs;
}


#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 33)
static int daq_ioctl(struct inode *node, struct file *f, unsigned int cmd, unsigned long arg)
#else
static long daq_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
#endif
{
	switch (cmd)
	{
	case DAQDRV_IOCTL_WAIT_FOR_IRQ:
		return daq_ioctl_cmd_wait_for_irq(arg);
	case DAQDRV_IOCTL_READ_STATISTIC:
		return daq_ioctl_cmd_read_statistic(arg);
	case DAQDRV_IOCTL_CLEAR_RING_BUFFER:
		daqfifo_clear_ring_buffer();
		return 0;
	case DAQDRV_IOCTL_GET_WR_POSITION:
		return daq_ioctl_cmd_get_wr_position();
	default:
		ERR("invalid smc ioctl cmd: %d\n", cmd);
		return -EFAULT;
	}
	return 0;
}
//-----------------------------------------------------------------------------
//--- daq end -----------------------------------------------------------------

// **************************************** Character Device Instance Definiton

// Char Driver File Operations
static struct file_operations daq_chrdrv_fops = {
		.open = daq_chrdrv_open, // handle opening the file-node
		.release = daq_chrdrv_release, // handle closing the file-node
//		.read = daq_chrdrv_read, // handle reading
//		.write = daq_chrdrv_write, // handle writing
//		.llseek = daq_chrdrv_llseek, // handle seeking in the file
		.unlocked_ioctl = daq_ioctl, // handle special i/o operations
		.mmap = daq_chrdrv_mmap
};

// Initialization of the Character Device
static int daq_chrdrv_create(daq_device_t* mydev)
{
	int err = -1;
	char name[30];
	chrdrv_t* chrdrv = &mydev->daq_driver;

	INFO("install daq character device\n");
	if (!mydev)
	{
		ERR("Null pointer argument!\n");
		goto err_dev;
	}

	/* Create sysfs entries - on udev systems this creates the dev files */
	mydev->sysfs_class = class_create(THIS_MODULE, DRIVER_NAME);
	if (IS_ERR(mydev->sysfs_class))
	{
		err = PTR_ERR(mydev->sysfs_class);
		ERR("Error creating device class %d.\n", err);
		goto err_sysclass;
	}

	/* Allocate major and minor numbers for the driver */
	err = alloc_chrdev_region(&chrdrv->devno, DAQ_DEV_MINOR, DAQ_DEV_MINOR_COUNT, DAQ_DEV_NAME);
	if (err)
	{
		ERR("Error allocating Major Number for daq driver.\n");
		goto err_region;
	}

	DBG("Major Number: %d\n", MAJOR(chrdrv->devno));

	/* Register the driver as a char device */
	cdev_init(&chrdrv->cdev, &daq_chrdrv_fops);
	chrdrv->cdev.owner = THIS_MODULE;
	DBG("char device allocated 0x%x\n", (unsigned int)&chrdrv->cdev);
	err = cdev_add(&chrdrv->cdev, chrdrv->devno, DAQ_DEV_MINOR_COUNT);
	if (err)
	{
		ERR("cdev_all failed\n");
		goto err_char;
	}
	DBG("Char device added\n");

	sprintf(name, "%s0", DAQ_DEV_NAME);

	// create devices
	chrdrv->device = device_create(mydev->sysfs_class, NULL, MKDEV(MAJOR(chrdrv->devno), 0), NULL, name, 0);

	if (IS_ERR(chrdrv->device))
	{
		ERR("%s: Error creating sysfs device\n", name);
		err = PTR_ERR(chrdrv->device);
		goto err_class;
	}

//	hess1u_system_enum daq_device_type = hess1u_smi_getSystemType();
//	DBG("first check hess1u_device_type == %s\n", hess1u_smi_getSystemTypeAsString(hess1u_device_type));

	return 0;

err_class:
	cdev_del(&chrdrv->cdev);
err_char:
	unregister_chrdev_region(chrdrv->devno, DAQ_DEV_MINOR_COUNT);
err_region:

	class_destroy(mydev->sysfs_class);

err_sysclass:

err_dev :

	return err;
}

// Initialization of the Character Device
static void daq_chrdrv_destroy(daq_device_t* mydev)
{
	chrdrv_t* chrdrv = &mydev->daq_driver;
	device_destroy(mydev->sysfs_class, MKDEV(MAJOR(chrdrv->devno), 0));

	/* Unregister device driver */
	cdev_del(&chrdrv->cdev);

	/* Unregiser the major and minor device numbers */
	unregister_chrdev_region(chrdrv->devno, DAQ_DEV_MINOR_COUNT);

	class_destroy(mydev->sysfs_class);
}

// ************************************************  SRQ IRQ Handler Code

#if TEST_CODE==1

// some debug helper code...
static void dumpPio(size_t pio)
{
#define DUMP(NAME, REG) INFO(#REG "\t= 0x%.8x  " NAME "\n", at91_sys_read(pio + REG));
	DUMP("Status Register", PIO_PSR);
	DUMP("Output Status Register", PIO_OSR);
	DUMP("Glitch Input Filter Status", PIO_IFSR);
	DUMP("Output Data Status Register", PIO_ODSR);
	DUMP("Pin Data Status Register", PIO_PDSR);
	DUMP("Interrupt Mask Register", PIO_IMR);
	DUMP("Interrupt Status Register", PIO_ISR);

	DUMP("Multi-driver Status Register", PIO_MDSR);
	DUMP("Pull-up Status Register", PIO_PUSR);

	DUMP("AB Status Register", PIO_ABSR);
	DUMP("Output Write Status Register", PIO_OWSR);
#undef DUMP
}

#endif

#if DEBUGFS_ENABLED==1
	#include "debugfs.h"
#endif

// Initialize the Kernel Module
static int __init daq_init(void)
{
	int ret = 0;

	INFO("*** daq driver - version '" DRIVER_VERSION " compiled at " __DATE__ " time:" __TIME__ "' loaded ***\n");

#if TEST_CODE==1
	WRN("Test Code Activated! DO NOT USE THIS DRIVER with a productive system\n");
#endif

#if DEBUGFS_ENABLED==1
	ret = daqdrv_debugfs_init();
	if (ret) goto err_debugfs;
#endif

#if DAQ_DEVICE_ENABLED==1
	ret = daq_chrdrv_create(&daq_device_instance);
	if (ret)
	{
		ERR("error initialzing daq char device\n");
		goto err_daq_chrdrv;
	}

  #if IRQ_ENABLED==1
	ret=daqfifo_initialize();
	if (ret)
	{
		ERR("could not install irq handler\n.");
		goto err_daq_irq_init;
	}
  #endif // IRQ_ENABLED

#endif // DAQ_DEVICE_ENABLED

	return 0;

#if IRQ_ENABLED==1
	daqfifo_deinitialize();
#endif // IRQ_ENABLED

err_daq_irq_init:

	daq_chrdrv_destroy(&daq_device_instance);

err_daq_chrdrv:

#if DEBUGFS_ENABLED==1
	daqdrv_debugfs_remove(); // removing the directory recursively which in turn cleans all the files
#endif

err_debugfs:

	return ret;
}

// Deinitialize the Kernel Module
static void __exit daq_exit(void)
{
#if DEBUGFS_ENABLED==1
	daqdrv_debugfs_remove(); // removing the directory recursively which in turn cleans all the files
#endif

#if	DAQ_DEVICE_ENABLED==1

#if IRQ_ENABLED==1
	daqfifo_deinitialize();
#endif

	daq_chrdrv_destroy(&daq_device_instance);
#endif

	INFO("*** daq driver - version '" DRIVER_VERSION " compiled at " __DATE__ " Time:" __TIME__ "' unloaded ***\n");
}

module_init(daq_init);
module_exit(daq_exit);

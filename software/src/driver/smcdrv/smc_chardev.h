/***************************************************************************** 
 * File		  smc_chrdrv.h
 * created on 09.02.2012
 *****************************************************************************
 * Author:	M.Eng. Dipl.-Ing(FH) Marek Penno, EL/1L23, Tel:033762/77275 marekp
 * Email:	marek.penno@desy.de
 * Mail:	DESY, Platanenallee 6, 15738 Zeuthen
 *****************************************************************************
 * Description
 * 
 ****************************************************************************/

#ifndef SMC_CHRDRV_H_
#define SMC_CHRDRV_H_

#include <linux/mm.h>
#include <linux/version.h>

#include "smc_ioctl_defines.h"


// ----------------------------------- Character Device Driver Interface ------------------

// Char Driver Implementation
static int smc_chrdrv_open(struct inode * node, struct file *f)
{
	smc_device_t* dev;

	dev = container_of(node->i_cdev, smc_device_t, 	chrdrv.cdev);
	f->private_data = dev;

	return 0;
}

static int smc_chrdrv_release(struct inode *node, struct file *f)
{
	return 0;
}

typedef struct
{
	int usage_count;
	smc_device_t* mydev;
} smc_private_data_t;


#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35))
static int smc_chrdrv_ioctl(struct inode *node, struct file *f, unsigned int cmd, unsigned long arg)
#else
static long smc_chrdrv_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
#endif
{
	//intlk_dev_t* dev=f->private_data;
	switch (cmd)
	{
	case IOCTL_SMC_RD16:
		{
			ioctl_smc_rdwr_t cmd;

			if (copy_from_user(&cmd, (void*)arg, sizeof(ioctl_smc_rdwr_t)))
			{
				// fault occured, read was not completed
				return -EFAULT;
			}

			// Limit Size
			if ((cmd.address + 2) >= SMC_MEM_LEN ) return -EFAULT;

			// perform io read
			cmd.value = smc_bus_read16(cmd.address);

			if (copy_to_user((void*)arg,&cmd,sizeof(ioctl_smc_rdwr_t))) {
				// fault occured, read was not completed
				return -EFAULT;
			}

			return 0;
		}
	case IOCTL_SMC_RD32:
		{
			ioctl_smc_rdwr_t cmd;

			if (copy_from_user(&cmd, (void*)arg, sizeof(ioctl_smc_rdwr_t)))
			{
				// fault occured, read was not completed
				return -EFAULT;
			}

			// Limit Size
			if ((cmd.address + 4) >= SMC_MEM_LEN ) return -EFAULT;

			// perform io read
			cmd.value = smc_bus_read32(cmd.address);

			if (copy_to_user((void*)arg,&cmd,sizeof(ioctl_smc_rdwr_t))) {
				// fault occured, read was not completed
				return -EFAULT;
			}

			return 0;
		}
	case IOCTL_SMC_WR16:
		{
			ioctl_smc_rdwr_t cmd;

			if (copy_from_user(&cmd, (void*)arg, sizeof(ioctl_smc_rdwr_t)))
			{
				// fault occured, read was not completed
				return -EFAULT;
			}

			// Limit Size
			if ((cmd.address + 2) >= SMC_MEM_LEN ) return -EFAULT;

			// perform io write
			smc_bus_write16(cmd.address, cmd.value);

			return 0;
		}

	case IOCTL_SMC_WR32:
		{
			ioctl_smc_rdwr_t cmd;

			if (copy_from_user(&cmd, (void*)arg, sizeof(ioctl_smc_rdwr_t)))
			{
				// fault occured, read was not completed
				return -EFAULT;
			}

			// Limit Size
			if ((cmd.address + 4) >= SMC_MEM_LEN ) return -EFAULT;

			// perform io write
			smc_bus_write32(cmd.address, cmd.value);

			return 0;
		}

	default:
		ERR("invalid ioctl cmd: %d\n", cmd);
		return -EFAULT;
	}
	return 0;
}

// **************************************** Character Device Instance Definiton

// Char Driver File Operations
static struct file_operations smc_user_fops =
	{
		.open = smc_chrdrv_open, // handle opening the file-node
		.release = smc_chrdrv_release, // handle closing the file-node
		.unlocked_ioctl = smc_chrdrv_ioctl, // handle special i/o operations
//        .mmap = smc_chrdrv_mmap
		};


//static int hess_smc_create(smc_device_t* mydev)
//{
//	int err;
//
//	INFO("Initialize SMC\n");
//
//	/* Create sysfs entries - on udev systems this creates the dev files */
//	mydev->sysfs_class = class_create(THIS_MODULE, DRIVER_NAME);
//	if (IS_ERR(mydev->sysfs_class))
//	{
//		err = PTR_ERR(mydev->sysfs_class);
//		ERR("Error creating hessdrv class %d.\n", err);
//		goto err_sysclass;
//	}
//
//	msleep(100); // ## wait for pullups to charge pin
//
//	err=smc_initialize();
//	if (err) {
//		// error initializing smc interface
//		goto err_smc_init;
//	}
//
//	msleep(10); // ## ??
//
//	return 0;
//
//err_smc_init:
//
//	class_destroy(mydev->sysfs_class);
//
//err_sysclass:
//
//	return err;
//}
// Initialization of the Character Device
static int smc_chrdrv_create(smc_device_t* mydev)
{
	int err = 0;
	char name[30];

	if (!mydev)
	{
		ERR("Null pointer argument!\n");
		return 0; // TODO: return correct error code here
	}

	chrdrv_t* chrdrv = &mydev->chrdrv;

	INFO("Install Character Device\n");

	/* Create sysfs entries - on udev systems this creates the dev files */
	mydev->sysfs_class = class_create(THIS_MODULE, DRIVER_NAME);
	if (IS_ERR(mydev->sysfs_class))
	{
		err = PTR_ERR(mydev->sysfs_class);
		ERR("Error creating driver class %d.\n", err);
		goto err_sysclass;
	}

	/* Allocate major and minor numbers for the driver */
	err = alloc_chrdev_region(&chrdrv->devno, SMC_DEV_MINOR, SMC_DEV_MINOR_COUNT, SMC_DEV_NAME);
	if (err)
	{
		ERR("Error allocating Major Number for driver.\n");
		goto err_region;
	}

	DBG("Major Number: %d\n", MAJOR(chrdrv->devno));

	/* Register the driver as a char device */
	cdev_init(&chrdrv->cdev, &smc_user_fops);
	chrdrv->cdev.owner = THIS_MODULE;
//	DBG("char device allocated 0x%x\n",(unsigned int)chrdrv->cdev);
	err = cdev_add(&chrdrv->cdev, chrdrv->devno, SMC_DEV_MINOR_COUNT);
	if (err)
	{
		ERR("cdev_all failed\n");
		goto err_char;
	}
	DBG("Char device added\n");

	sprintf(name, "%s0", SMC_DEV_NAME);

	// create devices
	chrdrv->device = device_create(mydev->sysfs_class, NULL, MKDEV(MAJOR(chrdrv->devno), 0), NULL, name, 0);

	if (IS_ERR(chrdrv->device))
	{
		ERR("%s: Error creating sysfs device\n", DRIVER_NAME);
		err = PTR_ERR(chrdrv->device);
		goto err_class;
	}

	return 0;

	err_class:
		cdev_del(&chrdrv->cdev);

	err_char:
		unregister_chrdev_region(chrdrv->devno, SMC_DEV_MINOR_COUNT);

	err_region:


	class_destroy(mydev->sysfs_class);

	err_sysclass:

	return err;
}

// Initialization of the Character Device
static void smc_chrdrv_destroy(smc_device_t* mydev)
{
	chrdrv_t* chrdrv = &mydev->chrdrv;
	device_destroy(mydev->sysfs_class, MKDEV(MAJOR(chrdrv->devno), 0));

	/* Unregister device driver */
	cdev_del(&chrdrv->cdev);

	/* Unregiser the major and minor device numbers */
	unregister_chrdev_region(chrdrv->devno, SMC_DEV_MINOR_COUNT);

	class_destroy(mydev->sysfs_class);
}

#endif /* SMC_CHRDRV_H_ */

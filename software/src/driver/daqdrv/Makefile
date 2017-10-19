EXTRA_CFLAGS += -Wno-declaration-after-statement -O3 -g
#EXTRA_CFLAGS += -DIS_KERNEL_SOURCE=1 -I . -I ${EXTRA_INCLUDES}
EXTRA_CFLAGS += -DIS_KERNEL_SOURCE=1 -I${EXTRA_INCLUDES} 
EXTRA_CFLAGS += -Wno-declaration-after-statement -O3 -g -DIS_KERNEL_SOURCE=1 -DARCH_AT91SAM -I . -I ${INCLUDE_HAL}

obj-m += daqdrv.o
#MODULES	= hessdrv
ARCH = arm
KERNEL_SOURCE = ${OE_ROOT}/tmp-eglibc/work/stamp9g45-oe-linux-gnueabi/linux/3.0-r2/linux-3.0/
ARMCROSS =  ${OE_ROOT}/tmp-eglibc/sysroots/x86_64-linux/usr/bin/armv5te-oe-linux-gnueabi/arm-oe-linux-gnueabi-


default:	all

BUILD	= $(MODULES:%=%.ko)

all::
	$(MAKE) -C $(KERNEL_SOURCE) ARCH=$(ARCH) CROSS_COMPILE=$(ARMCROSS) modules M=$(PWD)

clean::
	rm -f $(BUILD) *.o *.ko *.mod.c *.mod.o *~ .*.cmd Module.symvers
	rm -rf .tmp_versions
	$(MAKE) -C $(KERNEL_SOURCE) ARCH=$(ARCH) CROSS_COMPILE=$(ARMCROSS) clean
	#make -C $(KERNEL_SOURCE) M=$(PWD) clean

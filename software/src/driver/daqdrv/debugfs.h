#define DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH 2000

struct dentry *dirret;
struct dentry *fileret;
struct dentry *u64int;
struct dentry *u64hex;

char ker_buf[DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH];
int filevalue;
u64 intvalue;
u64 hexvalue;

static ssize_t debug_stats_read(struct file *fp, char __user *user_buffer, size_t count, loff_t *position)
{
	daqfifo_device_t* dev = &daqfifo_instance; //g_(daqfifo_device_t*)a_data;

	long diff_mHz;
	if( dev->statistic.diff_us > 0) {diff_mHz = 1000000000 / dev->statistic.diff_us;}
	else {diff_mHz = 0;}

	long triggerRate_mHz;
	if( dev->statistic.triggerRate > 0) {triggerRate_mHz = 1000000000 / dev->statistic.triggerRate;}
	else {triggerRate_mHz = 0;}

//	long unsigned trigger_counter = smc_bus_read16(BASE_HESS1U_DRAWER_READOUT+OFFS_HESS1U_DRAWER_READOUT_TRIGGERACCEPTCOUNTERHIGH)*65536 + smc_bus_read16(BASE_HESS1U_DRAWER_READOUT+OFFS_HESS1U_DRAWER_READOUT_TRIGGERACCEPTCOUNTERLOW);
//	u16 resetTime = smc_bus_read16(OFFS_HESS1U_DRAWER_READOUT_TRIGGERACCEPTCOUNTERRESETTIME);
//	long unsigned rate_scale = 0;
	long unsigned irq_rate_mHz = 0;
	long unsigned irq_rate_us = 0;
	long unsigned irq_rate_Hz = 0;
	long unsigned averagingTime = 0;

//	if(resetTime > 0)
//	{
//		rate_scale = HESS1U_DRAWER_READOUT_TRIGGERCOUNTERRESETTIMESEC*1000 / resetTime;
//		if (rate_scale > 0)
//		{
//			averagingTime = 1000000 / rate_scale;
//			irq_rate_mHz = trigger_counter * rate_scale;
//			if(irq_rate_mHz > 0)
//			{
//				irq_rate_us = 1000000000 / irq_rate_mHz;
//				irq_rate_Hz = irq_rate_mHz / 1000;
//			}
//		}
//	}

	size_t len = 0;
	len += sprintf(ker_buf + len, "buffer size:              %u\n", (dev->shared_data)?dev->shared_data->bufferSize:0);
	len += sprintf(ker_buf + len, "buffer chunks:            %u * %ubytes\n", (dev->shared_data)?dev->shared_data->chunkCount:0, dev->shared_data?dev->shared_data->chunkSize:0);
	len += sprintf(ker_buf + len, "buffer wr pos:            %u\n", dev->shared_data?dev->shared_data->wrOffs:0);
	len += sprintf(ker_buf + len, "buffer wr pos:            [");
	if (dev->shared_data) {
		int i=0;
		int width=40;
		int wrpos=0;
		wrpos=width*dev->shared_data->wrOffs/dev->shared_data->bufferSize;
		for (i=0;i<width;i++) {
			len += sprintf(ker_buf + len, (i==wrpos)?"w":".");
		}
		len += sprintf(ker_buf + len, "]\n");
	} else {
		len += sprintf(ker_buf + len, "no buffer allocated\n");
	}

	len += sprintf(ker_buf + len, "irq rate:                 %luus == %lu,%03luHz\n", dev->statistic.diff_us, diff_mHz/1000, diff_mHz%1000);
	len += sprintf(ker_buf + len, "trigger rate software:    %luus == %lu,%03luHz\n", dev->statistic.triggerRate, triggerRate_mHz/1000, triggerRate_mHz%1000);
	len += sprintf(ker_buf + len, "trigger rate hardware:    %luus == %lu,%03luHz (avg@%lums)\n", irq_rate_us, irq_rate_Hz, irq_rate_mHz%1000, averagingTime);
	len += sprintf(ker_buf + len, "irq_count:                %u\n", dev->statistic.total_irq_count);
	len += sprintf(ker_buf + len, "irq period:               %u\n", dev->statistic.irq_period);
	len += sprintf(ker_buf + len, "irq idle:                 %u\n", dev->statistic.irq_period-dev->statistic.irq_duration);

	len += sprintf(ker_buf + len, "fifo max words:           %u\n", dev->statistic.max_fifo_count);
	len += sprintf(ker_buf + len, "fifo words on irq:        %u\n", dev->statistic.fifo_count);
	len += sprintf(ker_buf + len, "fifo empty on irq:        %u\n", dev->statistic.fifo_empty);
//	len += sprintf(ker_buf + len, "fifo words now:           %u\n", smc_bus_read16( BASE_HESS1U_DRAWER_READOUT + OFFS_HESS1U_DRAWER_READOUT_EVENTFIFOWORDCOUNT));
	len += sprintf(ker_buf + len, "fifo words after copy:    %u\n", dev->statistic.fifo_count_after_copy);
//	len += sprintf(ker_buf + len, "fifo full counter:        %u\n", smc_bus_read16( BASE_HESS1U_DRAWER_READOUT + OFFS_HESS1U_DRAWER_READOUT_FIFOFULLCOUNT ));

	len += sprintf(ker_buf + len, "irq duration              %uus\n", dev->statistic.irq_duration);
	len += sprintf(ker_buf + len, "copy start                %uus\n", dev->statistic.irq_duration_copy_start);
	len += sprintf(ker_buf + len, "copy data                 %uus\n", dev->statistic.irq_duration_copy);
	len += sprintf(ker_buf + len, "copy duration per word    %uns\n", (dev->statistic.fifo_count>0)?(dev->statistic.irq_duration_copy*1000)/dev->statistic.fifo_count:99999);

	if (s_nDMAtype  == _NO_DMA_) {
		len += sprintf(ker_buf + len, "eventcounter mismatches:  %u \t%u +1 != %u\n", dev->statistic.eventcounter_mismatch, dev->statistic.eventcounter_mismatch_old, dev->statistic.eventcounter_mismatch_new);
		len += sprintf(ker_buf + len, "current eventcounter:     %u\n", dev->statistic.eventcounter);
		len += sprintf(ker_buf + len, "samples 0:                %u\n", dev->statistic.samples_0);
		len += sprintf(ker_buf + len, "samples 16:               %u\n", dev->statistic.samples_16);
		len += sprintf(ker_buf + len, "samples 32:               %u\n", dev->statistic.samples_32);
		len += sprintf(ker_buf + len, "samples other:            %u\n", dev->statistic.samples_other);
		len += sprintf(ker_buf + len, "last frame length was:    %u\n", dev->statistic.frame_length);
		len += sprintf(ker_buf + len, "unknown_type:             %u\n", dev->statistic.unknown_type);
	}
	else {
		len += sprintf(ker_buf + len, "dma errors                %u\n", dev->statistic.dma_errors);
	}

	len += sprintf(ker_buf + len, "\nchars left:~%u\n", DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH-len-20);

	;

	if(len > DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH)
	{
		sprintf(ker_buf, "DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH exceeded\n\n");
		ERR("DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH exceeded\n");
	}

	return simple_read_from_buffer(user_buffer, count, position, ker_buf, min((size_t)DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH,len));
}

static ssize_t debug_stats_write(struct file *fp, const char __user *user_buffer, size_t count, loff_t *position)
{
	if(count > DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH )
	return -EINVAL;

	return simple_write_to_buffer(ker_buf, DAQDRV_DEBUG_KERNEL_BUFFER_LENGTH, position, user_buffer, count);
}

static const struct file_operations fops_debug_stats =
{
	.read = debug_stats_read,
	.write = debug_stats_write,
};

static int daqdrv_debugfs_init(void)
{
	//printk("\n\nhess_debugfs_init()\n\n");
	dirret = debugfs_create_dir("daqdrv", NULL); // create a directory by the name dell in /sys/kernel/debugfs
	fileret = debugfs_create_file("stats", 0644, dirret, &filevalue, &fops_debug_stats);// create a file in the above directory This requires read and write file operations
	if (!fileret)
	{
		printk("error creating stats file");
		return (-ENODEV);
	}

	u64int = debugfs_create_u64("number", 0644, dirret, &intvalue);// create a file which takes in a int(64) value
	if (!u64int)
	{
		printk("error creating int file");
		return (-ENODEV);
	}

	u64hex = debugfs_create_x64("hexnum", 0644, dirret, &hexvalue ); // takes a hex decimal value
	if (!u64hex)
	{
		printk("error creating hex file");
		return (-ENODEV);
	}

	return 0;
}

static void daqdrv_debugfs_remove(void)
{
	debugfs_remove_recursive(dirret);
}

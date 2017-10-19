/*
 * smcif.h
 *
 *  Created on: Jul 8, 2016
 *      Author: marekp
 */

#ifndef KERNEL_SMC_DRIVER_SMCIF_H_
#define KERNEL_SMC_DRIVER_SMCIF_H_

#define SMC_BUS_CHIPSELECT	2 // which chip select line should get the timing
// SMC_BUS Timing Setup
#define SMC_BUS_SETUP		2 // Bus Cycle Setup Time
#define SMC_BUS_PULSE		5 // Bus Cycle Pulse Time
#define SMC_BUS_CYCLE		(SMC_BUS_SETUP + SMC_BUS_PULSE + 2) // Bus Cycle Length
#define SMC_BUS_SETUP_CS	1
#define SMC_BUS_PULSE_CS	6

#define IOMEM_NAME "smcbusiomem"

#define SMC_MEM_START		AT91_CHIPSELECT_2 	// 0x30000000	// physical address region of the controlbus bus mapping *is fixed!*
#define SMC_MEM_LEN			0x4000000 			// 64M

#define VOID_PTR(PTR, OFFS) ((void*)(((char*)(PTR)) + (OFFS)))

// smc base address in virtual memory
static void* smc_bus_virt_base_address = 0;
// allocated smc bus region
struct resource *smc_bus_iomemregion   = 0;

// *** Helper Functions for direct SMC bus Access ***
static inline void smc_bus_write32(size_t offset, uint32_t data)
{
	iowrite16(data, VOID_PTR(smc_bus_virt_base_address, offset));
	iowrite16(data >> 16, VOID_PTR(smc_bus_virt_base_address, offset + 2));
}
static inline void smc_bus_write16(size_t offset, uint16_t data)
{
	iowrite16(data, VOID_PTR(smc_bus_virt_base_address, offset));
}
static inline uint32_t smc_bus_read32(size_t offset)
{
	return (uint32_t) ioread16(VOID_PTR(smc_bus_virt_base_address, offset)) |
		   (uint32_t)(ioread16(VOID_PTR(smc_bus_virt_base_address, offset + 2)) << 16); // ## in der hoffnung ioread16() gibt mindestens 32 bit zurueck
}
static inline uint16_t smc_bus_read16(size_t offset)
{
	return ioread16(VOID_PTR(smc_bus_virt_base_address, offset));
}

struct smc_config
{
	// Setup register
	uint8_t ncs_read_setup;
	uint8_t nrd_setup;
	uint8_t ncs_write_setup;
	uint8_t nwe_setup;

	// Pulse register
	uint8_t ncs_read_pulse;
	uint8_t nrd_pulse;
	uint8_t ncs_write_pulse;
	uint8_t nwe_pulse;

	// Cycle register
	uint16_t read_cycle;
	uint16_t write_cycle;

	// Mode register
	uint32_t mode;
	uint8_t tdf_cycles : 4;
};

// Apply the timing to the SMC
static void smc_setup_timings(void)
{
	struct smc_config config = {
		// Setup register
		.ncs_read_setup = 2, //SMC_BUS_SETUP_CS,
		.nrd_setup = 2, //SMC_BUS_SETUP,
		.ncs_write_setup = SMC_BUS_SETUP_CS,
		.nwe_setup = SMC_BUS_SETUP,

		// Pulse register
		.ncs_read_pulse = 8, //SMC_BUS_PULSE_CS,
		.nrd_pulse = 8, //SMC_BUS_PULSE,
		.ncs_write_pulse = SMC_BUS_PULSE_CS,
		.nwe_pulse = SMC_BUS_PULSE,

		// Cycle register
		.read_cycle = 8 + 2, //SMC_BUS_CYCLE,
		.write_cycle = SMC_BUS_CYCLE,

		// Mode register
		.mode = AT91_SMC_READMODE | AT91_SMC_WRITEMODE | AT91_SMC_BAT_SELECT | AT91_SMC_DBW_16 | AT91_SMC_EXNWMODE_READY,
		.tdf_cycles = 0
	};

	int cs = SMC_BUS_CHIPSELECT;

	// Setup register
	at91_sys_write(AT91_SMC_SETUP(cs),
		AT91_SMC_NWESETUP_(config.nwe_setup) |
		AT91_SMC_NCS_WRSETUP_(config.ncs_write_setup) |
		AT91_SMC_NRDSETUP_(config.nrd_setup) |
		AT91_SMC_NCS_RDSETUP_(config.ncs_read_setup)
	);

	// Pulse register
	at91_sys_write(AT91_SMC_PULSE(cs),
			AT91_SMC_NWEPULSE_(config.nwe_pulse) |
			AT91_SMC_NCS_WRPULSE_(config.ncs_write_pulse) |
			AT91_SMC_NRDPULSE_(config.nrd_pulse) |
			AT91_SMC_NCS_RDPULSE_(config.ncs_read_pulse)
	);

	// Cycle register
	at91_sys_write(AT91_SMC_CYCLE(cs),
			AT91_SMC_NWECYCLE_(config.write_cycle) |
			AT91_SMC_NRDCYCLE_(config.read_cycle)
	);

	// Mode register
	at91_sys_write(AT91_SMC_MODE(cs),
			config.mode |
			AT91_SMC_TDF_(config.tdf_cycles)
	);

	INFO("SMC Bus Timing: chipselect=%u tdf_cycles=%u mode=0x%x\n   "
		" read: cycle=%u setup=%u pulse=%u cs_setup=%u sc_pulse=%u\n   "
		"write: cycle=%u setup=%u pulse=%u cs_setup=%u sc_pulse=%u\n",
		SMC_BUS_CHIPSELECT, config.tdf_cycles, config.mode,
		config.read_cycle, config.nrd_setup, config.nrd_pulse,
		config.ncs_read_setup, config.ncs_read_pulse, config.write_cycle,
		config.nwe_setup, config.nwe_pulse, config.ncs_write_setup,
		config.ncs_write_pulse);

}

// initialize the smc bus interface
int smc_initialize(void)
{
	// Request Memory Region
	smc_bus_iomemregion = request_mem_region(SMC_MEM_START, SMC_MEM_LEN, IOMEM_NAME);
	if (!smc_bus_iomemregion)
	{
		ERR("could not request io-mem region for smc bus\n.");
		goto err_memregion;
	}

	// Request remap of Memory Region
	smc_bus_virt_base_address = ioremap_nocache(SMC_MEM_START, SMC_MEM_LEN);
	if (!smc_bus_virt_base_address)
	{
		ERR("could not remap io-mem region for smc bus\n.");
		goto err_ioremap;
	}

	// activate smc chip select NCS
	//	at91_set_gpio_output(AT91_PIN_PC11, 1); // Activate as Output
	//	at91_set_B_periph(AT91_PIN_PC11, 0);    // Disable SPI0 CS Function
	//	at91_set_A_periph(AT91_PIN_PC11, 1);    // Activate NCS2 Function
	at91_set_A_periph(AT91_PIN_PC13, 1); // Activate NCS2 Function

	at91_set_A_periph(AT91_PIN_PC2, 1); // Activate A19
	at91_set_A_periph(AT91_PIN_PC3, 1); // Activate A20
	at91_set_A_periph(AT91_PIN_PC4, 1); // Activate A21
	at91_set_A_periph(AT91_PIN_PC5, 1); // Activate A22
	at91_set_A_periph(AT91_PIN_PC6, 1); // Activate A23
	at91_set_A_periph(AT91_PIN_PC7, 1); // Activate A24
	at91_set_A_periph(AT91_PIN_PC12, 1); // Activate A25

	// setup the smc timing
	smc_setup_timings();

	return 0; // success

	err_ioremap:
		release_mem_region(SMC_MEM_START, SMC_MEM_LEN);
		smc_bus_iomemregion = 0;

	err_memregion:

	return 1; // error
}

// uninitializes the smc bus interface
static void smc_uninitialize(void)
{
	if (smc_bus_virt_base_address) {
		iounmap(smc_bus_virt_base_address);
		smc_bus_virt_base_address=0;
	}
	if (smc_bus_iomemregion) {
		smc_bus_iomemregion=0;
		release_mem_region(SMC_MEM_START, SMC_MEM_LEN);
	}
}

#endif /* KERNEL_SMC_DRIVER_SMCIF_H_ */

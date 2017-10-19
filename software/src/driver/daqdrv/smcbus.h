
#ifndef SMCBUS_H
#define SMCBUS_H

// import driver functions from smcdriver for smc bus access

// *** Helper Functions for direct SMC bus Access ***
uint32_t smcbusstart(void);
void smcbuswr32(size_t offset, uint32_t data);
void smcbuswr16(size_t offset, uint16_t data);
uint32_t smcbusrd32(size_t offset);
uint16_t smcbusrd16(size_t offset);

#endif // SMCBUS_H

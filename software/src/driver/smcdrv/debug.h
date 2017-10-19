/*
 * debug.h
 *
 *  Created on: 03.09.2010
 *      Author: marekp
 */

#ifndef DEBUG_H_
#define DEBUG_H_

#define WRN(fmt...) do { if(printk_ratelimit()) printk(KERN_WARNING " " DRIVER_NAME " "  ": " fmt); } while(0)
#define ERR(fmt...) do { if(printk_ratelimit()) printk(KERN_ERR " " DRIVER_NAME ": " fmt); } while(0)

#define INFO(fmt...) do { printk(KERN_INFO " " DRIVER_NAME ": " fmt); } while(0)
//#define INFO(fmt...) do {} while(0)

#define DBG(fmt...) do { if(printk_ratelimit()) printk(DRIVER_NAME ": " fmt); } while(0)
//#define DBG(fmt...) do {} while(0)

//#define ERR(fmt, args...) do { if(printk_ratelimit()) printk(KERN_ERR " " DRIVER_NAME ": " fmt, ##args); } while(0)
//#define WRN(fmt, args...) do { if(printk_ratelimit()) printk(KERN_WARNING " " DRIVER_NAME ": " fmt, ##args); } while(0)
//#define DBG(fmt, args...) do { if(printk_ratelimit()) printk(DRIVER_NAME ":<%s> " fmt, __func__, ##args); } while(0)




#endif /* DEBUG_H_ */

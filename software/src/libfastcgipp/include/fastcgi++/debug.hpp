/*
 * debug.hpp
 *
 *  Created on: Jan 31, 2017
 *      Author: marekp
 */

#ifndef DEBUG_HPP_
#define DEBUG_HPP_

#include <iostream>

extern void error_log(const char* msg);


//#define DBG(MSG) do { std::stringstream s; s << __FILE__ << ":" << __LINE__ << " "<< MSG << std::endl; error_log(s.str().c_str()); } while(0)
#define DBG(MSG) do { } while(0)


#endif /* DEBUG_HPP_ */

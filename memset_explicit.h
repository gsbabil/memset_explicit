/*
 * ---------------------------------------------------------------------------
 *       Filename:  memset_explicit.h
 *    Description:  A custom `memset()` implementation to force bypass GCC/Clang
 *                  optimization
 *
 *        Version:  1.0
 *        Created:  03/19/2015 01:41:49
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Babil Golam Sarwar (bgs)
 *          Email:  gsbabil@gmail.com
 * ---------------------------------------------------------------------------
 */

#ifndef _MEMSET_VYSK_H
#define _MEMSET_VYSK_H

void memset_explicit(unsigned char* buf, unsigned char val, size_t buf_len);

#endif

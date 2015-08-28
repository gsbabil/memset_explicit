/*
 * ---------------------------------------------------------------------------
 *       Filename:  memset_explicit.c
 *    Description:  A custom `memset()` implementation to force bypass GCC/Clang
 *                  optimization
 *
 *        Version:  1.0
 *        Created:  03/19/2015 01:41:49
 *       Revision:  none
 *       Compiler:  gcc, clang, armcc
 *
 *         Author:  Babil Golam Sarwar (gsbabil)
 *          Email:  gsbabil@gmail.com
 * ---------------------------------------------------------------------------
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "memset_explicit.h"

#define memset_explicit_x86(buf, val, len) \
  __asm__ __volatile__("\n\trep stos %1, (%0)"                  \
                       :                                        \
                       : "D"((buf)), "a"((unsigned char)(val)), \
                         "c"((len) / sizeof(unsigned char))     \
                       : "memory")

/*
 * #if defined(__EMBEDDED__)
 * #define memset_explicit_arm(buf, val) \
 *   __asm__ __volatile__("mov r4, %[val] \n\tstmia %[buf]!, {r4} \n\t"
 *                      :
 *                      : [val] "r"(val), [buf] "r"(buf)
 *                      : "r4", "memory")
 * #endif
 */

#if __ARM_ARCH == 7 || defined(__EMBEDDED__)
#define memset_explicit_arm(buf, val) \
  __asm__ __volatile__("mov r4, %[val]\n\tmov r5, %[buf]\n\tstr r4, [r5]" \
                       :                                                  \
                       : [val] "r"((unsigned int)val), [buf] "r"(buf)     \
                       : "r4", "r5", "memory")
#endif

#if __ARM_ARCH == 8
#define memset_explicit_arm(buf, val) \
  __asm__ __volatile__("mov x4, %[val]\n\tmov x5, %[buf]\n\tstr x4, [x5]" \
                       :                                                  \
                       : [val] "r"((unsigned long)val), [buf] "r"(buf)    \
                       : "x4", "x5", "memory")
#endif

void __attribute__((noinline))
memset_explicit(unsigned char* buf, unsigned char val, size_t buf_len) {
#if defined(__ARM_ARCH)
  int i = 0;
  for (i = 0; i < buf_len; i++) {
    buf[i] = val;
    memset_explicit_arm(buf, val);
    /*
     * asm volatile("mov x4, %[val]"
     *              :
     *              : [val] "r"((unsigned long)val)
     *              : "x4", "memory");
     * asm volatile("mov x5, %[buf]"
     *              :
     *              : [buf] "r"((unsigned long)buf)
     *              : "x5", "memory");
     * asm volatile("str x4, [x5]" : : : "x4", "x5",
     * "memory");
     */
    buf = buf + 1;
  }
#else
  memset_explicit_x86(buf, val, buf_len);
#endif
}

int main() {
  char buffer[4];
  buffer[0] = 'A';
  buffer[1] = 'B';
  buffer[2] = 'C';
  buffer[3] = 'D';
  /*
   * memset((unsigned char*)buffer, 0x00, sizeof(buffer));
   */
  memset_explicit((unsigned char*)buffer, 0x00, sizeof(buffer));
  return 0;
}

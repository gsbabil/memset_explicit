# memset_explicit
Forced `memset()` to avoid GCC/Clang optimization

## Supported Compiers

The code was tested under the following compilers:

  - ARMCC
  - GCC
  - GCC-ARM
  - Clang (x86, arm64, armv7, armv7s)

## Demo

```
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
```

Typical `memset` with `-O3` optimization produces the following assembly
for the code above, clearly shorting out the `memset` call. Here's how
the compiled assembly looks like after compiling it with GCC/Clang:

```
gdb$ Dump of assembler code for function main:
   0x00001ff0 <+0>:     push   %ebp
   0x00001ff1 <+1>:     mov    %esp,%ebp
   0x00001ff3 <+3>:     xor    %eax,%eax
   0x00001ff5 <+5>:     pop    %ebp
   0x00001ff6 <+6>:     ret
End of assembler dump.
```

As can be seen the `memset` call is "optimized" by GCC/Clang's
optimizer.

This can be problematic, even dangerous, if the `memset` was critically
needed to erase memory locations containting privacy sensitive data.
These are the situations where `memset_explicit(..)` becomes useful. The
same code snippet above compiled with `-O3` produces the following
assembly with `memset_explicit(..)` forcing the deletion of the buffer
as the programmer have had intended.

```
gdb$ Dump of assembler code for function main:
   0x00001fd0 <+0>:     push   %ebp
   0x00001fd1 <+1>:     mov    %esp,%ebp
   0x00001fd3 <+3>:     sub    $0x18,%esp
   0x00001fd6 <+6>:     movl   $0x44434241,-0x4(%ebp)
   0x00001fdd <+13>:    lea    -0x4(%ebp),%eax
   0x00001fe0 <+16>:    mov    %eax,(%esp)
   0x00001fe3 <+19>:    movl   $0x4,0x8(%esp)
   0x00001feb <+27>:    movl   $0x0,0x4(%esp)
   0x00001ff3 <+35>:    call   0x1fb0 <memset_explicit>
   0x00001ff8 <+40>:    xor    %eax,%eax
   0x00001ffa <+42>:    add    $0x18,%esp
   0x00001ffd <+45>:    pop    %ebp
   0x00001ffe <+46>:    ret
End of assembler dump.
```


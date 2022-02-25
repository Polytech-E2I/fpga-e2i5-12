# See LICENSE for license details.

.include "macros.s"
.include "constants.s"

#
# Totally minimalist boot sequence with in particular no access to the
# control and status registers with dedicated instructions
# 

.section .text.init,"ax",@progbits
.globl _start

_start:
    # set up stack pointer at some zeroed address range 
    la      sp, stacks + STACK_SIZE

    # jump to libfemto_start_main
    j       libfemto_start_main

    .bss
    .align 4
    .global stacks
stacks:
    .skip STACK_SIZE

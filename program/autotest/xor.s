# TAG = xor
    .text

    addi x31,   zero,   -1
    addi t1,    zero,   0x74C
    xor  x31,   x31,    t1

    # max_cycle 50
    # pout_start
    # FFFFFFFF
    # FFFFF8B3
    # pout_end

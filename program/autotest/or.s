# TAG = or
    .text

    addi x31,   zero,   0
    addi t1,    zero,   0x74C
    or   x31,   x31,    t1

    # max_cycle 50
    # pout_start
    # 00000000
    # 0000074C
    # pout_end

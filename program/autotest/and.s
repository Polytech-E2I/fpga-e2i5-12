# TAG = and
    .text

    addi x31,   zero,   -1
    addi t1,    zero,   0x74C
    and  x31,   x31,    t1

    # max_cycle 50
    # pout_start
    # FFFFFFFF
    # 0000074C
    # pout_end

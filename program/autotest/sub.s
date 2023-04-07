# TAG = sub
    .text

    addi x31,   zero,   7
    addi t1,    zero,   4
    sub  x31,   x31,    t1
    sub  x31,   x31,    t1

    # max_cycle 50
    # pout_start
    # 00000007
    # 00000003
    # FFFFFFFF
    # pout_end

# TAG = sltiu
    .text

    addi  t0,    zero,   7
    addi  t1,    zero,   -4
    sltiu x31,   t0,     -4
    sltiu x31,   t1,     7
    sltiu x31,   t0,     7

    # max_cycle 50
    # pout_start
    # 00000001
    # 00000000
    # 00000000
    # pout_end

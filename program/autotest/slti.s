# TAG = slti
    .text

    addi t0,    zero,   7
    addi t1,    zero,   -4
    slti x31,   t0,     -4
    slti x31,   t1,     7
    slti x31,   t0,     7

    # max_cycle 50
    # pout_start
    # 00000000
    # 00000001
    # 00000001
    # pout_end

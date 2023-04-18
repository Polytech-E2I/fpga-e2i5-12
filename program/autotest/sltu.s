# TAG = sltu
    .text

    addi t0,    zero,   7
    addi t1,    zero,   -4
    sltu x31,   t0,     t1
    sltu x31,   t1,     t0
    sltu x31,   t1,     t1

    # max_cycle 50
    # pout_start
    # 00000000
    # 00000001
    # 00000000
    # pout_end

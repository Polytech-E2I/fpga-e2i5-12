# TAG = jalr
    .text

    lui     t0,     0x1

    jalr    x31,    12(t0)

    addi    x31,    zero,   0x123

    addi    x31,    zero,   0x321
    jalr    x0,     8(t0)

    # max_cycle 50
    # pout_start
    # 00001008
    # 00000321
    # 00000123
    # 00000321
    # pout_end

# TAG = sw
    .text

    # address
    lui     t0,     0x2
    # data
    addi    t1,     zero,   0x123

    sw      t1,     0(t0)
    lw      x31,    0(t0)


    # max_cycle 50
    # pout_start
    # 00000123
    # pout_end

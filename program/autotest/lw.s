# TAG = lw
    .text

    lui     t0,     0x08FF0
    srli    t0,     t0,     12
    addi    t1,     zero,   0x123

    sw      t1,     0(t0)
    lw      x31,    0(t0)

    # Fail ??? OK in simulation

    # max_cycle 500
    # pout_start
    # 00000123
    # pout_end

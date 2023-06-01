# TAG = beq
    .text

    addi    t0,     zero,   7
    addi    t1,     zero,   7
    addi    t2,     zero,   4

    addi    x31,    zero,   9
    beq     t0,     t1,     jump1
    addi    x31,    zero,   12
jump1:
    addi    x31,    zero,   13

    beq     t0,     t2,     jump2
    addi    x31,    zero,   14
jump2:
    addi    x31,    zero,   15

    # max_cycle 50
    # pout_start
    # 00000009
    # 0000000D
    # 0000000E
    # 0000000F
    # pout_end

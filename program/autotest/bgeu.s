# TAG = bgeu
    .text

    addi    t0,     zero,   7
    addi    t1,     zero,   -4

    addi    x31,    zero,   9
    bgeu    t1,     t0,     jump
    addi    x31,    zero,   12
jump:
    addi    x31,    zero,   13

    # max_cycle 50
    # pout_start
	# 00000009
    # 0000000D
    # pout_end

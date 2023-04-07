# TAG = addi
    .text

    addi x31,   zero,   0x037
    addi x31,   zero,   -1
    addi x31,   x31,    22

    # max_cycle 50
    # pout_start
    # 00000037
    # FFFFFFFF
    # 00000015
    # pout_end

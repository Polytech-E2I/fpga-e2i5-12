# TAG = sra
    .text

    addi x31,   zero,   1
    addi t1,    zero,   4
    sll  x31,   x31,    t1
    sll  x31,   x31,    t1
    sll  x31,   x31,    t1
    sll  x31,   x31,    t1
    sll  x31,   x31,    t1
    sll  x31,   x31,    t1
    sll  x31,   x31,    t1

    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1

    sll  x31,   x31,    31
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1
    sra  x31,   x31,    t1

    # max_cycle 500
    # pout_start
    # 00000001
    # 00000010
    # 00000100
    # 00001000
    # 00010000
    # 00100000
    # 01000000
    # 10000000
    # 01000000
    # 00100000
    # 00010000
    # 00001000
    # 00000100
    # 00000010
    # 00000001
    # 80000000
    # F8000000
    # FF800000
    # FFF80000
    # FFFF8000
    # FFFFF800
    # FFFFFF80
    # FFFFFFF8
    # pout_end

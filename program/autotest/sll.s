# TAG = sll
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
    sll  x31,   x31,    t1

    # max_cycle 50
    # pout_start
    # 00000001
    # 00000010
    # 00000100
    # 00001000
    # 00010000
    # 00100000
    # 01000000
    # 10000000
    # 00000000
    # pout_end

# TAG = srli
    .text

    addi x31,   zero,   1
    slli x31,   x31,    4
    slli x31,   x31,    4
    slli x31,   x31,    4
    slli x31,   x31,    4
    slli x31,   x31,    4
    slli x31,   x31,    4
    slli x31,   x31,    4

    srli x31,   x31,    4
    srli x31,   x31,    4
    srli x31,   x31,    4
    srli x31,   x31,    4
    srli x31,   x31,    4
    srli x31,   x31,    4
    srli x31,   x31,    4

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
    # 01000000
    # 00100000
    # 00010000
    # 00001000
    # 00000100
    # 00000010
    # 00000001
    # pout_end

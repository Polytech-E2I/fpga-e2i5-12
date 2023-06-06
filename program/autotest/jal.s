# TAG = jal
    .text

    jal     x31,     jump
begin:
    addi    x31,    zero,   0x123
jump:
    addi    x31,    zero,   0x321
    jal     x0,     begin

    # max_cycle 50
    # pout_start
    # 00001004
    # 00000321
    # 00000123
    # 00000321
    # pout_end

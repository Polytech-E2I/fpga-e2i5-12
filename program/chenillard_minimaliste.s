.text

    # index <> x11 = 24
    addi    x11,    zero,   20

    # mask <> x12 = 1 << index
    addi    x12,    zero,   1
    sll     x12,    x12,    x11

    # compteur <> x13 = compteur + 1
    addi    x13,    x13,    1

    # bit_extrait <> x14 = compteur & mask
    and     x14,    x13,    x12

    # change <> x15 = bit_extrait xor bit_extrait_precedent
    xor     x15,    x14,    x16

    # bit_extrait_precedent <> x16 = bit_extrait
    addi    x16,    x15,    0

    # change = change >> index
    srl     x15,    x15,    x11

    # motif <> x17 = motif << change
    sll     x17,    x17,    x15

    # motif = motif or 0x1
    ori     x17,    x17,    0x1

    # afficher(motif)
    addi    x31,    x17,    0
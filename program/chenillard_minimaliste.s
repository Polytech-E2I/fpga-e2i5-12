.text

    # index <> x1 = 24
    addi    x1,    zero,   3

    # mask <> x2 = 1 << index
    addi    x2,    zero,   1
    sll     x2,    x2,    x1

    # compteur <> x3 = compteur + 1
    addi    x3,    x3,    1

    # bit_extrait <> x4 = compteur & mask
    and     x4,    x3,    x2

    # change <> x5 = bit_extrait xor bit_extrait_precedent
    xor     x5,    x4,    x6

    # bit_extrait_precedent <> x6 = bit_extrait
    addi    x6,    x5,    0

    # change = change >> index
    srl     x5,    x5,    x1

    # motif <> x7 = motif << change
    sll     x7,    x7,    x5

    # motif = motif or 0x1
    ori     x7,    x7,    0x1

    # afficher(motif)
    addi    x31,    x7,    0

    #mul     x0,     x0,     x0
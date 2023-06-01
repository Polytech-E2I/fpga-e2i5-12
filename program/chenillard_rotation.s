.text

    # motif <> x1 = 0x03
    addi    x1,     zero,   0x03

loop:
    # compteur <> x2 = 0
    addi    x2,     zero,   0

    # cible <> x3 = 10 000 000
    # (10 000 000)_10 >> (12)_10 = (989)_16
    lui     x3,     0x989
    # (989)_16 << (12)_10 = (10 000 000)_10 - (1664)_10
    addi    x3,     x3,     1664

    # cible = 5 (for debugging in simulation)
    #addi    x3,     zero,   5

################################################################################
wait_loop:
    # compteur += 1
    addi    x2,     x2,     1
    ## if compteur < cible then jump back
    blt     x2,     x3,     wait_loop
################################################################################

    # afficher(motif)
    addi    x31,    x1,     0

    # motif <<= 1
    slli    x1,     x1,     1

    # x2 = motif & 0x10
    andi    x2,     x1,     0x10

################################################################################
    ## if (motif & 0x10) == 0 then jump forward
    beq     x2,     zero,   end_if

    # motif &= 0xF
    andi    x1,     x1,     0xF

    # motif |= 0x1
    ori     x1,     x1,     0x1
################################################################################

end_if:
    beq     zero,   zero,   loop
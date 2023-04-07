# TAG = add
	.text

	addi t0, zero, 7
	addi t1, zero, 4
	add  x31, t0, t1

	addi t0, zero, 0
	addi t1, zero, -1
	add  x31, t0, t1

	# max_cycle 50
	# pout_start
	# 0000000B
	# FFFFFFFF
	# pout_end

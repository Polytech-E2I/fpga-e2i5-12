# TAG = auipc
	.text

	auipc x31, 0       # Test sur la valeur 0

	auipc x31, 0xFFFFF # Test sur la valeur maximal sur 20 bits

	auipc x31, 0x12345 # Test sur une valeur sur 20 bits

	auipc x31, 0x7FFFF # Test sur la valeur maximal positive sur 20 bits

	auipc x31, 0x80000 # Test en soustrayant de l'adresse de base du code

	# max_cycle 50
	# pout_start
	# 00001000
	# 00000004
	# 12346008
	# 8000000C
	# 80001010
	# pout_end

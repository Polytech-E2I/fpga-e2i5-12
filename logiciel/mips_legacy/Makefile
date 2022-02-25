# Pour utiliser ce Makefile, les variables suivantes doivent etre positionnées
# PATH : doit contenir le chemin du cross-compilateur
# MIPS_PREFIX : prefix des binutils ou du cross-compilateur par defaut MIPS_PREFIX=mips-sde-elf-

# A l'appel du makefile : make <cible> IRQ_FLAG=irq/no_irq
# IRQ_FLAG=irq  ou no_irq pour valider/invalider l'utilisation d'IRQs
MIPS_TOOLCHAIN_DIR?=/opt/mips-toolchain/bin
MIPS_PREFIX?=mips-sde-elf-
export MIPS_TOOLCHAIN_DIR
export MIPS_PREFIX

# Toolchain GCC
CC=$(MIPS_TOOLCHAIN_DIR)/$(MIPS_PREFIX)gcc
LD=$(MIPS_TOOLCHAIN_DIR)/$(MIPS_PREFIX)ld
AS=$(MIPS_TOOLCHAIN_DIR)/$(MIPS_PREFIX)as
DP=$(MIPS_TOOLCHAIN_DIR)/$(MIPS_PREFIX)objdump

help:
	@echo "Usage:"
	@echo "  $(MAKE) <elf-target> [IRQ_FLAG=<irq?>]"
	@echo ""
	@echo "Variable:"
	@echo "  IRQ_FLAG   Permet d'activer les interruptions ou non."
	@echo "             Valeurs autorisées: irq, no_irq"
	@echo ""
	@echo "Exemple:"
	@echo "  $(MAKE) mips_invader_zybo.elf IRQ_FLAG=no_irq"
	@echo ""

# Config
IRQ_FLAG ?= no_irq

# Default configs (for mips_invader_zybo and test_irq)
ifneq ($(filter $(MAKECMDGOALS),mips_invader_zybo.elf),)
  override IRQ_FLAG=no_irq
endif
mips_invader_zybo.elf:
ifneq ($(filter $(MAKECMDGOALS),test_irq.elf),)
  override IRQ_FLAG=irq
endif
test_irq.elf:

# Flags
MIPS_FLAG=mmips_$(IRQ_FLAG)
MSTART=$(MIPS_FLAG).o
LINK_SCR= mmips_link_$(IRQ_FLAG).scr
ASFLAGS=-mips32 -EB -mabi=32 -non_shared
CFLAGS=-mips32 -Xassembler -EB -Xassembler -mabi=32 -Xassembler -W -G0  -fno-delayed-branch
LDFLAGS=-G0 -EB -mips3 --static -T  $(LINK_SCR)

.PRECIOUS : %.o %.dump


# Build rules
%.o : %.s
	$(AS)  $(ASFLAGS) -G0 -o $@ $<

%.o : %.c
	$(CC) $(CFLAGS) -c  -o $@ $<

%.elf :  %.o  $(LINK_SCR) $(MSTART)
	$(LD)  $(LDFLAGS)  -o $@ $(MSTART) $<
	@# placer le binaire obtenu dans le répertoire program du projet.
	cp $@ ../processeur/implem/program
	@echo ""
	@echo "Les instructions nécessaires pour exécuter ce programme sont:"
	@./instructions_necessaires.sh $@

%.dump  : %
	$(DP)  -S --section=.ini --section=__start --section=.text --section=.sdata --section=.data --section=.bss --section=.irq_vec -M no-aliases -d $< > $@

%.dump  : %.o
	$(DP)  -S --section=.ini --section=__start --section=.text --section=.sdata --section=.data --section=.bss --section=.irq_vec -M no-aliases -d $< > $@

clean:
	rm -f *.o *.dump *.elf

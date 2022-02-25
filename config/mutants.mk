SEQUENCE_TAG ?= program/sequence_tag
COLOR        ?= 1
SHELL        := /bin/bash

# Files & Directories
include config/directory.mk

TMP_RES=$(MUT_DIR)/tmp_res
TMP_SEQ=$(MUT_DIR)/tmp_seq

AUTOTEST_MK:=config/autotest.mk
MUTANTS_REF:=config/mutants.txt

#.PHONY : res print filter clean realclean 
.PHONY : generate_seq print save_autotest_res

# Getting list of declared tags
TAGS        != sed -e 's/\#[ a-zA-Z0-9]*//g' $(SEQUENCE_TAG)

# Filter tags to only evaluate mutants for tags that have passed the autotest
PASSED_TAGS != if [[ -f tag.res ]] ; then cat tag.res | awk -v tag=$* 'BEGIN{IGNORECASE = 1}$$2~/PASSED/{print $$1}' ; fi
TAGS    := $(filter $(TAGS), $(PASSED_TAGS))

MUTRES  := $(addprefix $(MUT_DIR)/, $(TAGS:=.mutres))

TOCLEAN := $(MUT_DIR)/*.mutres  $(MUT_DIR)/*.mutseq

print: mutants.res
	@echo ""
	@echo "   ****   Test Coverage Results   ****"
	@echo ""
	@# Print mutants.res (with color)
	@-[[ $(COLOR) == 1 ]] && cat $< | GREP_COLORS='ms=01;31' grep --color "low_coverage"        ; exit 0
	@-[[ $(COLOR) == 1 ]] && cat $< | GREP_COLORS='ms=01;33' grep --color "medium_coverage"     ; exit 0
	@-[[ $(COLOR) == 1 ]] && cat $< | GREP_COLORS='ms=01;36' grep --color "high_coverage"       ; exit 0
	@-[[ $(COLOR) == 1 ]] && cat $< | GREP_COLORS='ms=01;32' grep --color "full_coverage"       ; exit 0
	@-[[ $(COLOR) == 1 ]] && cat $< | grep -v "full_coverage\|high_coverage\|medium_coverage\|low_coverage"    ; exit 0
	@# (without color)
	@-[[ $(COLOR) != 1 ]] && cat $< ; exit 0

mutants.res: save_autotest_res generate_seq ${MUTRES}
	@cat $(MUT_DIR)/*.mutres | column -t > $@	

%.mutres: %.mutseq
	@rm -f $(TMP_RES) $(TMP_SEQ)
	@echo "$$(basename $*)" > $(TMP_SEQ)
	# lance l'autotest avec une sequence_tag donné
	@for i in $$(cat $<) ; do echo "Executing autotest for tag $$(basename $*) (mutant n°$$i)"; $(MAKE) -s -f $(AUTOTEST_MK) TESTS_DIR=$(TESTS_DIR) SEQUENCE_TAG=$(TMP_SEQ) MUTANTS=$${i} print ; if [[ $$(cat tag.res | awk '{print $$2}') == "PASSED" ]] ; then echo "$$(basename $*) passed" >> $(TMP_RES); else echo "$$(basename $*) failed" >> $(TMP_RES) ; fi ; done
	# Calcule le taux de couverture
	@ if [[ $$(cat $<) == "" ]] ; then echo "$$(basename $*) no_mutants_found" > $@ ; exit 0 ; fi ; f=$$(grep -c "failed" $(TMP_RES)) ; p=$$(grep -c "passed" $(TMP_RES)) ; total=$$(($$f + $$p)) ; perc=$$(( ($$f*100)/($$f + $$p) )); if [[ "$${perc}" -eq 100 ]] ; then msg="full_coverage" ; elif [[ "$${perc}" -ge 75 ]] ; then echo msg="high_coverage" ; elif [[ "$${perc}" -ge 30 ]] ; then msg="medium_coverage" ; else msg="low_coverage" ; fi ; echo "$$(basename $*) $${msg} $${perc}% ($$f/$${total})" > $@

generate_seq:
	@mkdir -p $(MUT_DIR)
	@echo "Generate sequences"
	@for i in ${TAGS} ; do numbers=$$(cat ${MUTANTS_REF} | awk -v tag=$${i} '$$2~("(^|,)" tag "($$|,)"){print $$1}' ${MUTANTS_REF}); echo "$${numbers}" > $(MUT_DIR)/$${i}.mutseq ; done

save_autotest_res:
	@cp tag.res tag.res.sav

clean:
	@echo "Removing $(TOCLEAN)"
	@rm -rf $(TOCLEAN)

realclean: clean
	#@rm -rf $(TOPOLISH)

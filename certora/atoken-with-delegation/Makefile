default: help

PATCH         = applyHarness.patch
CONTRACTS_DIR = ../../src
LIB_DIR       = ../../lib
MUNGED_SRC    = munged/src
MUNGED_LIB    = munged/lib
MUNGED_DIR    = munged

help:
	@echo "usage:"
	@echo "  make clean:  remove all generated files (those ignored by git)"
	@echo "  make $(MUNGED_DIR): create $(MUNGED_DIR) directory by applying the patch file to $(CONTRACTS_DIR)"
	@echo "  make record: record a new patch file capturing the differences between $(CONTRACTS_DIR) and $(MUNGED_DIR)"

munged:  $(wildcard $(CONTRACTS_DIR)/*.sol) $(PATCH)
	rm -rf $@
	mkdir $@
	cp -r ../../lib $@
	cp -r ../../src $@
	patch -p0 -d $@ < $(PATCH)

record:
	mkdir tmp_make_r
	cp -r $(LIB_DIR) tmp_make_r
	cp -r $(CONTRACTS_DIR) tmp_make_r
	diff -ruN tmp_make_r $(MUNGED_DIR) | sed 's+tmp_make_r/++g' | sed 's+$(MUNGED_DIR)/++g' > $(PATCH)
	rm -rf tmp_make_r

clean:
	git clean -fdX
	touch $(PATCH)


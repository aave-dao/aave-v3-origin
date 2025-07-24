default: help

PATCH         = applyHarness.patch
CONTRACTS_DIR = ../../src
MUNGED_DIR    = munged

help:
	@echo "usage:"
	@echo "  make clean:  remove all generated files (those ignored by git)"
	@echo "  make $(MUNGED_DIR): create $(MUNGED_DIR) directory by applying the patch file to $(CONTRACTS_DIR)"
	@echo "  make record: record a new patch file capturing the differences between $(CONTRACTS_DIR) and $(MUNGED_DIR)"

munged:  $(wildcard $(CONTRACTS_DIR)/*.sol) $(PATCH)
	rm -rf $@
	mkdir $@
	cp -r ../../src $@
	patch -p0 -d $@ < $(PATCH)

record:
	mkdir tmp
	cp -r ../../src tmp
	diff -ruN tmp $(MUNGED_DIR) | sed 's+tmp/++g' | sed 's+$(MUNGED_DIR)/++g' > $(PATCH)
	rm -rf tmp

clean:
	git clean -fdX
	touch $(PATCH)


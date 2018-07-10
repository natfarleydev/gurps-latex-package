COMPILED_PACKAGE_FILES = $(foreach var,.sty .lua _tables.lua _character.lua,gurps$(var)) etb_extensions.lua

all: tests/test_document.pdf

tests/test_document.pdf: tests/test_document.tex $(foreach i,$(COMPILED_PACKAGE_FILES),source/$i)
	$(foreach var,$(COMPILED_PACKAGE_FILES),cp source/$(var) tests/$(var);)
	cd tests && latexmk -g -lualatex --interaction=nonstopmode test_document.tex

source/gurps.sty: source/gurps.dtx source/gurps.lua source/gurps_character.lua source/gurps_tables.lua
	$(MAKE) -C source/

clean:
	$(MAKE) -C source/ distclean
	$(foreach var,$(COMPILED_PACKAGE_FILES),rm -f tests/$(var);)
	cd tests && latexmk -CA test_document.tex

inst:
	$(MAKE) -C source/ inst

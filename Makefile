COMPILED_PACKAGE_FILES = $(foreach var,.sty .lua _tables.lua,gurps$(var))

all: tests/test_document.pdf

tests/test_document.pdf: tests/test_document.tex $(foreach i,$(COMPILED_PACKAGE_FILES),source/$i)
	$(foreach var,$(COMPILED_PACKAGE_FILES),cp source/$(var) tests/$(var);)
	latexmk -g -lualatex --interaction=nonstopmode -cd tests/test_document.tex

source/gurps.sty: source/gurps.dtx source/gurps.lua
	$(MAKE) -C source/

clean:
	$(MAKE) -C source/ distclean
	$(foreach var,$(COMPILED_PACKAGE_FILES),rm tests/$(var);)
	latexmk -CA -cd tests/test_document.tex

inst:
	$(MAKE) -C source/ inst

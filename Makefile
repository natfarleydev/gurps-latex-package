COMPILED_PACKAGE_FILES = $(foreach var,.sty .lua _tables.lua,gurps$(var))

all: tests/main.pdf

tests/main.pdf: tests/main.tex source/gurps.sty source/gurps.lua
	$(foreach var,$(COMPILED_PACKAGE_FILES),cp source/$(var) tests/$(var);)
	latexmk -g -lualatex -cd tests/ main.tex

source/gurps.sty: source/gurps.dtx source/gurps.lua
	$(MAKE) -C source/

clean:
	$(MAKE) -C source/ distclean
	$(foreach var,$(COMPILED_PACKAGE_FILES),rm tests/$(var);)
	latexmk -CA -cd tests/ main.tex

inst:
	$(MAKE) -C source/ inst

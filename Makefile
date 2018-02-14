all: tests/main.pdf

tests/main.pdf: tests/main.tex source/gurps.sty source/gurps.lua
	latexmk -g -lualatex -cd tests/main.tex

source/gurps.sty: source/gurps.dtx source/gurps.lua
	$(MAKE) -C source/ inst

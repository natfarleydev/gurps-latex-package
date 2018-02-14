all: tests/main.pdf

tests/main.pdf: tests/main.tex source/gurps.sty source/gurps.lua
	cp source/gurps{.sty,.lua,_tables.lua} tests/
	latexmk -g -lualatex -cd tests/main.tex

source/gurps.sty: source/gurps.dtx source/gurps.lua
	$(MAKE) -C source/

clean:
	rm tests/gurps{.sty,.lua,_tables.lua}
	latexmk -CA -cd tests/main.tex

inst:
	$(MAKE) -C source/ inst

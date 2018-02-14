# gurps-latex-package
A LaTeX package for aiding the creation of homemade GURPS resources.

## Installation
To install this package as a user:

    make inst
    
To install this package using sudo:

    cd source/
    make install
    
## Running tests

Tests can be run with the Makefile as:

    make

which will make the package, copy the `sty` and `lua` files over to the test
directory and compile the test document.

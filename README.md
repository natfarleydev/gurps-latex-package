# gurps-latex-package
CircleCI status: ![CircleCI status](https://circleci.com/gh/nasfarley88/gurps-latex-package.png?circle-token=8d0ab847c5fc6ed4fa9cf07aa5e167c24c322cb3)

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

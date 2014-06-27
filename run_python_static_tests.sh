#!/bin/sh

# Flake8 checks code style using pep8, static erros using pyflakes and code
# complexity using mccabe.
flake8 . --max-complexity 10

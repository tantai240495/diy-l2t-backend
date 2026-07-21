.PHONY: setup install

setup: install

install:
	poetry install
	poetry lock

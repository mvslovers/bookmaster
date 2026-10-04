# Builds the sample book and checks its syntax diagrams.

TYPST ?= typst
FONTS := fonts

.PHONY: all sample check clean

all: check sample

sample: sample/ml01-0002.pdf

sample/ml01-0002.pdf: sample/ml01-0002.typ bookmaster.typ $(wildcard sample/ex/*)
	$(TYPST) compile --root . --font-path $(FONTS) --ignore-system-fonts $< $@

check:
	python3 tools/check-syntax.py sample/ex/syn-*.txt

clean:
	rm -f sample/*.pdf

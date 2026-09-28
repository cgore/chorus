#### Copyright (c) 2012--2021 Masayuki Takagi.
#### Copyright (c) 2026 Christopher Mark Gore.
####
#### This file is part of Chorus, licensed under the MIT License.
#### See the LICENSE file at the root of the repository.

LATEX_FILES=chorus.latex copyright.latex introduction.latex		\
	chorus-package.latex api-context-package.latex			\
	api-memory-package.latex api-defkernel-package.latex		\
	api-macro-package.latex api-nvcc-package.latex			\
	api-timer-package.latex lang-package.latex			\
	driver-api-package.latex interop-package.latex

all: chorus.dvi chorus.ps chorus.pdf

chorus.dvi: ${LATEX_FILES} chorus.bib
	latex chorus.latex
	bibtex chorus
	latex chorus.latex
	latex chorus.latex

chorus.ps: chorus.dvi
	dvips -o chorus.ps chorus.dvi

chorus.pdf: ${LATEX_FILES} chorus.bib
	pdflatex chorus.latex
	bibtex chorus
	pdflatex chorus.latex
	pdflatex chorus.latex

clean:
	rm -f chorus.pdf chorus.ps chorus.dvi \
	      chorus.aux chorus.bbl chorus.blg chorus.log \
	      chorus.toc chorus.out

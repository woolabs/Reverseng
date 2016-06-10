FILES=Cover.md \
	  Part-Ⅰ/Chapter-01.md \
	  Part-Ⅰ/Chapter-02.md \
	  Part-Ⅰ/Chapter-03.md \
	  Part-Ⅰ/Chapter-04.md \
	  Part-Ⅰ/Chapter-05.md \
	  Part-Ⅰ/Chapter-06.md \
	  Part-Ⅰ/Chapter-07.md \
	  Part-Ⅰ/Chapter-08.md \
	  Part-Ⅰ/Chapter-09.md \
	  Part-Ⅰ/Chapter-10.md \
	  Part-Ⅰ/Chapter-11.md \
	  Part-Ⅰ/Chapter-12.md \
	  Part-Ⅰ/Chapter-13.md \
	  Part-Ⅰ/Chapter-14.md \
	  Part-Ⅰ/Chapter-15.md \
	  Part-Ⅰ/Chapter-16.md \
	  Part-Ⅰ/Chapter-17.md \
	  Part-Ⅰ/Chapter-18.md \
	  Part-Ⅰ/Chapter-19.md \
	  Part-Ⅰ/Chapter-20.md \
	  Part-Ⅰ/Chapter-21.md \
	  Part-Ⅰ/Chapter-22.md \
	  Part-Ⅰ/Chapter-23.md \
	  Part-Ⅰ/Chapter-24.md \
	  Part-Ⅰ/Chapter-25.md \
	  Part-Ⅰ/Chapter-26.md \
	  Part-Ⅰ/Chapter-27.md \
	  Part-Ⅰ/Chapter-28.md \
	  Part-Ⅰ/Chapter-29.md \
	  Part-Ⅱ/Chapter-30.md \
	  Part-Ⅱ/Chapter-31.md \
	  Part-Ⅱ/Chapter-32.md \
	  Part-Ⅱ/Chapter-33.md \
	  Part-Ⅱ/Chapter-34.md \
	  Part-Ⅲ/Chapter-35.md \
	  Part-Ⅲ/Chapter-36.md \
	  Part-Ⅲ/Chapter-37.md \
	  Part-Ⅲ/Chapter-38.md \
	  Part-Ⅲ/Chapter-39.md \
	  Part-Ⅲ/Chapter-40.md \
	  Part-Ⅲ/Chapter-41.md \
	  Part-Ⅲ/Chapter-42.md \
	  Part-Ⅲ/Chapter-43.md \
	  Part-Ⅲ/Chapter-44.md \
	  Part-Ⅲ/Chapter-49.md \
	  Part-Ⅲ/Chapter-50.md \
	  Part-Ⅲ/Chapter-51.md \
	  Part-Ⅲ/Chapter-52.md \
	  Part-Ⅲ/Chapter-53.md \
	  Part-Ⅳ/Chapter-54.md \
	  Part-Ⅴ/Chapter-55.md \
	  Part-Ⅴ/Chapter-56.md \
	  Part-Ⅴ/Chapter-57.md \
	  Part-Ⅴ/Chapter-58.md \
	  Part-Ⅴ/Chapter-59.md \
	  Part-Ⅴ/Chapter-60.md \
	  Part-Ⅴ/Chapter-61.md \
	  Part-Ⅴ/Chapter-62.md \
	  Part-Ⅵ/Chapter-64.md \
	  Part-Ⅵ/Chapter-65.md \
	  Part-Ⅵ/Chapter-66.md \
	  Part-Ⅵ/Chapter-67.md \
	  Part-Ⅵ/Chapter-68.md \
	  Part-Ⅶ/Chapter-69.md \
	  Part-Ⅶ/Chapter-70.md \
	  Part-Ⅶ/Chapter-71.md \
	  Part-Ⅶ/Chapter-72.md \
	  Part-Ⅶ/Chapter-73.md \
	  Part-Ⅸ/Chapter-84.md \
	  Part-Ⅸ/Chapter-85.md \
	  Part-Ⅸ/Chapter-86.md \
	  Part-Ⅸ/Chapter-87.md \
	  Afterword/Chapter-99.md \
	  Appendix/Appendix-A.md \
	  Appendix/Appendix-B.md \
	  Appendix/Appendix-C.md \
	  Appendix/Appendix-D.md \
	  Appendix/Appendix-E.md \
	  Appendix/Appendix-F.md

.PHONY: html epub

all: html epub

html:
	rm -rf out/html && mkdir -p out/html/img
	cp -r html/book.css out/html/
	cp --parents img/cover.png out/html/
	cp --parents Part-Ⅰ/img/* out/html/
	cp --parents Part-Ⅱ/img/* out/html/
	cp --parents Part-Ⅲ/img/* out/html/
	cp --parents Part-Ⅳ/img/* out/html/
	cp --parents Part-Ⅴ/img/* out/html/
	cp --parents Part-Ⅵ/img/* out/html/
	cp --parents Part-Ⅶ/img/* out/html/
	cp --parents Part-Ⅸ/img/* out/html/
	cp --parents Afterword/img/* out/html/
	cp --parents Appendix/img/* out/html/


	pandoc -S --to html5 -o out/html/RE4B-CN-partial.html --section-divs --toc --standalone --template=html/template.html $(FILES)

epub:
	mkdir -p out
	rm -f out/RE4B-CN-partial.epub
	pandoc -S --to epub3 -o out/RE4B-CN-partial.epub --toc --epub-chapter-level=2 --data-dir=epub --template=epub/template.html $(FILES)

# bookmaster

A [Typst](https://typst.app) template that sets the mvslovers manuals in the
style of IBM's BookMaster and SCRIPT/VS publications: serif body text, sans
headings under a heavy chapter rule and a hairline section rule, figures
framed by rules with the caption below, running footers carrying the
chapter title and a bold folio, "Figure 3 on page 5" cross-references,
syntax diagrams and a generated index.

It is the look of the books that is copied, not their file format: the
sources are Typst, and the output is PDF.

## Layout

```
bookmaster.typ          the template -- import it from a book
fonts/                  IBM Plex Serif, Sans and Mono (SIL OFL, see OFL.txt)
tools/check-syntax.py   checks that every joint of a syntax diagram meets
sample/                 a sample: parts of the cc370 Command Reference
```

## Building

```sh
brew install typst      # or a release binary from github.com/typst/typst
make                    # check the diagrams, build sample/ml01-0002.pdf
```

Always pass `--font-path` pointing at `fonts/` and `--ignore-system-fonts`, so
a build sets the same pages on every host:

```sh
typst compile --root . --font-path fonts --ignore-system-fonts sample/ml01-0002.typ
```

## Using it in a project

Add this repository as a submodule beside the book sources, for example
`doc/book/bookmaster`, and start the book with

```typst
#import "bookmaster/bookmaster.typ": *

#show: book.with(
  title: "cc370 Cross-Toolchain for MVS 3.8j",
  subtitle: "Command Reference",
  short-title: "cc370 Command Reference",
  number: "ML01-0002-0",
  date: "October 2026",
  authors: ("Mike Großmann",),
  edition: [ ... ],
)

#contents()
#figures()

#heading(numbering: none)[About This Book]
...

#mainmatter()
#set page(numbering: "1")

= The cc370 Command
...

#heading(numbering: none)[Index]
#make-index()
```

`sample/ml01-0002.typ` uses every element and is the worked example.

## Elements

| Call | Gives |
|---|---|
| `= Title` / `==` / `===` | chapter (new right-hand page, heavy rule), section (hairline), subsection |
| `cmd("-o")`, `var("file")` | a command or option as typed (bold mono), a variable (italic mono) |
| `fig(caption: [...])[...]` | a figure: rules above and below, "Figure n." caption underneath |
| `tab(caption: [...])[table(...)]` | a table, "Table n." caption on top |
| `code(src, numbers: true)` | a program source or listing, optionally with line numbers |
| `screen(...)` | a framed terminal session |
| `syntax(src)`, `syntax(title: "Option:", src)` | a syntax diagram (below) |
| `deflist(...)` | a two-column definition list |
| `note[...]` | a run-in **Note:** |
| `idx("term")`, `idx("term", "subterm")` | an index entry for the current page |
| `#show: appendices` | the chapters after it are numbered "Appendix A.", "Appendix B." ... |
| `contents(depth: 2)` | a shallower table of contents (default 3), for a reference with many entries |
| `@label` | "Figure 3 on page 5", "“Section” on page 5", "Chapter 2, “Title”" -- the page is left out when the target is on the same page |

### Syntax diagrams

A diagram is written as text with box-drawing characters and drawn with
ruled lines on a character grid, so the joints meet whatever the font:

```
            ┌────────────────┐
            ▼                │
►►──as370───┬────────────────┼──«source-file»──►◄
            └─┤ Option ├─────┘
```

`«…»` marks a variable, set in italics; the guillemets take no column. A lone
`├` or `┤` is a fragment bracket and is drawn as a short tick. Keep diagrams in
files of their own and run `tools/check-syntax.py` over them -- a joint one
column off is easy to write and hard to see in the source.

## Document numbers

`ML` (mvslovers), a two-digit area, a four-digit serial, and the edition:
`ML01-0002-0` is the Draft of book 0002 in area 01, `ML01-0002-1` its first
edition.

**One area per product, assigned up front**, so a number never depends on
the order in which books get written. Within an area, serial 0001 is the
guide and 0002 the reference; further volumes count on. A product without a
row gets an area when its first book starts: add the row here first.

| Area | Product | Books |
|---|---|---|
| ML01 | cc370 and libc370 | ML01-0001 cc370 User's Guide, ML01-0002 cc370 Command Reference, ML01-0003 libc370 Programmer's Guide, ML01-0004 libc370 Library Reference |
| ML02 | mbt (version 3) | planned |
| ML03 | BREXX/370 | ML03-0001 User's Guide, ML03-0002 Reference, ML03-0003 Library and Samples -- in preparation |
| ML04 | rexx370 | planned |
| ML05 | ufsd | planned |
| ML06 | ftpd | planned |
| ML07 | httpd and its modules | planned; httprexx and httplua from ML07-0003 |
| ML08 | mvsMF | planned |

## License

The template, the tools and the sample are under the MIT License, see
`LICENSE`. The IBM Plex fonts in `fonts/` are under the SIL Open Font License
1.1, see `fonts/OFL.txt`.

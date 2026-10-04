// bookmaster.typ -- a BookMaster / SCRIPT/VS look for the mvslovers manuals.
//
// Style only: Times body, Helvetica headings, a heavy rule over each chapter
// title and a hairline over each section, figures framed by rules with the
// caption below, running footers carrying the chapter title and a bold folio,
// "Figure n on page p" cross-references, and a generated index.

// IBM Plex (SIL Open Font License), shipped in fonts/ and passed with
// --font-path, so a build on any host sets the same pages.
#let body-font = ("IBM Plex Serif",)
#let head-font = ("IBM Plex Sans",)
#let mono-font = ("IBM Plex Mono",)

// ---------------------------------------------------------------- inline ---

// A command, keyword or option as it is typed: bold monospace.
#let cmd(x) = text(font: mono-font, weight: "bold", size: 0.88em, hyphenate: false, x)
// A variable the reader supplies: italic monospace.
#let var(x) = text(font: mono-font, style: "italic", size: 0.88em, hyphenate: false, x)

// ----------------------------------------------------------------- index ---

// idx("term") or idx("term", "subterm"): marks the current page for the index.
#let idx(..t) = [#metadata(t.pos()) <bm-idx>]

#let make-index() = context {
  let marks = query(<bm-idx>)
  let entries = (:)
  for m in marks {
    let key = m.value.join("\u{1F}")
    let p = counter(page).at(m.location()).first()
    let have = entries.at(key, default: (terms: m.value, pages: (), locs: ()))
    if p not in have.pages {
      have.pages.push(p)
      have.locs.push(m.location())
    }
    entries.insert(key, have)
  }
  let keys = entries.keys().sorted(key: k => lower(k))
  let letter = none
  set par(justify: false, spacing: 0pt, leading: 0.45em)
  columns(2, gutter: 0.35in)[
    #let parent = none
    #for k in keys {
      let e = entries.at(k)
      let first = upper(e.terms.first().codepoints().filter(c => c != "-").first())
      if first != letter {
        letter = first
        block(above: 1.1em, below: 0.6em, sticky: true,
          text(font: head-font, weight: "bold", size: 11pt, letter))
      }
      let folios = e.locs.zip(e.pages).map(((l, p)) => link(l, str(p))).join(", ")
      if e.terms.len() > 1 {
        // A subentry whose main entry has no page of its own still needs it.
        if parent != e.terms.first() {
          block(above: 0.35em, below: 0pt, e.terms.first())
        }
        parent = e.terms.first()
        block(above: 0.35em, below: 0pt, inset: (left: 2.2em), [#h(-1em)#e.terms.last()#h(0.6em)#folios])
      } else {
        parent = e.terms.first()
        block(above: 0.35em, below: 0pt, inset: (left: 1em), [#h(-1em)#e.terms.first()#h(0.6em)#folios])
      }
    }
  ]
}

// -------------------------------------------------------------- elements ---

// A note in the BookMaster form: "Note:" in bold, run in.
#let note(body) = block(above: 1em, below: 1em)[*Note:* #body]

// A definition list: the term in a hanging column, bold monospace by default.
#let deflist(width: 1.25in, ..items) = {
  let pairs = items.pos()
  grid(
    columns: (width, 1fr),
    column-gutter: 0.15in,
    row-gutter: 0.9em,
    ..pairs
  )
}

// A framed screen or session: a light box, monospace, nothing reflowed.
#let screen(body) = block(
  width: 100%, inset: (x: 10pt, y: 8pt), radius: 3pt, stroke: 0.6pt,
  { set par(justify: false); text(font: mono-font, size: 8pt, body) })

// A program source or listing: monospace, nothing reflowed, optionally with
// line numbers in a column of their own.
#let code(src, numbers: false, size: 8pt) = {
  set par(justify: false, leading: 0.42em, spacing: 0.42em)
  set text(font: mono-font, size: size)
  let lines = src.trim("\n", at: end).split("\n")
  if numbers {
    grid(columns: (2.6em, auto), column-gutter: 1em, row-gutter: 0.42em,
      ..lines.enumerate().map(((i, l)) => (align(right, str(i + 1)), l)).flatten())
  } else {
    lines.join(linebreak())
  }
}

// A syntax diagram.  The diagram is written as text on a character grid with
// box-drawing characters; it is drawn with ruled lines, so the joints meet
// whatever the font.  A «word» is a variable and is set in italics.
#let _arms = (
  "─": (l: true, r: true), "│": (u: true, d: true),
  "┌": (d: true, r: true), "┐": (d: true, l: true),
  "└": (u: true, r: true), "┘": (u: true, l: true),
  "├": (u: true, d: true, r: true), "┤": (u: true, d: true, l: true),
  "┬": (l: true, r: true, d: true), "┴": (l: true, r: true, u: true),
  "┼": (l: true, r: true, u: true, d: true),
)
#let syntax(title: none, size: 8pt, framed: true, src) = {
  let cw = size * 0.6
  let rh = size * 1.55
  let lw = 0.55pt
  // Split each row into cells of (char, italic).
  let rows = src.trim("\n", at: end).split("\n").map(l => {
    let cells = ()
    let it = false
    for c in l.clusters() {
      if c == "«" { it = true } else if c == "»" { it = false } else { cells.push((c, it)) }
    }
    cells
  })
  let ncol = calc.max(..rows.map(r => r.len()))
  let grid-box = box(width: ncol * cw, height: rows.len() * rh, {
    for (y, row) in rows.enumerate() {
      for (x, (c, ital)) in row.enumerate() {
        let x0 = x * cw
        let y0 = y * rh
        let cx = x0 + cw / 2
        let cy = y0 + rh / 2
        let seg(a, b) = place(top + left, line(start: a, end: b, stroke: lw))
        if c in _arms {
          let a = _arms.at(c)
          if a.at("l", default: false) { seg((x0, cy), (cx, cy)) }
          if a.at("r", default: false) { seg((cx, cy), (x0 + cw, cy)) }
          // A vertical arm is drawn only where the neighbouring cell takes
          // it up; a lone ├ or ┤ is a fragment bracket, drawn as a short tick.
          let at(yy) = if yy >= 0 and yy < rows.len() and x < rows.at(yy).len() { rows.at(yy).at(x).first() } else { " " }
          let up = a.at("u", default: false) and at(y - 1) in "│┌┐├┤┬┼▼"
          let dn = a.at("d", default: false) and at(y + 1) in "│└┘├┤┴┼▼"
          if up { seg((cx, y0), (cx, cy)) }
          if dn { seg((cx, cy), (cx, y0 + rh)) }
          if (c == "├" or c == "┤") and not up and not dn {
            seg((cx, cy - rh * 0.3), (cx, cy + rh * 0.3))
          }
        } else if c == "▼" {
          seg((cx, y0), (cx, y0 + rh))
          place(top + left, dx: cx - cw * 0.32, dy: y0 + rh * 0.62,
            polygon(fill: black, (0pt, 0pt), (cw * 0.64, 0pt), (cw * 0.32, rh * 0.38)))
        } else if c == "►" {
          seg((x0, cy), (x0 + cw, cy))
          place(top + left, dx: x0, dy: cy - rh * 0.17,
            polygon(fill: black, (0pt, 0pt), (cw * 0.8, rh * 0.17), (0pt, rh * 0.34)))
        } else if c == "◄" {
          seg((x0, cy), (x0 + cw * 0.2, cy))
          place(top + left, dx: x0 + cw * 0.2, dy: cy - rh * 0.17,
            polygon(fill: black, (cw * 0.8, 0pt), (0pt, rh * 0.17), (cw * 0.8, rh * 0.34)))
        } else if c != " " {
          place(top + left, dx: x0, dy: y0, box(width: cw, height: rh,
            align(center + horizon, text(size: size, style: if ital { "italic" } else { "normal" }, c))))
        }
      }
    }
  })
  if not framed { return box(baseline: rows.len() * rh * 0.32, { set text(font: mono-font); grid-box }) }
  block(width: 100%, inset: (x: 10pt, y: 9pt), stroke: 0.6pt, breakable: false, {
    set text(font: mono-font)
    if title != none {
      block(below: 0.5em, text(font: head-font, weight: "bold", size: 8.5pt, title))
    }
    grid-box
  })
}

// ---------------------------------------------------------------- the book --

#let book(
  title: "",
  subtitle: "",
  short-title: "",
  number: "",
  date: "",
  authors: (),
  edition: [],
  body,
) = {
  set document(title: title + ": " + subtitle, author: authors)
  set text(font: body-font, size: 10pt, lang: "en", hyphenate: true)
  set par(justify: true, leading: 0.52em, spacing: 1.15em)

  // Running footers: odd pages carry the chapter title, even pages the book.
  let folio = context {
    let p = counter(page).get().first()
    let shown = counter(page).display()
    let chapters = query(heading.where(level: 1)).filter(
      h => h.location().page() <= here().page())
    let chap = if chapters.len() > 0 {
      let h = chapters.last()
      if h.numbering != none {
        [Chapter #counter(heading).at(h.location()).first(). #h.body]
      } else { h.body }
    } else { [] }
    set text(font: head-font, size: 8.5pt)
    if calc.odd(here().page()) {
      align(right)[#chap#h(1.2em)#text(weight: "bold", size: 11pt, shown)]
    } else {
      align(left)[#text(weight: "bold", size: 11pt, shown)#h(1.2em)#short-title]
    }
  }

  set page(
    paper: "us-letter",
    margin: (inside: 1in, outside: 1in, top: 0.9in, bottom: 1.05in),
    footer: folio,
    footer-descent: 40%,
  )

  // Raw text: monospace, a little smaller than the body.
  show raw: set text(font: mono-font, size: 0.85em, hyphenate: false)
  show raw.where(block: true): it => block(
    width: 100%, inset: (left: 1.2em, y: 0.2em), { set par(justify: false); it })

  set list(indent: 0.4em, body-indent: 0.7em, marker: ([•], [–]))
  set enum(indent: 0.4em, body-indent: 0.7em)

  // Headings.
  set heading(numbering: (..n) => if n.pos().len() == 1 { "Chapter " + str(n.pos().first()) + ". " })
  show heading: set text(font: head-font, weight: "regular")
  show heading.where(level: 1): it => {
    pagebreak(to: "odd", weak: true)
    v(0.55in)
    block(below: 2.2em, {
      // The heavy rule spans the title, as BookMaster's head level 1 does.
      let t = if it.numbering != none { [#counter(heading).display(it.numbering)#it.body] } else { it.body }
      context {
        let w = measure(text(font: head-font, size: 22pt, t)).width
        block(below: 0.35em, line(length: calc.min(w, 6.5in), stroke: 4pt))
      }
      text(font: head-font, size: 22pt, t)
    })
  }
  show heading.where(level: 2): it => block(above: 2em, below: 1.1em, sticky: true, {
    line(length: 100%, stroke: 0.6pt)
    v(-0.35em)
    text(size: 15pt, weight: "bold", it.body)
  })
  show heading.where(level: 3): it => block(above: 1.6em, below: 0.9em, sticky: true,
    text(size: 11.5pt, weight: "bold", it.body))
  show heading.where(level: 4): it => block(above: 1.3em, below: 0.8em, sticky: true,
    text(font: body-font, size: 10.5pt, weight: "bold", it.body))

  // Figures: a rule above and below, caption under it; tables carry theirs on top.
  set figure(gap: 0.7em)
  show figure.where(kind: "fig"): it => block(above: 1.4em, below: 1.4em, breakable: false, {
    line(length: 100%, stroke: 0.6pt)
    v(0.4em)
    align(left, it.body)
    v(0.3em)
    line(length: 100%, stroke: 0.6pt)
    v(0.2em)
    align(center, it.caption)
  })
  show figure.where(kind: table): it => block(above: 1.4em, below: 1.4em, breakable: false, {
    align(left, it.caption)
    v(0.3em)
    it.body
  })
  show figure.caption: it => text(size: 9.5pt)[#it.supplement #context it.counter.display(it.numbering). #it.body]
  set table(stroke: (x, y) => (
    top: if y == 0 { 1.2pt } else if y == 1 { 0.9pt } else { 0.4pt },
    bottom: 1.2pt, left: none, right: none))
  show table.cell.where(y: 0): set text(font: head-font, weight: "bold", size: 9pt)
  set table(inset: (x: 6pt, y: 5pt), align: left)

  // Cross-references in the BookMaster form.
  show ref: it => {
    let el = it.element
    if el == none { return it }
    let p = counter(page).at(el.location()).first()
    // BookMaster leaves out "on page n" when the target is on this page.
    let on = if el.location().page() == here().page() { [] } else { [ on page #p] }
    if el.func() == figure {
      let n = el.counter.at(el.location()).first()
      link(el.location())[#el.supplement #n#on]
    } else if el.func() == heading {
      if el.level == 1 and el.numbering != none {
        let n = counter(heading).at(el.location()).first()
        link(el.location())[Chapter #n, “#el.body”#on]
      } else {
        link(el.location())[“#el.body”#on]
      }
    } else { it }
  }

  // Contents: spaced dot leaders, chapters set off.
  set outline.entry(fill: box(width: 1fr, repeat(gap: 0.45em)[.]))
  show outline.entry.where(level: 1): it => {
    if it.element.func() == heading { block(above: 1.1em, strong(it)) }
    else { block(above: 0.5em, link(it.element.location(),
      it.indented([#it.element.counter.at(it.element.location()).first().], it.inner(), gap: 0.6em))) }
  }

  // ---------------------------------------------------------- title page --
  page(footer: none, {
    v(1.4in)
    align(right, {
      text(font: head-font, weight: "bold", size: 21pt, title)
      linebreak()
      text(font: head-font, weight: "bold", size: 21pt, subtitle)
      v(0.8in)
      set text(font: head-font, size: 10.5pt)
      [Document Number #number]
      v(0.35in)
      date
      v(0.35in)
      authors.join(linebreak())
    })
  })

  // ------------------------------------------------------ edition notice --
  page(footer: none, {
    v(1fr)
    set text(size: 9.5pt)
    edition
  })

  counter(page).update(1)
  set page(numbering: "i")
  body
}

// The switch from front matter to the body: arabic folios from 1.
#let mainmatter() = {
  pagebreak(to: "odd", weak: true)
  counter(page).update(1)
  set page(numbering: "1")
}

#let contents() = {
  heading(numbering: none, outlined: false)[Contents]
  outline(title: none, depth: 3, target: heading.where(outlined: true))
}

#let figures() = {
  heading(numbering: none, outlined: true)[Figures]
  outline(title: none, target: figure.where(kind: "fig"))
  v(1em)
  heading(level: 2, numbering: none, outlined: false)[Tables]
  outline(title: none, target: figure.where(kind: table))
}

// fig(caption, body) and tab(caption, body): BookMaster figures and tables.
#let fig(caption: [], body) = figure(body, caption: caption, kind: "fig", supplement: [Figure])
#let tab(caption: [], body) = figure(body, caption: caption, kind: table, supplement: [Table])

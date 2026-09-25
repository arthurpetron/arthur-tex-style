# Changelog

## Unreleased — extracted to its own repository

Extracted from `codynamic-book-machine:docs/arthur_tex_style` so the class can be
consumed as a submodule by more than one project and improved in one place.

### Fixed

Six layout bugs in `arthur-book.cls`, all visible in any document built with it.

- **Odd-page header geometry.** The page-number box and the full-bleed rule both
  landed mid-page on odd pages. `fancyhdr` right-aligns whatever sits in the `R`
  slot, which silently re-bases every `\makebox[0pt][l]` offset onto the header's
  *right* edge instead of its left. Odd-page content now lives in the left-origin
  `LO` slot, so one origin serves both parities, and the run to the paper edge is
  computed as `\paperwidth-\oddsidemargin-1in-\arthur@pageboxinset` with `\llap`
  hanging the box back so its right edge meets the inset.
- **Dangling separator in the running head.** `\arthur@path` emitted a `→` before
  every non-empty level, so any document without a chapter — that is, any report
  or any front matter — opened its header with a leading arrow. The separator is
  now emitted only once something precedes it.
- **Page number stated twice.** `\fancyfoot[C]{\thepage}` removed; the header box
  states it once.
- **Page box inside the unprintable border.** The box sat 2pt from the trim, which
  most printers clip. New length `\arthur@pageboxinset`, default `3pc`. The rule
  keeps its own, much smaller `\arthur@headruleinset` (2pt), since the rule is
  meant to reach the trim.
- **Header rule's near end wandered from page to page.** `\rlap` measures from
  the current horizontal position, and the rule was emitted *after* the running-head
  label, whose width varies with the section title — so the rule's near end moved by
  the width of that text (measured at 58pt, 69pt and 166pt from the trim on three
  consecutive pages of one document). The rule is now emitted first in its header
  field, from the field origin. The earlier `\vspace`-based implementation had hidden
  this by forcing a line break, which reset the position by accident.
- **Header rule now keeps a deliberate gap from the page box.** New length
  `\arthur@headrulegap`, default `1pc`: the rule runs from the far trim to one pica
  short of the box, on whichever side the box is, so the gap is identical on every
  page instead of the rule passing behind the box.
- **Header rule met the box only approximately.** The rule is now offset by the
  box's measured depth (`\dp`) rather than a `\baselineskip` guess, so the rule's
  top edge is flush with the box's bottom edge at any type size. `\rlap` and a
  `[0pt][0pt]` raisebox keep it out of the header's height so it cannot push the
  text block down, and `headheight` under `wide-notes` is now `1.3\baselineskip`,
  which also silences a `fancyhdr` warning.
- **Margin notes on the wrong side of even pages.** Two independent mechanisms had
  to be pinned. `\marginpar`, used by `marginfigure`, switches to the outer margin
  under `twoside` — fixed with `\@mparswitchfalse`. `marginnote`, used by
  `\shortcite`, `\marginkey` and the notation environments, ignores that switch
  and decides from `\if@twoside` and page parity, aiming for the left margin on
  even pages where the asymmetric `wide-notes` layout reserves nothing, so the
  note ran off the paper: `\@mn@margintest` is now wrapped to force the right
  margin, scoped to `wide-notes` only so the symmetric presets keep the
  conventional alternation.

### Fixed — the Codynamic mark

`\codynmark` drew a black square with a single white circle in it, whatever
arguments it was given. Three separate operations were dead, and each one hid
the next.

- **Every ring landed on the first one.** The radius was accumulated inside the
  loop body, `\pgfmathsetmacro{\r}{\r-(#3+#4)}`, but `\foreach` scopes its
  body, so `\r` was restored to its initial value on each iteration and all
  `rings` circles were drawn at the same radius. The radius is now computed from
  the loop counter, `\R-w/2-(k-1)(w+g)`, which needs no state to survive the
  scope.
- **The band was drawn black on black.** `\fill[black]` for the split ran
  *before* the rings, over a square that was already black. The band is meant to
  punch through the rings, so it is now filled after them.
- **The bleed arcs were drawn white on white.** They were drawn immediately
  after each full white circle, at the same radius and width, so they covered
  nothing but themselves. They now come last, after the band, which is the only
  order in which they do what their name says: reach back over the band edge so
  the right-hand ring ends stay attached.

Two guards were added with them. A ring whose radius has gone negative — easy to
ask for, since `rings * (w + g)` can exceed `D/2` — is skipped instead of drawn
inside out, and a ring narrower than the band is skipped rather than passed to
`acos` outside `[-1,1]`.

### Fixed — margin citations

`\shortcite` produced a margin entry in a hand-assembled title-then-author order
that matches no published style, which contradicted this module's own promise to
leave the bibliography style to the document. It now renders the entry with
biblatex's own bibliography driver via `\usedriver`, so the margin carries a real
reference-list entry in whatever style the document loaded — MLA, Chicago,
authoryear. Verified against `biblatex-mla` (MLA 9th edition).

Four bugs surfaced by that change:

- **Not `\fullcite`.** `biblatex-mla` redefines `\fullcite` to a title-only
  citation, so the obvious implementation yields nothing resembling a
  works-cited entry. `\usedriver{}{\thefield{entrytype}}` invokes the driver the
  reference list itself uses. The driver is called *without*
  `\DeclareNameAlias{sortname}{default}`, so the leading name stays inverted and
  the margin entry reads exactly like its Works Cited counterpart.
- **`\shortcite{key}[20]` came out as a bare "(20)".** The optional arguments were
  declared `O{}`, so an argument the author omitted was passed as *empty* rather
  than absent, and `biblatex-mla` reads a present-but-empty prenote as "the author
  is already named in the sentence" and suppresses it. Declared `o` now, with the
  four cases branched explicitly.
- **The in-text citation lost its author on first use.** biblatex tracks previous
  citations globally, and MLA legitimately shortens a repeat of the same source to
  a page number — so rendering the margin entry *before* the citation made the
  citation think the work had already been cited. The citation is emitted first.
- **Repeated-author dash leaked both ways.** A margin entry whose author matched
  the previous one printed MLA's `———.`, and the last margin entry on a page left
  its author behind so the reference list opened with a dash instead of a name.
  `\bbx@lasthash` and `\cbx@lasthash` are now cleared before *and* after each
  margin entry; both are set `\global` by the style, so the reset has to be too.

Also: the margin entry is set `\normalfont`, so a citation inside a `theorem` or
`definition` no longer inherits that environment's italic; and `\finentry`
supplies the terminal period that `\usedriver` alone omits.

### Added — one queue for margin material

New module `tex/arthur-margins.sty`. `marginnote` places a note at its anchor and
keeps no record of what is already there, so two anchors on the same line put two
notes in the same place — a `\shortcite` beside a `\marginnote` simply overprinted.
`\marginpar` does stack, but only against other `\marginpar`s, and it is illegal
inside floats, footnotes and math, which is why this class uses `marginnote`.

`\arthurmarginnote` gives every piece of margin material one queue: it walks the
items in document order, keeps the bottom edge reached so far on the current page,
and pushes an item down by exactly its overlap. `\marginnote` is routed through it,
so `\shortcite`, `\marginkey`, the notation environments and hand-written notes all
participate; `marginfigure` now uses it too instead of `\marginpar`, which also
makes margin figures legal inside floats and footnotes.

An item's true position is not known while it is typeset — it depends on where the
page breaks — so each anchor drops a zref label and the geometry is read back on
the next run. The first run places notes unstacked and asks for a rerun; latexmk
does that unprompted. It converges in two runs and stays converged, because
pushing an item down moves no anchor: margin material is set with `\rlap` and
contributes nothing to the main vertical list.

Configurable with `\arthurmarginsep` (gap between items, default
`0.7\baselineskip`) and `\arthurmarginfoot` (warn below this, default
`2\baselineskip`). Both resolve at `\begin{document}`, since `\baselineskip` is
0pt while the preamble is read.

Four traps met on the way, recorded because each would silently return:

- `\marginnotetextwidth` is **not** the note's width — it is `\textwidth`, used as a
  kern to skip past the text column. Content is set at `\marginparwidth`. Measuring
  at the wrong width underestimated every height and the stack still overlapped.
- `\zref@labelbylist` records the page but no position; `\zref@savepos` must emit
  the primitive whatsit first. Without it every `posy` came back 0, and one zero
  dragged the whole page's stack off the paper.
- Measuring means typesetting, so a `\caption` inside a `marginfigure` stepped the
  float counter twice and left a hole in the figure numbering. Counters named in
  `\arthurmargincounters` are saved and restored around the measurement.
- That save/restore cannot be built as a token list with `\xdef` and `\noexpand`:
  `calc` makes `\setcounter` robust, so `\noexpand` protects only its shell and
  calc's internals execute while the list is being built. Values are stashed in
  per-counter macros instead.

### Fixed — margin citations on a clean first pass

`\shortcite` aborted the run on a first pass, before biber had produced any data:
`entrytype` is empty then, and `\usedriver` called an undefined driver. It now
prints nothing until the data exists.

### Unchanged, deliberately

The header rule is full-bleed by design, and the page box alternates left/right by
parity. Both look like bugs and are not.

### Notes

New lengths, tunable in a document preamble: `\arthur@pageboxinset` (`3pc`),
`\arthur@headruleinset` (`2pt`), `\arthur@headrulewd` (`0.4pt`).

A document with no chapters will still number sections `0.1` and equations and
theorems `0.0.1`, since the class numbers within chapter and section. Consuming
packages can set `\setcounter{secnumdepth}{0}` with `\renewcommand{\theequation}
{\arabic{equation}}` and `\renewcommand{\thetheorem}{\arabic{theorem}}`; a
`report` class option would be a reasonable future addition.

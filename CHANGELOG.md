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

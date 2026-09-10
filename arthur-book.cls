% !TEX root = arthur-book.cls
% !TEX encoding = UTF-8 Unicode
% arthur-book.cls
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{arthur-book}[2025/09/03 Arthur's constructive book class]

% ---------- Options ----------
\newif\ifarthur@tight
\newif\ifarthur@print
\newif\ifarthur@widenotes
\DeclareOption{tight}{\arthur@tighttrue\arthur@printfalse\arthur@widenotesfalse}
\DeclareOption{print}{\arthur@tightfalse\arthur@printtrue\arthur@widenotesfalse}
\DeclareOption{wide-notes}{\arthur@tightfalse\arthur@printfalse\arthur@widenotestrue}
\DeclareOption*{} % ignore unknown
\ExecuteOptions{tight} % default
\ProcessOptions\relax

% ---------- Base class ----------
% Keep it flexible: book, but openany, twoside so we control paging & headers.
\LoadClass[11pt,openany,twoside]{book}

% ---------- Required packages ----------
\RequirePackage{etoolbox}
\RequirePackage{geometry}
\RequirePackage{fancyhdr}
\RequirePackage{titlesec}
\RequirePackage{titletoc}
\RequirePackage{microtype}
\RequirePackage{ifthen}
\RequirePackage{calc}
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{mathtools}
\RequirePackage{hyperref}
\hypersetup{hidelinks}

% ---------- Geometry presets ----------
% tight  : ~36pt side margins, compact top/bottom
% print  : comfortable book-ish margins
% wide-notes : Tufte-like outer margin for sidenotes
\ifarthur@tight
  \geometry{
    paperwidth=8.5in,paperheight=11in,
    inner=36pt, outer=36pt,
    top=36pt, bottom=48pt,
    headheight=18pt, headsep=18pt, footskip=18pt,
    includehead, includefoot
  }
\fi
\ifarthur@print
  \geometry{
    paperwidth=8.5in,paperheight=11in,
    inner=28mm, outer=32mm,
    top=24mm, bottom=28mm,
    headheight=18pt, headsep=18pt, footskip=20pt,
    includehead, includefoot
  }
\fi
\ifarthur@widenotes
  % Tufte-like letterpaper layout:
  % textwidth=26pc, marginparsep=2pc, marginparwidth=12pc.
  \geometry{
    letterpaper,
    left=1in,
    top=1in,
    textwidth=26pc,
    marginparsep=2pc,
    marginparwidth=12pc,
    textheight=44\baselineskip,
    % The head must clear the page-number box, which is taller than a line of
    % type: \normalsize digits plus 2pt of \fboxsep and 0.4pt of rule, top and
    % bottom. A one-line headheight makes fancyhdr warn and overprints the rule.
    headheight=1.3\baselineskip,
    headsep=2\baselineskip,
    footskip=2\baselineskip,
    asymmetric
  }
\makeatletter
  \@mparswitchfalse
\makeatother
\fi

% ---------- Depth of numbering (Arthur wants details!) ----------
\setcounter{secnumdepth}{6}
\setcounter{tocdepth}{6}

% ---------- Remove forced page clears around \chapter ----------
\makeatletter
\pretocmd{\chapter}{\@afterindentfalse}{}{}
\patchcmd{\chapter}{\if@openright\cleardoublepage\else\clearpage\fi}{}{}{}
\patchcmd{\@chapter}{\clearpage}{}{}{}
\patchcmd{\@schapter}{\clearpage}{}{}{}
\makeatother

% ---------- Chapter/Section formatting ----------
\titleformat{\chapter}[hang]
  {\huge\bfseries}
  {\thechapter\;\;\rule[-0.3ex]{.5pt}{1.25em}}
  {1em}
  {\Huge}
  [\vspace{0.5ex}\rule{\textwidth}{0.5pt}\vspace{0.75ex}]
\titlespacing*{\chapter}{0pt}{1.2ex plus .3ex}{1.0ex}

\titleformat{\section}[hang]
  {\Large\bfseries}
  {\thesection}{0.6em}{}
\titlespacing*{\section}{0pt}{1.0ex plus .2ex}{0.5ex}

\titleformat{\subsection}[hang]
  {\large\bfseries}
  {\thesubsection}{0.5em}{}
\titlespacing*{\subsection}{0pt}{0.8ex plus .2ex}{0.4ex}

\titleformat{\subsubsection}[runin]
  {\normalsize\bfseries}
  {\thesubsubsection}{0.5em}{}[.]

% ---------- TOC: compact dotted leaders ----------
\contentsmargin{2em}
\dottedcontents{chapter}[0em]{}{\dimexpr1.5em+1.5ex}{0.8em}
\dottedcontents{section}[1.6em]{}{\dimexpr2.3em+1.5ex}{0.8em}
\dottedcontents{subsection}[3.2em]{}{\dimexpr3.1em+1.5ex}{0.8em}
\dottedcontents{subsubsection}[4.8em]{}{\dimexpr3.9em+1.5ex}{0.8em}
\dottedcontents{subsubsubsection}[6.4em]{}{\dimexpr4.7em+1.5ex}{0.8em}

% ---------- Header path: chapter --> section --> subsection ----------
% We'll track current chapter/section/subsection titles and compose a path.
\makeatletter
\newcommand*\arthur@chapname{}
\newcommand*\arthur@secname{}
\newcommand*\arthur@subsecname{}
\newcommand*\arthur@subsubsecname{}
\newcommand*\arthur@subsubsubsecname{}
\renewcommand{\chaptermark}[1]{%
  \gdef\arthur@chapname{#1}%
  \gdef\arthur@secname{}%
  \gdef\arthur@subsecname{}%
  \gdef\arthur@subsubsecname{}%
  \gdef\arthur@subsubsubsecname{}%
}
\renewcommand{\sectionmark}[1]{%
  \gdef\arthur@secname{#1}%
  \gdef\arthur@subsecname{}%
  \gdef\arthur@subsubsecname{}%
  \gdef\arthur@subsubsubsecname{}%
}
\renewcommand{\subsectionmark}[1]{%
  \gdef\arthur@subsecname{#1}%
  \gdef\arthur@subsubsecname{}%
  \gdef\arthur@subsubsubsecname{}%
}
\renewcommand{\subsubsectionmark}[1]{%
  \gdef\arthur@subsubsecname{#1}%
  \gdef\arthur@subsubsubsecname{}%
}
\newcommand{\subsubsubsectionmark}[1]{\gdef\arthur@subsubsubsecname{#1}}
% The separator is emitted *before* an item only once something precedes it,
% so a document with no chapter (any report, or front matter) does not open its
% header with a dangling arrow.
\newcommand{\arthur@pathsep}{}
\newcommand{\arthur@pathitem}[1]{%
  \ifx#1\@empty\else
    \arthur@pathsep #1%
    \renewcommand{\arthur@pathsep}{\,{\footnotesize$\rightarrow$}\,}%
  \fi
}
\newcommand{\arthur@path}{%
  \begingroup
  \renewcommand{\arthur@pathsep}{}%
  \arthur@pathitem\arthur@chapname
  \arthur@pathitem\arthur@secname
  \arthur@pathitem\arthur@subsecname
  \arthur@pathitem\arthur@subsubsecname
  \arthur@pathitem\arthur@subsubsubsecname
  \endgroup
}
\makeatother

% ---------- Page number box helper ----------
\makeatletter
% Inset of the page-number box from the paper edge. Not flush with the trim:
% anything closer than a couple of picas is liable to be clipped by a printer's
% unprintable border, and looks like a mistake even when it survives.
\newlength{\arthur@pageboxinset}
\setlength{\arthur@pageboxinset}{3pc}
% Inset of the full-bleed header rule. Deliberately much smaller than the box
% inset: the rule is meant to run to the trim.
\newlength{\arthur@headruleinset}
\setlength{\arthur@headruleinset}{2pt}
\newlength{\arthur@headrulewd}
\setlength{\arthur@headrulewd}{0.4pt}
\newsavebox{\arthur@pbbox}
\newcommand{\arthur@pagebox}{%
  \begingroup
  \setlength\fboxsep{2pt}%
  \setlength\fboxrule{0.4pt}%
  \fbox{\normalsize\thepage}%
  \endgroup
}

% ---------- Full-bleed header rule ----------
% Runs to \arthur@headruleinset from each paper edge, with its top edge flush
% against the bottom edge of the page-number box, so the rule and the box meet
% exactly instead of approximately. The offset is measured from the box itself
% (\dp) rather than guessed from \baselineskip, so it holds at any type size.
% \rlap and the [0pt][0pt] raisebox keep the rule out of the header's height
% calculation, so it cannot push the text block down.
\newcommand{\arthur@headrule}{%
  \sbox\arthur@pbbox{\arthur@pagebox}%
  \rlap{%
    \hspace*{\dimexpr -\oddsidemargin-1in+\arthur@headruleinset}%
    \raisebox{-\dimexpr\dp\arthur@pbbox+\arthur@headrulewd\relax}[0pt][0pt]{%
      \rule{\dimexpr \paperwidth-2\arthur@headruleinset}{\arthur@headrulewd}%
    }%
  }%
}
\newcommand{\arthur@headerlabel}{\raisebox{0.45ex}{\textsc{\small \arthur@path}}}

% ---------- Headers/footers ----------
\pagestyle{fancy}
\fancyhf{} % clear

% Page box at the absolute left paper edge on even pages, the absolute right
% paper edge on odd pages, with the section path at the text edge and the
% full-bleed rule beneath both.
%
% Both fields are placed in the *left* slot on purpose. fancyhdr right-aligns
% whatever sits in the R slot, which silently re-bases every \makebox[0pt][l]
% offset below onto the header's right edge instead of its left — that put the
% page box and the full-bleed rule mid-page on odd pages under the asymmetric
% wide-notes geometry. Keeping one origin for both parities keeps the offsets
% honest, and the paper-edge arithmetic is then the same on every page.
\fancyhead[LE]{%
  % Page box inset \arthur@pageboxinset from the left paper edge.
  \makebox[0pt][l]{\hspace*{\dimexpr -\evensidemargin-1in+\arthur@pageboxinset}\arthur@pagebox}%
  \quad\arthur@headerlabel
  \arthur@headrule
}
\fancyhead[LO]{%
  % Page box inset \arthur@pageboxinset from the right paper edge: the origin is
  % (\oddsidemargin+1in) from the paper's left edge, so the run to the right
  % edge is \paperwidth minus that origin. \llap hangs the box back so its
  % right edge, not its left, meets the 2pt inset.
  \makebox[0pt][l]{%
    \hspace*{\dimexpr \paperwidth-\oddsidemargin-1in-\arthur@pageboxinset}%
    \llap{\arthur@pagebox}}%
  \arthur@headerlabel
  \arthur@headrule
}
% One path header per page: duplicating inner and outer headers makes long
% section paths collide in the compact layouts.
\fancyhead[RE]{}
\fancyhead[RO]{}

% No footer page number: the header box states the page once. Two page numbers
% on one page is redundant ink.
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}
\makeatother

% ---------- Title page ----------
\makeatletter
\ifarthur@widenotes
\newcommand{\arthur@fullwidth@geometry}{%
  \newgeometry{
    left=1in,
    right=1in,
    top=1in,
    bottom=1in,
    headheight=\baselineskip,
    headsep=2\baselineskip,
    footskip=2\baselineskip
  }%
}
  \let\arthur@book@maketitle\maketitle
  \renewcommand{\maketitle}{%
    \arthur@fullwidth@geometry
    \arthur@book@maketitle
    \restoregeometry
  }%
  \let\arthur@book@tableofcontents\tableofcontents
  \renewcommand{\tableofcontents}{%
    \clearpage
    \arthur@fullwidth@geometry
    \arthur@book@tableofcontents
    \clearpage
    \restoregeometry
  }%
\fi
\makeatother

% ---------- Arthur modules ----------
% ---------- Margin side ----------
% The wide-notes geometry is asymmetric: the margin column is on the right of
% every page, odd and even alike. A twoside class, however, switches marginpars
% into the *outer* margin, which on an even page is the left — where this layout
% reserves no space, so the note runs off the paper. Pin them to one side.
\makeatletter
\@mparswitchfalse
\makeatother
\normalmarginpar

\RequirePackage{tex/arthur-symbols}
\RequirePackage{tex/arthur-math}
\RequirePackage{tex/arthur-notation}
\RequirePackage{tex/arthur-margin-citations}
\RequirePackage{tex/arthur-figures}
\RequirePackage{tex/arthur-tikz}

% ---------- Margin side, part two ----------
% \@mparswitchfalse above governs \marginpar (so marginfigure is fixed), but
% marginnote — which \shortcite, \marginkey and the notation environments all
% use — decides its own side from \if@twoside and page parity and ignores that
% switch. On an even page it aims for the outer margin, which is the left, where
% the asymmetric wide-notes layout reserves nothing: the note then runs off the
% paper edge. \@mn@margintest is what sets the flag (true = right margin), so
% run it and then force the answer. Only under wide-notes: the symmetric presets
% want the conventional alternating behaviour.
\makeatletter
\ifarthur@widenotes
  \@ifundefined{@mn@margintest}{}{%
    \let\arthur@mn@margintest\@mn@margintest
    \renewcommand{\@mn@margintest}{\arthur@mn@margintest\@tempswatrue}%
  }%
\fi
\makeatother

% ---------- End class ----------

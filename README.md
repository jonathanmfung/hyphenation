# hyphenation

[![Package Version](https://img.shields.io/hexpm/v/hyphenation)](https://hex.pm/packages/hyphenation)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/hyphenation/)

Knuth–Liang Hyphenation.

```sh
gleam add hyphenation
```
```gleam
import gleam/string
import gleam/list
import gleam/io

import hyphenation
import hyphenation/language

pub fn main() {
 let word = "hyphenation"

 let hyphenator = hyphenation.hyphenator(language.EnglishUS)

 hyphenation.hyphenate(word, hyphenator)
 |> io.debug
 // ["hy", "phen", "ation"]

 let text =
   "Gleam is a friendly language for building type-safe systems that scale!
The power of a type system, the expressiveness of functional programming,
and the reliability of the highly concurrent, fault tolerant Erlang runtime,
with a familiar and modern syntax."

 text
 |> string.split(" ")
 |> list.map(hyphenation.hyphenate_delim(_, hyphenator, "‧"))
 |> string.join(" ")
 |> io.print
 // "Gleam is a friendly lan‧guage for build‧ing type‧-safe sys‧tems that scale!
 // The power of a type sys‧tem, the ex‧pres‧sive‧ness of func‧tional pro‧gram‧ming,
 // and the re‧li‧a‧bil‧ity of the highly con‧cur‧rent, fault tol‧er‧ant Er‧lang run‧time,
 // with a fa‧mil‧iar and mod‧ern syn‧tax."
}
```

Further documentation can be found at <https://hexdocs.pm/hyphenation>.

## Development
Run `download_patterns.sh` to download all TeX patterns.

Then `gleam run -m hyphenation/internal/codegen` to update generated gleam files.

## TODO

- [X] Add option to return parts list
    - `hyphenate` vs `hyphenate_delim`
- [ ] Clean up pattern code to use `Pattern`
- [ ] Maybe refactor language handling (metadata, codegen)
- [ ] Incorporate other languages
    - Improved codegen for copyright, licenses.
- [ ] Respect existing hyphens (ex: "compile-time")
    - see: https://github.com/ekmett/hyphenation/issues/16
- [ ] Benchmark
- [ ] Convert `Patterns` implementation to trie for faster lookup

## Out of Scope
- Handling punctuation (e.g. .,!?), this library works on the word-level.

## References
- [Liang's Thesis](https://www.tug.org/docs/liang/liang-thesis.pdf)
- [hyphenation.org](https://www.hyphenation.org/)
- [Haskell Implemenation](https://github.com/ekmett/hyphenation)
- [Apache FOP Wiki](https://cwiki.apache.org/confluence/display/XMLGRAPHICSFOP/AutomaticHyphenation)

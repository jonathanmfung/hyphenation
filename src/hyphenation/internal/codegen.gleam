// gleam run -m hyphenation/internal/codegen

import gleam/io
import gleam/list
import gleam/result
import gleam/string
import hyphenation/internal/metadata.{metadata}
import language.{type Language}
import simplifile

// generation disclaimer
// in-file license (manual map like metadata)
// patterns
// exceptions
pub fn main() {
  io.print("from internal/codegen")

  let lang = language.EnglishUS
  let #(patterns_path, exceptions_path, out_path) = filepaths(lang)

  use patterns_str <- result.map(simplifile.read(from: patterns_path))
  use exceptions_str <- result.map(simplifile.read(from: exceptions_path))
  let patterns = gen(patterns_str, Patterns)
  let exceptions = gen(exceptions_str, Exceptions)

  let res =
    [
      disclaimer(lang),
      copyright(lang),
      license_text(license(lang)),
      patterns,
      exceptions,
    ]
    |> string.join("\n\n")
  // TODO handle failure, any of the 3 paths not existing
  let assert Ok(Nil) = simplifile.write(to: out_path, contents: res)
}

// TODO could probably just copy tex files
// extract comments, then remove \patterns{, }, \hyphenation{
// match on
// TODO though tex sometimes aren't newlined https://github.com/hyphenation/tex-hyphen/blob/master/hyph-utf8/tex/generic/hyph-utf8/patterns/tex/hyph-grc.tex
// while text always seems to be newlines

fn gen(raw_str: String, c: Content) -> String {
  let constant = case c {
    Patterns -> "patterns"
    Exceptions -> "exceptions"
  }

  let transform = fn(pattern) {
    case c {
      // "pat3tern"
      Patterns -> "\"" <> pattern <> "\","
      // #("pattern", "pat-tern")
      Exceptions -> {
        "#(\""
        <> string.replace(pattern, "-", "")
        <> "\","
        <> "\""
        <> pattern
        <> "\"),"
      }
    }
  }

  let content =
    raw_str
    |> string.split("\n")
    // Remove empty string from trailing newline
    |> list.filter(fn(x) { x != "" })
    |> list.map(transform)
    |> string.join("\n")

  string.join(["pub const " <> constant <> " = [", content, "]"], "\n")
}

fn disclaimer(l: Language) -> String {
  // TODO append "hyph-en-us.txt" to links
  "//  This file was generated from ./src/hyphenation/internal/codegen.gleam
//  Data is sourced from:
//  Patterns and Exceptions - https://ctan.org/tex-archive/language/hyph-utf8/tex/generic/hyph-utf8/patterns/txt
//  License Info - https://ctan.org/tex-archive/language/hyph-utf8/tex/generic/hyph-utf8/patterns/tex"
}

fn copyright(l: Language) -> String {
  case l {
    language.EnglishUS ->
      "//  Copyright (C) 1990, 2004, 2005 Gerard D.C. Kuiken"
  }
}

fn license(l: Language) -> License {
  case l {
    language.EnglishUS -> OtherFree
    // language.Bulgarian -> BSD
  // language.Macedonian -> GPL
  }
}

fn license_text(l: License) -> String {
  case l {
    MIT ->
      "//  License: MIT (https://opensource.org/licenses/MIT)
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  \"Software\"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
//  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE."
    OtherFree ->
      "//  Copying and distribution of this file, with or without modification,
//  are permitted in any medium without royalty provided the copyright
//  notice and this notice are preserved"
    // LPPL -> todo
    // GPL -> todo
    // Unlicense -> todo
    _ -> ""
  }
}

type License {
  MIT
  LPPL
  GPL
  OtherFree
  Unlicense
}

type Content {
  Patterns
  Exceptions
}

/// Returns paths for (patterns, exceptions, out)
fn filepaths(l: Language) -> #(String, String, String) {
  let abbrev = metadata(l).abbreviation

  // TODO some languages don't have exceptions
  let patterns = "tex-hyphen/hyph-" <> abbrev <> ".pat.txt"
  let exceptions = "tex-hyphen/hyph-" <> abbrev <> ".hyp.txt"

  let out =
    "src/hyphenation/internal/data/"
    <> string.replace(abbrev, each: "-", with: "_")
    <> ".gleam"

  #(patterns, exceptions, out)
}

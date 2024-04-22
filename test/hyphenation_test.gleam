import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import hyphenation
import hyphenation/internal/patterns
import hyphenation/language

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn parse_reference_test() {
  "3foo."
  // |> pattern.parse_reference
  // |> should.equal(pattern.Pattern(["f", "o", "o"], [3, 0, 0, 0]))
}

pub fn insert_reference_test() {
  patterns.insert_reference(
    patterns.new_patterns(),
    patterns.Pattern(["a"], [0, 0]),
  )
  |> should.equal(patterns.Patterns([#(["a"], [0, 0]), #([], [])]))
}

pub fn conseq_sublist_test() {
  ["a", "b", "c"]
  |> patterns.conseq_sublist
  |> should.equal([
    #(0, ["a"]),
    #(0, ["a", "b"]),
    #(0, ["a", "b", "c"]),
    #(1, ["b"]),
    #(1, ["b", "c"]),
    #(2, ["c"]),
  ])
}

pub fn update_score_test() {
  [0, 0, 0]
  |> patterns.update_score([1, 0], 1)
  |> should.equal([0, 1, 0])

  [0, 0, 0]
  |> patterns.update_score([1, 0], 1)
  |> patterns.update_score([2], 2)
  |> should.equal([0, 1, 2])

  [0, 0, 0]
  |> patterns.update_score([1, 0], 1)
  |> patterns.update_score([2], 2)
  |> patterns.update_score([3, 0], 1)
  |> should.equal([0, 3, 2])
}

pub fn hyphenator_hyphenate_test() {
  let hyphenator = hyphenation.hyphenator(language.EnglishUS)
  ""
  |> hyphenation.hyphenate(hyphenator)
  |> should.equal([""])

  "parameter"
  |> hyphenation.hyphenate(hyphenator)
  |> should.equal(["pa", "ra", "me", "ter"])

  "hyphenation"
  |> hyphenation.hyphenate(hyphenator)
  |> should.equal(["hy", "phen", "ation"])

  "supercalifragilisticexpialadocious"
  |> hyphenation.hyphenate(hyphenator)
  |> should.equal([
    "su", "per", "cal", "ifrag", "ilis", "tic", "ex", "pi", "al", "ado", "cious",
  ])

  "systems"
  |> hyphenation.hyphenate(hyphenator)
  |> should.equal(["sys", "tems"])

  "reliability"
  |> hyphenation.hyphenate(hyphenator)
  |> should.equal(["re", "li", "a", "bil", "ity"])

  "ab"
  |> hyphenation.hyphenate(hyphenator)
  |> should.equal(["ab"])
}

pub fn hyphenate_test() {
  [#("a", 0), #("b", 2), #("c", 3), #("d", 0)]
  |> patterns.hyphenate
  |> should.equal(["ab", "cd"])

  [#("a", 0), #("b", 0)]
  |> patterns.hyphenate
  |> should.equal(["ab"])

  [#("c", 1), #("d", 0)]
  |> patterns.hyphenate
  |> should.equal(["cd"])
}

pub fn readme_test() {
  let word = "hyphenation"

  let hyphenator = hyphenation.hyphenator(language.EnglishUS)

  hyphenation.hyphenate(word, hyphenator)
  |> should.equal(["hy", "phen", "ation"])

  let text =
    "Gleam is a friendly language for building type-safe systems that scale!
    The power of a type system, the expressiveness of functional programming,
    and the reliability of the highly concurrent, fault tolerant Erlang runtime,
    with a familiar and modern syntax."

  text
  |> string.split(" ")
  |> list.map(hyphenation.hyphenate_delim(_, hyphenator, "‧"))
  |> string.join(" ")
}

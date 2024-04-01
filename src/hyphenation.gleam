import gleam/io
import gleam/int
import gleam/string
import gleam/result
import gleam/list
import simplifile
import pattern.{type Input, type Pattern, type Reference}

pub fn main() {
  io.println("Hello from hyphenation!")
  // should be [3, 0, 0, 2, 0]
  "3fo2o."
  |> pattern.parse_reference()
  |> io.debug

  "param4"
  |> pattern.parse_reference()
  |> io.debug

  "para"
  |> pattern.new
  |> io.debug
  // https://mirrors.mit.edu/CTAN/language/hyph-utf8/tex/generic/hyph-utf8/patterns/txt/hyph-en-us.pat.txt

  // TODO need to remove dangling newline, which creates empty pattern
  let assert Ok(patterns_str) =
    simplifile.read(from: "./data/hyph-en-us.pat.txt")
  patterns_str
  |> string.split("\n")
  |> list.map(pattern.parse_reference)
  |> list.fold(pattern.new_patterns(), pattern.insert_reference)
  |> pattern.get_pattern_score(["p", "a", "r", "a", "m"])
  |> io.debug
}

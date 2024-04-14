import gleam/int
import gleam/result
import gleam/string
import gleam/list
import gleam/io
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import simplifile

pub opaque type Input {
  Input
}

pub opaque type Reference {
  Reference
}

pub type Pattern(source) {
  // Scores should be 1 longer than List(String), for beg/end
  Pattern(graphemes: List(String), scores: List(Int))
}

pub type Patterns {
  Patterns(List(#(List(String), List(Int))))
}

fn pattern_to_tuple(p: Pattern(t)) -> #(List(String), List(Int)) {
  #(p.graphemes, p.scores)
}

/// Lookup the score of a pattern, if it exists
pub fn get_pattern_score(
  ps: Patterns,
  p: List(String),
) -> Result(List(Int), Nil) {
  let Patterns(ls) = ps
  list.key_find(ls, p)
}

pub fn new_patterns() -> Patterns {
  Patterns([#([], [])])
}

pub fn insert_reference(ps: Patterns, p: Pattern(t)) -> Patterns {
  // convert s to pattern?
  let ref =
    p
    |> pattern_to_tuple
  let Patterns(ls) = ps
  Patterns([ref, ..ls])
}

pub fn parse_reference(s: String) -> Pattern(Reference) {
  // TODO handle "."?
  let is_not_digit = fn(x) {
    x
    |> int.parse
    |> result.is_error
  }
  let new_s =
    s
    |> string.to_graphemes
    |> list.filter(is_not_digit)
  Pattern(graphemes: new_s, scores: score_reference(s))
}

// from ekmett
fn score_reference(s: String) -> List(Int) {
  // TOOD incorrectly scores "param4" as [0,0,0,0,0], should be [0,0,0,0,4]
  case string.pop_grapheme(s) {
    // empty string
    Error(Nil) -> []
    Ok(#(x, xs)) -> {
      case int.parse(x) {
        Error(Nil) -> [0, ..score_reference(xs)]
        Ok(n) ->
          case string.pop_grapheme(xs) {
            Error(Nil) -> [n]
            Ok(#(_, ys)) -> [n, ..score_reference(ys)]
          }
      }
    }
  }
}

pub fn new(s: String) -> Pattern(Input) {
  // TODO need to add . to input in both front and back?
  let new_s = string.to_graphemes(s)
  let l = list.length(new_s)
  let empty_score = list.repeat(0, l + 1)
  Pattern(graphemes: new_s, scores: empty_score)
}

pub fn main() {
  let assert Ok(patterns) = read_patterns("./data/hyph-en-us.pat.txt")

  let hyphenated = process("systems", patterns)

  string.join(hyphenated, "‧")
  |> io.debug
}

/// Hyphenate a string under a given set of patterns.
///
/// Output is list of substrings, split where hyphens should be inserted.
///
/// ## Example
///
/// ```gleam
/// new() |> insert("a", 0)
/// // -> from_list([#("a", 0)])
/// ```
///
pub fn process(s: String, ps: Patterns) -> List(String) {
  let pattern =
    s
    |> new
  let res_score = process_input(pattern, ps)

  let hyphenated = hyphenate(list.zip(pattern.graphemes, res_score))
}

pub fn process_input(s: Pattern(Input), patterns: Patterns) -> List(Int) {
  let subs: List(#(Int, List(String))) =
    s.graphemes
    |> conseq_sublist()

  subs
  |> list.fold(s.scores, fn(old_score, ind_substring) {
    case get_pattern_score(patterns, ind_substring.1) {
      Ok(new_score) -> update_score(old_score, new_score, ind_substring.0)
      Error(Nil) -> old_score
    }
  })
}

pub fn hyphenate(ls: List(#(String, Int))) -> List(String) {
  do_hyphenate(ls, [])
}

fn do_hyphenate(ls: List(#(String, Int)), acc: List(String)) -> List(String) {
  let extract_string = fn(list) {
    list
    |> list.map(fn(t: #(String, Int)) { t.0 })
    |> string.concat
  }

  // Check if head is already odd, otherwise recursion will drop head
  let #(head, new_ls) = case ls {
    [] -> #(#("", 0), [])
    [x, ..xs] ->
      case int.is_odd(x.1) {
        True -> #(x, xs)
        False -> #(#("", 0), [x, ..xs])
      }
  }

  // TODO last letter is being dropped if odd
  //       because split_while is not inclusive
  // update 240413: ??????
  let split = list.split_while(new_ls, fn(t) { int.is_even(t.1) })

  // io.println_error("head:\t" <> string.inspect(head))
  // io.println_error("new_ls:\t" <> string.inspect(new_ls))
  // io.println_error("split:\t" <> string.inspect(split))
  // io.println_error("acc:\t" <> string.inspect(acc))
  // io.println("")

  case split {
    #([], rest) -> {
      case rest {
        [] -> list.append(acc, [head.0])
        // Odd head creates a singleton
        [x, ..xs] -> {
          case int.is_odd(head.1) {
            True -> do_hyphenate([x, ..xs], list.append(acc, [head.0]))
            False -> do_hyphenate(xs, list.append(acc, [head.0 <> x.0]))
          }
        }
      }
    }
    #(syllable, []) -> list.append(acc, [head.0 <> extract_string(syllable)])
    #(syllable, rest) -> {
      do_hyphenate(rest, list.append(acc, [head.0 <> extract_string(syllable)]))
    }
  }
}

// fn split_while_incl(ls: List(a), f: fn(a) -> Bool) -> #(List(a), List(a)) {
//   let #(left, right) = list.split_while(ls, f)
//   case right {
//     [] -> #(left, right)
//     [x, ..xs] -> #(list.append(left, [x]), xs)
//   }
// }

/// Generate Patterns from a patgen file.
///
/// ## Example
///
/// ```gleam
/// let assert Ok(patterns) = read_patterns("./data/hyph-en-us.pat.txt")
/// ```
///
pub fn read_patterns(file: String) -> Result(Patterns, simplifile.FileError) {
  use patterns_str <- result.map(simplifile.read(from: file))

  patterns_str
  |> string.split("\n")
  |> list.map(parse_reference)
  |> list.fold(new_patterns(), insert_reference)
}

/// Merge two scores, the input string's and a new Pattern's.
pub fn update_score(old: List(Int), new: List(Int), padding: Int) -> List(Int) {
  // should change everything to Pattern?
  let pad_left_new = list.append(list.repeat(0, padding), new)
  let pad_right = list.repeat(0, list.length(old) - list.length(pad_left_new))
  let padded_new = list.append(pad_left_new, pad_right)
  list.map2(old, padded_new, int.max)
}

/// Generate all consecutive (inclusive) sublists of a list.
///
/// Int is an indicator of where the sublist starts in the input list.
///
/// ## Example
///
/// ```gleam
/// conseq_sublist(["a", "b", "c"])
/// // -> [
/// //      #(0, ["a"]),
/// //      #(0, ["a", "b"]),
/// //      #(0, ["a", "b", "c"]),
/// //      #(1, ["b"]),
/// //      #(1, ["b", "c"]),
/// //      #(2, ["c"]),
/// //    ]
/// ```
///
pub fn conseq_sublist(l: List(a)) -> List(#(Int, List(a))) {
  // do_conseq_sublist, but for all tails
  l
  // could also use string.drop_left/right
  // abcd -> [abcd, bcd, cd, d]
  // keep drop index for aligning
  |> list.index_map(fn(_, i) {
    list.drop(l, i)
    |> do_conseq_sublist
    |> list.map(fn(subl) { #(i, subl) })
  })
  |> list.concat
}

/// TODO (Docs) Generate all ??? sublists of a list.
///
/// ## Example
///
/// ```gleam
/// conseq_sublist(["a", "b", "c"])
/// // -> [
/// //      ["a"],
/// //      ["a", "b"],
/// //      ["a", "b", "c"],
/// //    ]
/// ```
///
fn do_conseq_sublist(l: List(a)) -> List(List(a)) {
  // Could also use string.drop_left/right
  l
  |> list.index_map(fn(_x, i) { list.take(l, i + 1) })
}

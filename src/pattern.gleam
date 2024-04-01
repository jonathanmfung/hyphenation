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

// trie from ekmett
// type Patterns {
//   Patterns(List(Int), Patterns)
// }

pub type Pattern(source) {
  // Scores should be 1 longer than List(String), for beg/end
  Pattern(graphemes: List(String), scores: List(Int))
}

// pub type Patterns {
//   Patterns(scores: List(Int), map: Dict(String, Patterns))
// }

// prototyping definition, simple list dict
pub type Patterns {
  Patterns(List(#(List(String), List(Int))))
}

fn pattern_to_tuple(p: Pattern(t)) -> #(List(String), List(Int)) {
  #(p.graphemes, p.scores)
}

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
  // do_insert_reference(Some(p), ref, p.scores)
}

fn do_insert_reference(
  p: Option(Patterns),
  ref: Pattern(Reference),
  scores: List(Int),
) -> Patterns {
  todo
  // case p {
  //   Some(p) ->
  //     case ref.graphemes, p {
  //       [], Patterns(_, m) -> Patterns(ref.scores, m)
  //       [x, ..xs], Patterns(n, m) ->
  //         Patterns(
  //           n,
  //           // should ignores old key value, just replace with do_insert_reference(xs)
  //           dict.update(in: m, update: x, with: do_insert_reference(
  //             _,
  //             parse_reference(string.concat(xs)),
  //             scores,
  //           )),
  //         )
  //     }
  //   // Some runs f new_k old_k
  //   // None just inserts (new_k, new_v) (x, mk xs)
  //   None -> construct_node(ref, scores)
  // }
}

fn construct_node(ref: Pattern(Reference), scores: List(Int)) -> Patterns {
  todo
  // case ref.graphemes {
  //   [] -> Patterns(scores, dict.new())
  //   [x, ..xs] ->
  //     Patterns(
  //       [],
  //       dict.new()
  //         |> dict.insert(
  //           x,
  //           construct_node(parse_reference(string.concat(xs)), scores),
  //         ),
  //     )
  // }
}

// a = foldr insertPattern mempty ["a2f", "3foo.", "1a"]
// -- Patterns []
// -- 	(fromList [
// --         ('a',Patterns [1,0] (fromList [('f',Patterns [0,2,0] (fromList []))])),
// --         ('f',Patterns [] (fromList [
// --         	('o',Patterns [] (fromList [
// --                 	('o',Patterns [] (fromList [
// --                         	('.',Patterns [3,0,0,0,0] (fromList []))]))]))]))])

// -- . a f o o .
// -- . a2f
// --    3f o o .
// --  1a
// -- .1a3f o o .

// -- Patterns [Int] (IM.IntMap Patterns)
// -- [Int] is score vector, only present IFF node is terminal
// --       length is length of terminal string + 1
// -- key of map is character
// -- value of map is new node

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

fn empty() -> Pattern(Reference) {
  Pattern([], [])
}

pub fn new(s: String) -> Pattern(Input) {
  // TODO need to add . to input in both front and back?
  let new_s = string.to_graphemes(s)
  let l = list.length(new_s)
  let empty_score = list.repeat(0, l + 1)
  Pattern(graphemes: new_s, scores: empty_score)
}

// output is pattern of orig string
fn score(inp: String, ptns: List(Pattern(Reference))) -> Pattern(Input) {
  todo
  // orig_pattern: Pattern(Reference) = Pattern(orig_string, [0,0,0,0,...])
  // list.fold(orig_pattern, ptns, empty, do_score)
}

pub fn main() {
  // parameter -> pa-ra-me-ter
  // hyphenation -> hy-phen-ation
  // supercalifragilisticexpialadocious -> su-per-cal-ifrag-ilis-tic-ex-pi-al-ado-cious
  let pattern =
    "supercalifragilisticexpialadocious"
    |> new

  let assert Ok(patterns) = read_patterns("./data/hyph-en-us.pat.txt")

  let res_score =
    process_input(pattern, patterns)
    |> io.debug

  let hyphenated =
    hyphenate(pattern.graphemes, res_score, "-")
    |> io.debug
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

pub fn hyphenate(
  graphemes: List(String),
  scores: List(Int),
  delim: String,
) -> String {
  let add_hyphen = fn(grapheme: String, score: Int) {
    case int.is_odd(score) {
      True -> grapheme <> delim
      False -> grapheme
    }
  }
  // TODO there has to be a better function than drop(1)
  // list.rest returns a Result
  list.map2(graphemes, list.drop(scores, 1), add_hyphen)
  |> string.concat
}

pub fn read_patterns(file: String) -> Result(Patterns, simplifile.FileError) {
  use patterns_str <- result.map(simplifile.read(from: file))

  patterns_str
  |> string.split("\n")
  |> list.map(parse_reference)
  |> list.fold(new_patterns(), insert_reference)
}

pub fn update_score(old: List(Int), new: List(Int), padding: Int) -> List(Int) {
  // should change everything to Pattern?
  let pad_left_new = list.append(list.repeat(0, padding), new)
  let pad_right = list.repeat(0, list.length(old) - list.length(pad_left_new))
  let padded_new = list.append(pad_left_new, pad_right)
  list.map2(old, padded_new, int.max)
}

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

fn do_conseq_sublist(l: List(a)) -> List(List(a)) {
  // abcd -> [a, ab, abc, abcd]
  // could also use string.drop_left/right
  l
  |> list.index_map(fn(_x, i) { list.take(l, i + 1) })
}

fn align_patterns(a: Pattern(_x), b: Pattern(_y)) -> #(Pattern(t), Pattern(t)) {
  // align sublist to list
  // this only triggers is sublist is matched to list

  // or can pad sublist to same length as list
  // or use context of list.drop to see position in list?
  todo
}

fn do_score(a: Pattern(_x), b: Pattern(_y)) -> List(Int) {
  // TODO need to pad/align b size to a
  list.map2(a.scores, b.scores, int.max)
}
// pub fn main() {
//   "abcd"
//   |> string.to_graphemes
//   |> conseq_sublist
//   |> list.map(string.concat)
//   |> io.debug
//   // Patterns([], dict.new())
//   // |> insert_reference("a2f")
//   // |> io.debug
//   // |> insert_reference("3foo.")
//   // |> io.debug
//   // |> insert_reference("1a")
//   // |> io.debug
// }
// import qualified Data.Map as IM
// import Prelude hiding (lookup)
// import Data.Char (digitToInt, isDigit)
// data Patterns = Patterns [Int] (IM.Map Char Patterns) deriving Show
// instance Semigroup Patterns where
//   Patterns ps m <> Patterns qs n = Patterns (zipMax ps qs) (IM.unionWith mappend m n)
// instance Monoid Patterns where
//   mempty = Patterns [] IM.empty
// insertPattern :: String -> Patterns -> Patterns
// insertPattern s0 = go (chars s0) where
//   pts = scorePattern s0
//   go [] (Patterns _ m) = Patterns pts m
//   go (x:xs) (Patterns n m) = Patterns n (IM.insertWith (\_ -> go xs) ( x) (mk xs) m)
//   mk []     = Patterns pts IM.empty
//   mk (x:xs) = Patterns [] (IM.singleton (x) (mk xs))
// parsePatterns :: String -> Patterns
// parsePatterns = foldr insertPattern mempty . lines
// chars :: String -> String
// chars = filter (\x -> x < '0' || x > '9')
// scorePattern :: String -> [Int]
// scorePattern [] = [0]
// scorePattern (x:ys)
//   | isDigit x = digitToInt x : case ys of
//                                  []    -> []
//                                  _:ys' -> scorePattern ys'
//   | otherwise = 0 : scorePattern ys
// zipMax :: [Int] -> [Int] -> [Int]
// zipMax (x:xs) (y:ys) = max x y : zipMax xs ys
// zipMax [] ys = ys
// zipMax xs [] = xs

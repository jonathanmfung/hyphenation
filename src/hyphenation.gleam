import gleam/list
import gleam/string
import hyphenation/internal/metadata
import hyphenation/internal/patterns.{type Patterns}
import hyphenation/language.{type Language}

/// Break a string into hyphenated parts, using a hyphenator.
/// ## Example
/// ```gleam
/// hyphenate("hyphenation", hyphenator(language.EnglishUS))
/// // -> ["hy", "phen", "ation"]
/// ```
pub fn hyphenate(s: String, h: Hyphenator) -> List(String) {
  // Respect min lengths
  //  do hyphenation on input
  //      then check if first and last length are < min_left/right
  //      if true, concat with next element
  let hyphenated = patterns.process(s, h.patterns)

  let is_min_left = case hyphenated {
    [] -> True
    [x, ..] -> string.length(x) < h.left_min
  }

  let hyphenated =
    case is_min_left {
      True -> {
        merge_two(hyphenated, string.append)
      }
      False -> hyphenated
    }
    |> list.reverse

  let is_min_right = case hyphenated {
    [] -> True
    [x, ..] -> string.length(x) < h.right_min
  }
  let hyphenated =
    case is_min_right {
      True -> {
        merge_two(hyphenated, fn(x, y) { string.append(y, x) })
      }
      False -> hyphenated
    }
    |> list.reverse
  hyphenated
}

fn merge_two(ls: List(a), f: fn(a, a) -> a) -> List(a) {
  case ls {
    [x, y, ..xs] -> [f(x, y), ..xs]
    _ -> ls
  }
}

/// Hyphenate a string using a hyphenator, delim is hyphen character.
/// ## Example
/// ```gleam
/// hyphenate_delim("hyphenation", hyphenator(language.EnglishUS), "-")
/// // -> "hy-phen-ation"
/// ```
pub fn hyphenate_delim(s: String, h: Hyphenator, delim: String) -> String {
  string.join(hyphenate(s, h), delim)
}

// TODO add exceptions, maybe normalization function
pub opaque type Hyphenator {
  Hyphenator(
    language: String,
    patterns: Patterns,
    left_min: Int,
    right_min: Int,
  )
}

/// Construct Hyphenator from desired language.
pub fn hyphenator(l: Language) -> Hyphenator {
  let md = metadata.metadata(l)
  let patterns = language.patterns(l)

  Hyphenator(md.abbreviation, patterns, md.left_min, md.right_min)
}

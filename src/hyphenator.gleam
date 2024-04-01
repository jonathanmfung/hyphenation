type Hyphenator {
  // language == patterns?
  Hyphenator(delim: String, language: String)
}

fn new_hyphenator() -> Hyphenator {
  Hyphenator("-", "en-us")
}

fn with_language(h: Hyphenator, l: String) -> Hyphenator {
  Hyphenator(..h, language: l)
}

fn hyphenate(h: Hyphenator, s: String) -> String {
  todo
}

import hyphenation/internal/data/en_us
import hyphenation/internal/patterns.{type Patterns}

pub type Language {
  EnglishUS
}

@internal
pub fn patterns(l: Language) -> Patterns {
  case l {
    EnglishUS -> en_us.patterns
  }
  |> patterns.from_codegen
}

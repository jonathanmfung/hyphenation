import language.{type Language}

/// Metadata for a Language
pub type Metadata {
  Metadata(abbreviation: String, left_min: Int, right_min: Int)
}

pub fn metadata(l: Language) -> Metadata {
  case l {
    language.EnglishUS -> Metadata("en-us", 2, 3)
  }
}

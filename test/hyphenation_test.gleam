import gleeunit
import gleeunit/should
import pattern

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
  pattern.insert_reference(
    pattern.new_patterns(),
    pattern.Pattern(["a"], [0, 0]),
  )
  |> should.equal(pattern.Patterns([#(["a"], [0, 0]), #([], [])]))
}

pub fn conseq_sublist_test() {
  ["a", "b", "c"]
  |> pattern.conseq_sublist
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
  |> pattern.update_score([1, 0], 1)
  |> should.equal([0, 1, 0])

  [0, 0, 0]
  |> pattern.update_score([1, 0], 1)
  |> pattern.update_score([2], 2)
  |> should.equal([0, 1, 2])

  [0, 0, 0]
  |> pattern.update_score([1, 0], 1)
  |> pattern.update_score([2], 2)
  |> pattern.update_score([3, 0], 1)
  |> should.equal([0, 3, 2])
}

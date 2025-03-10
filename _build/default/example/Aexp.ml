type aexp =
  | Intliteral of int
  | Plus of aexp * aexp
  | Minus of aexp * aexp
  | Times of aexp * aexp

let rec eval = function
  | Intliteral n -> n
  | Plus (a1, a2) -> eval a1 + eval a2
  | Minus (a1, a2) -> eval a1 - eval a2
  | Times (a1, a2) -> eval a1 * eval a2

(* =============================================================================
 * MINITYFUN TYPE CHECKER
 * =============================================================================
 *
 * This module implements a type checker for MiniTyFun, verifying that programs
 * are type-safe before execution. If a program type-checks, it's guaranteed
 * not to have runtime type errors.
 *
 * THE TYPE CHECKING ALGORITHM:
 * ----------------------------
 * The type_check function takes an environment (mapping variables to types)
 * and a term, and returns the type of that term. If the term is not well-typed,
 * it raises an exception.
 *
 * The algorithm walks the syntax tree recursively:
 * - Literals have their natural type (5 : Int, true : Bool)
 * - Variables lookup their type in the environment
 * - Operations check operand types and determine result type
 * - Functions create closure types from parameter and body types
 * - Applications check function type matches argument type
 *)

open MiniTyFunSyntax

(* -----------------------------------------------------------------------------
 * type_check_bin_op: Type check binary operations
 * -----------------------------------------------------------------------------
 *
 * Each operator has a type signature:
 * Plus, Minus, Times : Int × Int -> Int
 * Less : Int × Int -> Bool
 * And : Bool × Bool -> Bool
 *
 * We check that:
 * 1. The operands have the correct types for the operator
 * 2. Return the result type
 *
 * If the operands have wrong types, we fail with a runtime error.
 *)
let type_check_bin_op (operator : binary_op) (op1 : typ) (op2 : typ) =
  match (operator, op1, op2) with
  (* Type check that Plus, Minus, and Times are used with Int and return Int *)
  | (Plus | Minus | Times), Int, Int -> Int
  (* Type check that Less is used with Int and return Bool *)
  | Less, Int, Int -> Bool
  (* Type check that And is used with Bool and return Bool *)
  | And, Bool, Bool -> Bool
  | _ -> failwith "Invalid operation for the operands"


let type_check_unary_op (operator : unary_op) (op : typ) =
  match (operator, op) with
  (* Type check that Not is used with Bool and return Bool *)
  | Not, Bool -> Bool
  | _ -> failwith "Invalid operation for the operands"

let rec type_check (env : environment) = function
  | IntLit _ -> Int
  | BoolLit _ -> Bool
  | Var x -> (
      try EnvMap.find x env
      with Not_found -> failwith ("Undefined variable " ^ x)
    )
  | BinOp (t1, operator, t2) ->
      (* Type check both operands *)
      let op1 = type_check env t1 in
      let op2 = type_check env t2 in
      (* Check that the operator is valid for these types *)
      type_check_bin_op operator op1 op2
  | UnaryOp (operator, t) ->
      (* Type check operand *)
      let op = type_check env t in
      (* Check that the operator is valid for this type *)
      type_check_unary_op operator op
  | If (t1, t2, t3) -> (
      (* Both branches must have the same type *)
      match (type_check env t1, type_check env t2, type_check env t3) with
      | Bool, if_true, if_false -> (
          match if_true == if_false with
          | true -> if_true
          | false -> failwith "Branches of the if must return the same type"
        )
      | _ -> failwith "Condition of the if must be a boolean"
    )
  | Fun (x, x_type, t) ->
     (* Type check the body in an environment where x has this declared type *)
      Closure (x_type, type_check (EnvMap.add x x_type env) t)

  | FunApp (t1, t2) -> (
      match (type_check env t1, type_check env t2) with
      (* The function must have a Closure type *)
      | Closure (in_type, out_type), arg_type -> (
          (* The argument must match the parameter type *)
          match in_type == arg_type with
          | true -> out_type
          | false -> failwith "Function argument type does not match"
        )
      | _ -> failwith "Expected a function in the application"
    )

  | Let (x, t1, t2) -> 
      (* Type check the argument of the function, extend environment with 
       * the inferred type and type check body *)
      type_check (EnvMap.add x (type_check env t1) env) t2
  
  | LetFun (f, x, f_type, t1, t2) -> (
      match f_type with
      | Closure (in_type, out_type) -> (
          (* Type check the function body in an environment with both
             the function name (for recursion) and parameter bound *)
          let body_type =
            type_check (EnvMap.add x in_type (EnvMap.add f f_type env)) t1
          in
          (* Check that body type matches declared return type *)
          match body_type == out_type with
          | true -> type_check (EnvMap.add f f_type env) t2
          | false ->
              failwith
                "Function body type does not match the declared return type"
        )
      | _ -> failwith "LetFun requires a function type"
    )

(* -----------------------------------------------------------------------------
 * type_check_program: Entry point for type checking
 * -----------------------------------------------------------------------------
 *
 * Attempts to type check a program. Returns Some(type) if successful,
 * None if type checking fails.
 *
 * This wrapper catches exceptions from type_check and converts them to
 * option values, which is more convenient for testing and REPL usage.
 *
 * EXAMPLE:
 *   type_check_program (Fun("x", Int, BinOp(Var "x", Plus, IntLit 1)))
 *   => Some(Closure(Int, Int))
 *
 *   type_check_program (BinOp(IntLit 3, Plus, BoolLit true))
 *   => None (type error)
 *)
let type_check_program term =
  try Some (type_check EnvMap.empty term) with _ -> None

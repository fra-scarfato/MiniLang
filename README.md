# MiniLang

A collection of minimal programming language implementations demonstrating compiler construction, functional programming, and type systems.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OCaml](https://img.shields.io/badge/OCaml-5.0+-orange.svg)](https://ocaml.org/)

## Overview

MiniLang is a suite of three educational programming languages showcasing different paradigms and implementation techniques:

- **MiniImp** → **MiniRISC** Compiler: Optimizing compiler from imperative to RISC assembly
- **MiniFun**: Functional language interpreter with closures and recursion
- **MiniTyFun**: Statically-typed functional language with type checking

## Features

### MiniImp Compiler
- **Register Allocation**: Graph-coloring with coalescing and spilling
- **Optimizations**: Dead code elimination, peephole optimization, algebraic simplification
- **Dataflow Analysis**: Instruction-level liveness and definite variables analysis
- **Safety Checking**: Detects uninitialized variable usage
- **Pure Functional**: Immutable data structures throughout

### MiniFun Interpreter
- **First-Class Functions**: Functions as values with full closure support
- **Recursion**: Named recursive functions via `letfun`
- **Lexical Scoping**: Environment-based evaluation with closure capture
- **Dynamic Typing**: Type errors caught at runtime

### MiniTyFun Type Checker
- **Static Type Checking**: Catch errors before execution
- **Type Safety**: Well-typed programs guaranteed error-free
- **Explicit Annotations**: Function parameters require type declarations
- **Simple Type System**: Int, Bool, and function types (Closure)

## Installation

### Prerequisites

- OCaml (≥ 4.14.0)
- Dune (≥ 3.16)
- Menhir (parser generator)
- OCamllex (lexer generator)

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/MiniLang.git
cd MiniLang

# Build all executables
dune build

# Install (optional)
dune install
```

### Build Artifacts

After building, executables are available at:
- `_build/default/bin/MiniImpCompiler.exe`
- `_build/default/bin/MiniFunInterpreter.exe`
- `_build/default/bin/MiniImpInterpreter.exe`

## Usage

### MiniImp Compiler

Compile MiniImp programs to MiniRISC assembly:

```bash
# Basic compilation (4 registers)
dune exec MiniImpCompiler -- 4 examples/simple.minimp output.risc

# With optimizations
dune exec MiniImpCompiler -- -O 4 examples/simple.minimp output.risc

# With safety checking
dune exec MiniImpCompiler -- -s 4 examples/simple.minimp output.risc

# Verbose output
dune exec MiniImpCompiler -- -v -O 8 examples/simple.minimp output.risc
```

**Options:**
- `-s, --safety`: Check for uninitialized variables
- `-O, --optimize`: Enable register coalescing
- `-v, --verbose`: Show detailed compilation steps
- `-h, --help`: Display help message

### MiniFun Interpreter

Run functional programs with interactive input:

```bash
dune exec MiniFunInterpreter -- examples/factorial.minifun
# Enter an integer: 5
# Result: 120
```

### MiniImp Interpreter

Execute MiniImp programs directly (for testing):

```bash
dune exec MiniImpInterpreter -- examples/simple.minimp
# Enter an integer: 10
# Output: 55
```

## Language Specifications

### MiniImp: Imperative Language

MiniImp is a minimal imperative language with variables, arithmetic, conditionals, and loops.

#### Formal Grammar

```
Program P ::= def main with input x output y as C

Command C ::= skip                          (no operation)
            | x := O                        (assignment)
            | C₁ ; C₂                       (sequence)
            | if B then C₁ else C₂          (conditional)
            | while B do C                  (loop)

Operation O ::= n                           (integer constant)
              | x                           (variable)
              | O₁ + O₂                     (addition)
              | O₁ - O₂                     (subtraction)
              | O₁ * O₂                     (multiplication)

Boolean B ::= true | false                  (boolean literals)
            | O₁ < O₂                       (comparison)
            | B₁ and B₂                     (conjunction)
            | not B                         (negation)
```

#### Semantics

**Memory**: A mapping from variable names to integer values: `σ : String → Int`

**Operation Evaluation**: `⟦O⟧_σ → Int`

```
⟦n⟧_σ = n
⟦x⟧_σ = σ(x)
⟦O₁ + O₂⟧_σ = ⟦O₁⟧_σ + ⟦O₂⟧_σ
⟦O₁ - O₂⟧_σ = ⟦O₁⟧_σ - ⟦O₂⟧_σ
⟦O₁ * O₂⟧_σ = ⟦O₁⟧_σ × ⟦O₂⟧_σ
```

**Boolean Evaluation**: `⟦B⟧_σ → Bool`

```
⟦true⟧_σ = true
⟦false⟧_σ = false
⟦O₁ < O₂⟧_σ = ⟦O₁⟧_σ < ⟦O₂⟧_σ
⟦B₁ and B₂⟧_σ = ⟦B₁⟧_σ ∧ ⟦B₂⟧_σ
⟦not B⟧_σ = ¬⟦B⟧_σ
```

**Command Execution**: `⟨C, σ⟩ → σ'` (big-step semantics)

```
⟨skip, σ⟩ → σ

⟨x := O, σ⟩ → σ[x ↦ ⟦O⟧_σ]

⟨C₁ ; C₂, σ⟩ → σ''  where ⟨C₁, σ⟩ → σ' and ⟨C₂, σ'⟩ → σ''

⟨if B then C₁ else C₂, σ⟩ → σ'  where σ' = { ⟨C₁, σ⟩  if ⟦B⟧_σ = true
                                               { ⟨C₂, σ⟩  if ⟦B⟧_σ = false

⟨while B do C, σ⟩ → σ''  where σ'' = { σ                              if ⟦B⟧_σ = false
                                      { ⟨while B do C, σ'⟩ → σ''      if ⟦B⟧_σ = true and ⟨C, σ⟩ → σ'
```

#### Example Programs

**Sum from 1 to N:**
```
def main with input n output sum as
    sum := 0;
    i := 1;
    while not n < i do (
        sum := sum + i;
        i := i + 1
    );
```

**Factorial:**
```
def main with input n output fact as
    fact := 1;
    while not n < 2 do (
        fact := fact * n;
        n := n - 1
    );
```

### MiniFun: Functional Language

MiniFun is a dynamically-typed functional language with first-class functions, closures, and recursion.

#### Formal Grammar

```
Term t ::= n                                (integer literal)
         | true | false                     (boolean literals)
         | x                                (variable)
         | fun x -> t                       (lambda abstraction)
         | t₁ t₂                            (function application)
         | t₁ + t₂ | t₁ - t₂ | t₁ * t₂     (binary operations)
         | t₁ < t₂                          (comparison)
         | t₁ and t₂ | not t               (boolean operations)
         | if t₁ then t₂ else t₃           (conditional)
         | let x = t₁ in t₂                (local binding)
         | letfun f x = t₁ in t₂           (recursive function)
```

#### Semantics

**Environment**: A mapping from variable names to values: `ρ : String → Value`

**Values**:
```
Value v ::= n                               (integer)
          | true | false                    (boolean)
          | ⟨fun x -> t, ρ⟩                (closure: non-recursive)
          | ⟨letfun f x -> t, ρ⟩          (closure: recursive)
```

**Evaluation**: `ρ ⊢ t ⇓ v` (environment `ρ` evaluates term `t` to value `v`)

```
(Lit)
──────────────
ρ ⊢ n ⇓ n


(Var)   x ∈ dom(ρ)
──────────────────
ρ ⊢ x ⇓ ρ(x)


(Fun)
──────────────────────────────
ρ ⊢ fun x -> t ⇓ ⟨fun x -> t, ρ⟩


(App-NoRec)
    ρ ⊢ t₁ ⇓ ⟨fun x -> t, ρ'⟩
    ρ ⊢ t₂ ⇓ v₂
    ρ'[x ↦ v₂] ⊢ t ⇓ v
──────────────────────────────────
ρ ⊢ t₁ t₂ ⇓ v


(App-Rec)
    ρ ⊢ t₁ ⇓ ⟨letfun f x -> t, ρ'⟩
    ρ ⊢ t₂ ⇓ v₂
    ρ'[f ↦ ⟨letfun f x -> t, ρ'⟩][x ↦ v₂] ⊢ t ⇓ v
───────────────────────────────────────────────────────
ρ ⊢ t₁ t₂ ⇓ v


(BinOp)
    ρ ⊢ t₁ ⇓ v₁
    ρ ⊢ t₂ ⇓ v₂
    v = v₁ ⊕ v₂
──────────────────
ρ ⊢ t₁ ⊕ t₂ ⇓ v


(If-True)
    ρ ⊢ t₁ ⇓ true
    ρ ⊢ t₂ ⇓ v
─────────────────────────────
ρ ⊢ if t₁ then t₂ else t₃ ⇓ v


(If-False)
    ρ ⊢ t₁ ⇓ false
    ρ ⊢ t₃ ⇓ v
─────────────────────────────
ρ ⊢ if t₁ then t₂ else t₃ ⇓ v


(Let)
    ρ ⊢ t₁ ⇓ v₁
    ρ[x ↦ v₁] ⊢ t₂ ⇓ v
────────────────────────
ρ ⊢ let x = t₁ in t₂ ⇓ v


(LetFun)
    ρ[f ↦ ⟨letfun f x -> t₁, ρ⟩] ⊢ t₂ ⇓ v
────────────────────────────────────────────
ρ ⊢ letfun f x = t₁ in t₂ ⇓ v
```

#### Operator Precedence and Associativity

| Precedence | Operators | Associativity | Description |
|------------|-----------|---------------|-------------|
| 1 (lowest) | `and` | Right | Logical conjunction |
| 2 | `<` | Left | Comparison |
| 3 | `+`, `-` | Left | Addition, subtraction |
| 4 | `*` | Left | Multiplication |
| 5 | `not` | - | Logical negation (prefix) |
| 6 (highest) | function application | Left | Juxtaposition |

#### Example Programs

**Identity Function:**
```ocaml
fun x -> x
```

**Factorial:**
```ocaml
letfun factorial n =
    if n < 1 then 1 
    else n * factorial (n - 1)
in factorial
```

**Higher-Order Functions:**
```ocaml
let compose = fun f -> fun g -> fun x -> f (g x) in
let inc = fun x -> x + 1 in
let double = fun x -> x * 2 in
compose double inc
```

**Closures:**
```ocaml
let makeAdder = fun x -> fun y -> x + y in
let add10 = makeAdder 10 in
add10 5  (* Returns 15 *)
```

### MiniTyFun: Statically-Typed Functional Language

MiniTyFun extends MiniFun with static type checking. Programs are verified before execution.

#### Formal Grammar

```
Type τ ::= Int                              (integer type)
         | Bool                             (boolean type)
         | τ₁ -> τ₂                         (function type)

Term t ::= n                                (integer literal)
         | true | false                     (boolean literals)
         | x                                (variable)
         | fun (x : τ) -> t                 (typed lambda)
         | t₁ t₂                            (function application)
         | t₁ + t₂ | t₁ - t₂ | t₁ * t₂     (binary operations)
         | t₁ < t₂                          (comparison)
         | t₁ and t₂ | not t               (boolean operations)
         | if t₁ then t₂ else t₃           (conditional)
         | let x = t₁ in t₂                (local binding)
         | letfun f (x : τ₁ -> τ₂) = t₁ in t₂  (recursive function)
```

#### Type System

**Type Environment**: A mapping from variable names to types: `Γ : String → Type`

**Type Judgments**: `Γ ⊢ t : τ` (under environment `Γ`, term `t` has type `τ`)

```
(T-Int)
──────────────
Γ ⊢ n : Int


(T-Bool)
──────────────────────
Γ ⊢ true : Bool
Γ ⊢ false : Bool


(T-Var)   x : τ ∈ Γ
──────────────────────
Γ ⊢ x : τ


(T-Fun)
    Γ[x : τ₁] ⊢ t : τ₂
──────────────────────────────────
Γ ⊢ (fun (x : τ₁) -> t) : τ₁ -> τ₂


(T-App)
    Γ ⊢ t₁ : τ₁ -> τ₂
    Γ ⊢ t₂ : τ₁
──────────────────────
Γ ⊢ t₁ t₂ : τ₂


(T-BinOp-Arith)
    Γ ⊢ t₁ : Int
    Γ ⊢ t₂ : Int
    ⊕ ∈ {+, -, *}
──────────────────────
Γ ⊢ t₁ ⊕ t₂ : Int


(T-Less)
    Γ ⊢ t₁ : Int
    Γ ⊢ t₂ : Int
──────────────────────
Γ ⊢ t₁ < t₂ : Bool


(T-And)
    Γ ⊢ t₁ : Bool
    Γ ⊢ t₂ : Bool
──────────────────────
Γ ⊢ t₁ and t₂ : Bool


(T-Not)
    Γ ⊢ t : Bool
──────────────────────
Γ ⊢ not t : Bool


(T-If)
    Γ ⊢ t₁ : Bool
    Γ ⊢ t₂ : τ
    Γ ⊢ t₃ : τ
─────────────────────────────────
Γ ⊢ if t₁ then t₂ else t₃ : τ


(T-Let)
    Γ ⊢ t₁ : τ₁
    Γ[x : τ₁] ⊢ t₂ : τ
────────────────────────────
Γ ⊢ let x = t₁ in t₂ : τ


(T-LetFun)
    Γ[f : τ₁ -> τ₂][x : τ₁] ⊢ t₁ : τ₂
    Γ[f : τ₁ -> τ₂] ⊢ t₂ : τ
──────────────────────────────────────────────
Γ ⊢ letfun f (x : τ₁ -> τ₂) = t₁ in t₂ : τ
```

#### Type Safety

**Theorem (Type Safety)**: If `∅ ⊢ t : τ` and `∅ ⊢ t ⇓ v`, then `v` has type `τ`.

**Progress**: If `∅ ⊢ t : τ`, then either:
- `t` is a value, or
- There exists `t'` such that `t → t'`

**Preservation**: If `Γ ⊢ t : τ` and `t → t'`, then `Γ ⊢ t' : τ`

#### Example Programs

**Typed Identity:**
```ocaml
fun (x : Int) -> x
(* Type: Int -> Int *)
```

**Typed Factorial:**
```ocaml
letfun factorial (n : Int -> Int) =
    if n < 1 then 1
    else n * factorial (n - 1)
in factorial
(* Type: Int -> Int *)
```

**Type Error Examples:**
```ocaml
(* ERROR: Cannot add Int and Bool *)
fun (x : Int) -> x + true

(* ERROR: Conditional branches must have same type *)
fun (x : Int) -> if x < 0 then x else true

(* ERROR: Function expects Int, given Bool *)
let f = fun (x : Int) -> x + 1 in
f true
```

## Project Structure

```
MiniLang/
├── bin/                          # Executable entry points
│   ├── MiniImpCompiler.ml       # Compiler CLI
│   ├── MiniFunInterpreter.ml    # Functional interpreter CLI
│   └── MiniImpInterpreter.ml    # Imperative interpreter CLI
├── lib/                          # Core libraries
│   ├── miniImp/                 # MiniImp implementation
│   │   ├── MiniImpSyntax.ml    # AST definitions
│   │   ├── MiniImpParser.mly   # Parser (Menhir)
│   │   ├── MiniImpLexer.mll    # Lexer (OCamllex)
│   │   ├── MiniImpEval.ml      # Interpreter
│   │   └── MiniImpCFG.ml       # Control flow graph
│   ├── miniFun/                 # MiniFun implementation
│   │   ├── MiniFunSyntax.ml    # AST and values
│   │   ├── MiniFunParser.mly   # Parser
│   │   ├── MiniFunLexer.mll    # Lexer
│   │   ├── MiniFunEval.ml      # Evaluator
│   │   ├── MiniTyFunSyntax.ml  # Typed AST
│   │   └── MiniTyFunTypeCheck.ml  # Type checker
│   └── miniRISC/                # MiniRISC target
│       ├── MiniRISCSyntax.ml   # Assembly AST
│       ├── MiniRISCTranslation.ml  # Code generation
│       ├── MiniRISCDataflow.ml # Liveness analysis
│       ├── MiniRISCAllocation.ml  # Register allocation
│       └── MiniRISCLinearize.ml   # CFG to linear code
├── examples/                     # Example programs
│   ├── simple.minimp
│   ├── factorial.minifun
│   └── optimization_test.minimp
├── test/                         # Test suite
└── docs/                         # Documentation
```

## Documentation

Comprehensive documentation is available in [DOCUMENTATION.md](DOCUMENTATION.md), including:
- Detailed language specifications
- Compilation pipeline architecture
- Dataflow analysis algorithms
- Register allocation strategy
- Design decisions and trade-offs

## Acknowledgments

Built using:
- [OCaml](https://ocaml.org/) - Functional programming language
- [Dune](https://dune.build/) - Build system
- [Menhir](http://gallium.inria.fr/~fpottier/menhir/) - Parser generator
- [OCamllex](https://v2.ocaml.org/manual/lexyacc.html) - Lexer generator

---

**Note**: This is an educational project. The languages and compiler are designed for learning purposes and are not intended for production use.

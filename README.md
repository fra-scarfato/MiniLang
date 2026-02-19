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
git clone https://github.com/fra-scarfato/MiniLang.git
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

#### Syntax

A program `p` is defined as follows:

```
p ::= def main with input x output y as c

c ::= skip                          (no operation)
    | x := a                        (assignment)
    | c ; c                         (sequence)
    | if b then c else c            (conditional)
    | while b do c                  (loop)

b ::= v                             (boolean literal)
    | b and b                       (conjunction)
    | not b                         (negation)
    | a < a                         (comparison)

a ::= x                             (variable)
    | n                             (integer constant)
    | a + a                         (addition)
    | a - a                         (subtraction)
    | a * a                         (multiplication)
```

where:
- `x, x', x'' ∈ X` are integer variables (any sequence of letters and numbers starting with a letter)
- `n, n', n'' ∈ Z` are integer numbers (0, 1, -1, ...)
- `v, v', v'' ∈ B` are boolean literals (true, false)

#### Semantics

**Memory**: A partial function `σ : X → Z` that associates variables with integer values.

The semantics is given by four reduction relations:
- For arithmetic expressions: `⟨σ, a⟩ →_a n`
- For boolean expressions: `⟨σ, b⟩ →_b v`
- For commands: `⟨σ, c⟩ →_c σ'`
- For programs: `⟨p, n⟩ →_p n'`

We write `σ[x ↦ n]` for the memory obtained by updating (adding or overwriting) the binding for `x`, associating it to `n`.

We assume a function `O(·)` that maps each syntactical operator to its corresponding operation (e.g., the symbol `+` to addition).

**Arithmetic Expression Evaluation**:

```
⟨σ, n⟩ →_a n                        [Num]

⟨σ, x⟩ →_a σ(x)                     [Var]

⟨σ, a₁⟩ →_a n₁    ⟨σ, a₂⟩ →_a n₂
─────────────────────────────────   [Op]
⟨σ, a₁ ⊕ a₂⟩ →_a O(⊕)(n₁, n₂)
```

**Boolean Expression Evaluation**:

```
⟨σ, v⟩ →_b v                        [Bool]

⟨σ, b₁⟩ →_b v₁    ⟨σ, b₂⟩ →_b v₂
─────────────────────────────────   [BoolOp]
⟨σ, b₁ ⊕ b₂⟩ →_b O(⊕)(v₁, v₂)

⟨σ, b⟩ →_b v
────────────────                    [Not]
⟨σ, not b⟩ →_b ¬v

⟨σ, a₁⟩ →_a n₁    ⟨σ, a₂⟩ →_a n₂
─────────────────────────────────   [Less]
⟨σ, a₁ < a₂⟩ →_b n₁ < n₂
```

**Command Execution**:

```
⟨σ, skip⟩ →_c σ                     [Skip]

⟨σ, a⟩ →_a n
────────────────────                [Assign]
⟨σ, x := a⟩ →_c σ[x ↦ n]

⟨σ, c₁⟩ →_c σ'    ⟨σ', c₂⟩ →_c σ''
───────────────────────────────────  [Seq]
⟨σ, c₁ ; c₂⟩ →_c σ''

⟨σ, b⟩ →_b true    ⟨σ, c₁⟩ →_c σ'
──────────────────────────────────   [IfTrue]
⟨σ, if b then c₁ else c₂⟩ →_c σ'

⟨σ, b⟩ →_b false    ⟨σ, c₂⟩ →_c σ'
──────────────────────────────────   [IfFalse]
⟨σ, if b then c₁ else c₂⟩ →_c σ'

⟨σ, b⟩ →_b false
─────────────────────────           [WhileFalse]
⟨σ, while b do c⟩ →_c σ

⟨σ, b⟩ →_b true    ⟨σ, c⟩ →_c σ'    ⟨σ', while b do c⟩ →_c σ''
──────────────────────────────────────────────────────────────   [WhileTrue]
⟨σ, while b do c⟩ →_c σ''
```

**Program Execution**:

```
⟨[x ↦ n], c⟩ →_c σ'    σ'(y) = n'
──────────────────────────────────   [Program]
⟨def main with input x output y as c, n⟩ →_p n'
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
    )
```

**Factorial:**
```
def main with input n output fact as
    fact := 1;
    while not n < 2 do (
        fact := fact * n;
        n := n - 1
    )
```

### MiniFun: Functional Language

MiniFun is a dynamically-typed functional language with first-class functions, closures, and recursion.

#### Syntax

```
t ::= x                                (variable)
    | n                                (integer literal)
    | v                                (boolean literal)
    | fun x -> t                       (lambda abstraction)
    | t t                              (function application)
    | t ⊕ t                            (binary operation)
    | not t                            (negation)
    | if t then t else t               (conditional)
    | let x = t in t                   (local binding)
    | letfun f x = t in t              (recursive function)
```

where:
- `x, f ∈ X` are variables (identifiers)
- `n ∈ Z` are integer literals
- `v ∈ B` are boolean literals (true, false)
- `⊕ ∈ {+, -, *, <, and}` are binary operators

#### Semantics

**Values**:

```
val ::= n                              (integer)
      | v                              (boolean)
      | ⟨fun x -> t, ρ⟩                (closure: non-recursive)
      | ⟨letfun f x -> t, ρ⟩          (closure: recursive)
```

**Environment**: A partial function `ρ : X → val` that associates variables with values.

**Evaluation**: `⟨ρ, t⟩ →_t val` (under environment `ρ`, term `t` evaluates to value `val`)

```
⟨ρ, n⟩ →_t n                           [Int]

⟨ρ, v⟩ →_t v                           [Bool]

⟨ρ, x⟩ →_t ρ(x)                        [Var]

⟨ρ, fun x -> t⟩ →_t ⟨fun x -> t, ρ⟩   [Fun]

⟨ρ, t₁⟩ →_t ⟨fun x -> t, ρ'⟩    ⟨ρ, t₂⟩ →_t val₂    ⟨ρ'[x ↦ val₂], t⟩ →_t val
────────────────────────────────────────────────────────────────────────────   [AppNoRec]
⟨ρ, t₁ t₂⟩ →_t val

⟨ρ, t₁⟩ →_t ⟨letfun f x -> t, ρ'⟩    ⟨ρ, t₂⟩ →_t val₂    
⟨ρ'[f ↦ ⟨letfun f x -> t, ρ'⟩][x ↦ val₂], t⟩ →_t val
─────────────────────────────────────────────────────────────────   [AppRec]
⟨ρ, t₁ t₂⟩ →_t val

⟨ρ, t₁⟩ →_t val₁    ⟨ρ, t₂⟩ →_t val₂
────────────────────────────────────────   [BinOp]
⟨ρ, t₁ ⊕ t₂⟩ →_t O(⊕)(val₁, val₂)

⟨ρ, t⟩ →_t val
──────────────────                         [Not]
⟨ρ, not t⟩ →_t ¬val

⟨ρ, t₁⟩ →_t true    ⟨ρ, t₂⟩ →_t val
───────────────────────────────────────    [IfTrue]
⟨ρ, if t₁ then t₂ else t₃⟩ →_t val

⟨ρ, t₁⟩ →_t false    ⟨ρ, t₃⟩ →_t val
───────────────────────────────────────    [IfFalse]
⟨ρ, if t₁ then t₂ else t₃⟩ →_t val

⟨ρ, t₁⟩ →_t val₁    ⟨ρ[x ↦ val₁], t₂⟩ →_t val
─────────────────────────────────────────────   [Let]
⟨ρ, let x = t₁ in t₂⟩ →_t val

⟨ρ[f ↦ ⟨letfun f x -> t₁, ρ⟩], t₂⟩ →_t val
───────────────────────────────────────────────   [LetFun]
⟨ρ, letfun f x = t₁ in t₂⟩ →_t val
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

#### Syntax

```
τ ::= Int                              (integer type)
    | Bool                             (boolean type)
    | τ -> τ                           (function type)

t ::= x                                (variable)
    | n                                (integer literal)
    | v                                (boolean literal)
    | fun (x : τ) -> t                 (typed lambda)
    | t t                              (function application)
    | t ⊕ t                            (binary operation)
    | not t                            (negation)
    | if t then t else t               (conditional)
    | let x = t in t                   (local binding)
    | letfun f (x : τ -> τ) = t in t   (recursive function)
```

where:
- `x, f ∈ X` are variables (identifiers)
- `n ∈ Z` are integer literals
- `v ∈ B` are boolean literals (true, false)
- `⊕ ∈ {+, -, *, <, and}` are binary operators

#### Type System

**Type Environment**: A partial function `Γ : X → τ` that associates variables with types.

**Type Judgments**: `Γ ⊢ t : τ` (under environment `Γ`, term `t` has type `τ`)

```
Γ ⊢ n : Int                            [T-Int]

Γ ⊢ v : Bool                           [T-Bool]

x : τ ∈ Γ
─────────                              [T-Var]
Γ ⊢ x : τ

Γ[x : τ₁] ⊢ t : τ₂
───────────────────────────────        [T-Fun]
Γ ⊢ (fun (x : τ₁) -> t) : τ₁ -> τ₂

Γ ⊢ t₁ : τ₁ -> τ₂    Γ ⊢ t₂ : τ₁
──────────────────────────────         [T-App]
Γ ⊢ t₁ t₂ : τ₂

Γ ⊢ t₁ : Int    Γ ⊢ t₂ : Int    ⊕ ∈ {+, -, *}
────────────────────────────────────────────    [T-BinOp-Arith]
Γ ⊢ t₁ ⊕ t₂ : Int

Γ ⊢ t₁ : Int    Γ ⊢ t₂ : Int
────────────────────────────           [T-Less]
Γ ⊢ t₁ < t₂ : Bool

Γ ⊢ t₁ : Bool    Γ ⊢ t₂ : Bool
───────────────────────────────        [T-And]
Γ ⊢ t₁ and t₂ : Bool

Γ ⊢ t : Bool
────────────                           [T-Not]
Γ ⊢ not t : Bool

Γ ⊢ t₁ : Bool    Γ ⊢ t₂ : τ    Γ ⊢ t₃ : τ
──────────────────────────────────────────    [T-If]
Γ ⊢ if t₁ then t₂ else t₃ : τ

Γ ⊢ t₁ : τ₁    Γ[x : τ₁] ⊢ t₂ : τ
─────────────────────────────────      [T-Let]
Γ ⊢ let x = t₁ in t₂ : τ

Γ[f : τ₁ -> τ₂][x : τ₁] ⊢ t₁ : τ₂    Γ[f : τ₁ -> τ₂] ⊢ t₂ : τ
────────────────────────────────────────────────────────────────   [T-LetFun]
Γ ⊢ letfun f (x : τ₁ -> τ₂) = t₁ in t₂ : τ
```

#### Type Safety

**Theorem (Type Safety)**: If `∅ ⊢ t : τ` and `⟨∅, t⟩ →_t val`, then `val` has type `τ`.

**Progress**: If `∅ ⊢ t : τ`, then either:
- `t` is a value, or
- There exists `t'` such that `⟨∅, t⟩ →_t t'`

**Preservation**: If `Γ ⊢ t : τ` and `⟨ρ, t⟩ →_t t'`, then `Γ ⊢ t' : τ`

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

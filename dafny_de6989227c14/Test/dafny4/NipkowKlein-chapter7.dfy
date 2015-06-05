// RUN: %dafny /compile:0 /rprint:"%t.rprint" "%s" > "%t"
// RUN: %diff "%s.expect" "%t"

// This file is a Dafny encoding of chapter 7 from "Concrete Semantics: With Isabelle/HOL" by
// Tobias Nipkow and Gerwin Klein.

// ----- first, some definitions from chapter 3 -----

datatype List<T> = Nil | Cons(head: T, tail: List<T>)
type vname = string  // variable names

type val = int
type state = imap<vname, val>
predicate Total(s: state)
{
  forall x :: x in s
}

datatype aexp = N(n: int) | V(x: vname) | Plus(0: aexp, 1: aexp)  // arithmetic expressions
function aval(a: aexp, s: state): val
  requires Total(s)
{
  match a
  case N(n) => n
  case V(x) => s[x]
  case Plus(a0, a1) => aval(a0,s ) + aval(a1, s)
}

datatype bexp = Bc(v: bool) | Not(op: bexp) | And(0: bexp, 1: bexp) | Less(a0: aexp, a1: aexp)
function bval(b: bexp, s: state): bool
  requires Total(s)
{
  match b
  case Bc(v) => v
  case Not(b) => !bval(b, s)
  case And(b0, b1) => bval(b0, s) && bval(b1, s)
  case Less(a0, a1) => aval(a0, s) < aval(a1, s)
}

// ----- IMP commands -----

datatype com = SKIP | Assign(vname, aexp) | Seq(com, com) | If(bexp, com, com) | While(bexp, com)

// ----- Big-step semantics -----

inductive predicate big_step(c: com, s: state, t: state)
  requires Total(s)
{
  match c
  case SKIP =>
    s == t
  case Assign(x, a) =>
    t == s[x := aval(a, s)]
  case Seq(c0, c1) =>
    exists s' ::
    Total(s') &&
    big_step(c0, s, s') &&
    big_step(c1, s', t)
  case If(b, thn, els) =>
    big_step(if bval(b, s) then thn else els, s, t)
  case While(b, body) =>
    (!bval(b, s) && s == t) ||
    (bval(b, s) && exists s' ::
     Total(s') &&
     big_step(body, s, s') &&
     big_step(While(b, body), s', t))
}

lemma Example1(s: state, t: state)
  requires Total(s)
  requires t == s["x" := 5]["y" := 5]
  ensures big_step(Seq(Assign("x", N(5)), Assign("y", V("x"))), s, t)
{
  var s' := s["x" := 5];
  calc <== {
    big_step(Seq(Assign("x", N(5)), Assign("y", V("x"))), s, t);
    // 5 is suffiiently high
    big_step#[5](Seq(Assign("x", N(5)), Assign("y", V("x"))), s, t);
    big_step#[4](Assign("x", N(5)), s, s') && big_step#[4](Assign("y", V("x")), s', t);
    // the rest is done automatically
    true;
  }
}

lemma SemiAssociativity(c0: com, c1: com, c2: com, s: state, t: state)
  requires Total(s)
  ensures big_step(Seq(Seq(c0, c1), c2), s, t) == big_step(Seq(c0, Seq(c1, c2)), s, t)
{
  calc {
    big_step(Seq(Seq(c0, c1), c2), s, t);
    // def. big_step
    exists s'' :: Total(s'') && big_step(Seq(c0, c1), s, s'') && big_step(c2, s'', t);
    // def. big_step
    exists s'' :: Total(s'') && (exists s' :: Total(s') && big_step(c0, s, s') && big_step(c1, s', s'')) && big_step(c2, s'', t);
    // logic
    exists s', s'' :: Total(s') && Total(s'') && big_step(c0, s, s') && big_step(c1, s', s'') && big_step(c2, s'', t);
    // logic
    exists s' :: Total(s') && big_step(c0, s, s') && exists s'' :: Total(s'') && big_step(c1, s', s'') && big_step(c2, s'', t);
    // def. big_step
    exists s' :: Total(s') && big_step(c0, s, s') && big_step(Seq(c1, c2), s', t);
    // def. big_step
    big_step(Seq(c0, Seq(c1, c2)), s, t);
  }
}

predicate equiv_c(c: com, c': com)
{
  forall s,t :: Total(s) ==> big_step(c, s, t) == big_step(c', s, t)
}

lemma lemma_7_3(b: bexp, c: com)
  ensures equiv_c(While(b, c), If(b, Seq(c, While(b, c)), SKIP))
{
}

lemma lemma_7_4(b: bexp, c: com)
  ensures equiv_c(If(b, c, c), c)
{
}

lemma lemma_7_5(b: bexp, c: com, c': com)
  requires equiv_c(c, c')
  ensures equiv_c(While(b, c), While(b, c'))
{
  forall s,t | Total(s)
    ensures big_step(While(b, c), s, t) == big_step(While(b, c'), s, t)
  {
    if big_step(While(b, c), s, t) {
      lemma_7_6(b, c, c', s, t);
    }
    if big_step(While(b, c'), s, t) {
      lemma_7_6(b, c', c, s, t);
    }
  }
}

inductive lemma lemma_7_6(b: bexp, c: com, c': com, s: state, t: state)
  requires Total(s) && big_step(While(b, c), s, t) && equiv_c(c, c')
  ensures big_step(While(b, c'), s, t)
{
  if !bval(b, s) {
    // trivial
  } else {
    var s' :| Total(s') && big_step#[_k-1](c, s, s') && big_step#[_k-1](While(b, c), s', t);
    lemma_7_6(b, c, c', s', t);  // induction hypothesis
  }
}

// equiv_c is an equivalence relation
lemma equiv_c_reflexive(c: com, c': com)
  ensures c == c' ==> equiv_c(c, c')
{
}
lemma equiv_c_symmetric(c: com, c': com)
  ensures equiv_c(c, c') ==> equiv_c(c', c)
{
}
lemma equiv_c_transitive(c: com, c': com, c'': com)
  ensures equiv_c(c, c') && equiv_c(c', c'') ==> equiv_c(c, c'')
{
}

inductive lemma IMP_is_deterministic(c: com, s: state, t: state, t': state)
  requires Total(s) && big_step(c, s, t) && big_step(c, s, t')
  ensures t == t'
{
  match c
  case SKIP =>
    // trivial
  case Assign(x, a) =>
    // trivial
  case Seq(c0, c1) =>
    var s' :| Total(s') && big_step#[_k-1](c0, s, s') && big_step#[_k-1](c1, s', t);
    var s'' :| Total(s'') && big_step#[_k-1](c0, s, s'') && big_step#[_k-1](c1, s'', t');
    IMP_is_deterministic(c0, s, s', s'');
    IMP_is_deterministic(c1, s', t, t');
  case If(b, thn, els) =>
    IMP_is_deterministic(if bval(b, s) then thn else els, s, t, t');
  case While(b, body) =>
    if !bval(b, s) {
      // trivial
    } else {
      var s' :| Total(s') && big_step#[_k-1](body, s, s') && big_step#[_k-1](While(b, body), s', t);
      var s'' :| Total(s'') && big_step#[_k-1](body, s, s'') && big_step#[_k-1](While(b, body), s'', t');
      IMP_is_deterministic(body, s, s', s'');
      IMP_is_deterministic(While(b, body), s', t, t');
    }
}

// ----- Small-step semantics -----

inductive predicate small_step(c: com, s: state, c': com, s': state)
  requires Total(s)
{
  match c
  case SKIP => false
  case Assign(x, a) =>
    c' == SKIP && s' == s[x := aval(a, s)]
  case Seq(c0, c1) =>
    (c0 == SKIP && c' == c1 && s' == s) ||
    exists c0' :: c' == Seq(c0', c1) && small_step(c0, s, c0', s')
  case If(b, thn, els) =>
    c' == (if bval(b, s) then thn else els) && s' == s
  case While(b, body) =>
    c' == If(b, Seq(body, While(b, body)), SKIP) && s' == s
}

inductive lemma SmallStep_is_deterministic(cs: (com, state), cs': (com, state), cs'': (com, state))
  requires Total(cs.1)
  requires small_step(cs.0, cs.1, cs'.0, cs'.1)
  requires small_step(cs.0, cs.1, cs''.0, cs''.1)
  ensures cs' == cs''
{
  match cs.0
  case Assign(x, a) =>
  case Seq(c0, c1) =>
    if c0 == SKIP {
    } else {
      var c0' :| cs'.0 == Seq(c0', c1) && small_step#[_k-1](c0, cs.1, c0', cs'.1);
      var c0'' :| cs''.0 == Seq(c0'', c1) && small_step#[_k-1](c0, cs.1, c0'', cs''.1);
      SmallStep_is_deterministic((c0, cs.1), (c0', cs'.1), (c0'', cs''.1));
    }
  case If(b, thn, els) =>
  case While(b, body) =>
}

inductive lemma small_step_ends_in_Total_state(c: com, s: state, c': com, s': state)
  requires Total(s) && small_step(c, s, c', s')
  ensures Total(s')
{
  match c
  case Assign(x, a) =>
  case Seq(c0, c1) =>
    if c0 != SKIP {
      var c0' :| c' == Seq(c0', c1) && small_step(c0, s, c0', s');
      small_step_ends_in_Total_state(c0, s, c0', s');
    }
  case If(b, thn, els) =>
  case While(b, body) =>
}

inductive predicate small_step_star(c: com, s: state, c': com, s': state)
  requires Total(s)
{
  (c == c' && s == s') ||
  exists c'', s'' ::
    small_step(c, s, c'', s'') &&
    (small_step_ends_in_Total_state(c, s, c'', s''); small_step_star(c'', s'', c', s'))
}

inductive lemma small_step_star_ends_in_Total_state(c: com, s: state, c': com, s': state)
  requires Total(s) && small_step_star(c, s, c', s')
  ensures Total(s')
{
  if c == c' && s == s' {
  } else {
    var c'', s'' :| small_step(c, s, c'', s'') &&
       (small_step_ends_in_Total_state(c, s, c'', s''); small_step_star#[_k-1](c'', s'', c', s'));
    small_step_star_ends_in_Total_state(c'', s'', c', s');
  }
}

lemma star_transitive(c0: com, s0: state, c1: com, s1: state, c2: com, s2: state)
  requires Total(s0) && Total(s1)
  requires small_step_star(c0, s0, c1, s1) && small_step_star(c1, s1, c2, s2)
  ensures small_step_star(c0, s0, c2, s2)
{
  star_transitive_aux(c0, s0, c1, s1, c2, s2);
}
inductive lemma star_transitive_aux(c0: com, s0: state, c1: com, s1: state, c2: com, s2: state)
  requires Total(s0) && Total(s1)
  requires small_step_star(c0, s0, c1, s1)
  ensures small_step_star(c1, s1, c2, s2) ==> small_step_star(c0, s0, c2, s2)
{
  if c0 == c1 && s0 == s1 {
  } else {
    var c', s' :|
      small_step(c0, s0, c', s') &&
      (small_step_ends_in_Total_state(c0, s0, c', s'); small_step_star#[_k-1](c', s', c1, s1));
      star_transitive_aux(c', s', c1, s1, c2, s2);
  }
}

// The big-step semantics can be simulated by some number of small steps
inductive lemma BigStep_implies_SmallStepStar(c: com, s: state, t: state)
  requires Total(s) && big_step(c, s, t)
  ensures small_step_star(c, s, SKIP, t)
{
  match c
  case SKIP =>
    // trivial
  case Assign(x, a) =>
    assert t == s[x := aval(a, s)];
    assert small_step(c, s, SKIP, t);
    assert small_step_star(SKIP, t, SKIP, t);
  case Seq(c0, c1) =>
    var s' :| Total(s') && big_step#[_k-1](c0, s, s') && big_step#[_k-1](c1, s', t);
    calc <== {
      small_step_star(c, s, SKIP, t);
      { star_transitive(Seq(c0, c1), s, Seq(SKIP, c1), s', SKIP, t); }
      small_step_star(Seq(c0, c1), s, Seq(SKIP, c1), s') && small_step_star(Seq(SKIP, c1), s', SKIP, t);
      { lemma_7_13(c0, s, SKIP, s', c1); }
      small_step_star(c0, s, SKIP, s') && small_step_star(Seq(SKIP, c1), s', SKIP, t);
      { BigStep_implies_SmallStepStar(c0, s, s'); }
      small_step_star(Seq(SKIP, c1), s', SKIP, t);
      { assert small_step(Seq(SKIP, c1), s', c1, s'); }
      small_step_star(c1, s', SKIP, t);
      { BigStep_implies_SmallStepStar(c1, s', t); }
      true;
    }
  case If(b, thn, els) =>
    BigStep_implies_SmallStepStar(if bval(b, s) then thn else els, s, t);
  case While(b, body) =>
    if !bval(b, s) && s == t {
      calc <== {
        small_step_star(c, s, SKIP, t);
        { assert small_step(c, s, If(b, Seq(body, While(b, body)), SKIP), s); }
        small_step_star(If(b, Seq(body, While(b, body)), SKIP), s, SKIP, t);
        { assert small_step(If(b, Seq(body, While(b, body)), SKIP), s, SKIP, s); }
        small_step_star(SKIP, s, SKIP, t);
        true;
      }
    } else {
      var s' :| Total(s') && big_step#[_k-1](body, s, s') && big_step#[_k-1](While(b, body), s', t);
      calc <== {
        small_step_star(c, s, SKIP, t);
        { assert small_step(c, s, If(b, Seq(body, While(b, body)), SKIP), s); }
        small_step_star(If(b, Seq(body, While(b, body)), SKIP), s, SKIP, t);
        { assert small_step(If(b, Seq(body, While(b, body)), SKIP), s, Seq(body, While(b, body)), s); }
        small_step_star(Seq(body, While(b, body)), s, SKIP, t);
        { star_transitive(Seq(body, While(b, body)), s, Seq(SKIP, While(b, body)), s', SKIP, t); }
        small_step_star(Seq(body, While(b, body)), s, Seq(SKIP, While(b, body)), s') && small_step_star(Seq(SKIP, While(b, body)), s', SKIP, t);
        { lemma_7_13(body, s, SKIP, s', While(b, body)); }
        small_step_star(body, s, SKIP, s') && small_step_star(Seq(SKIP, While(b, body)), s', SKIP, t);
        { BigStep_implies_SmallStepStar(body, s, s'); }
        small_step_star(Seq(SKIP, While(b, body)), s', SKIP, t);
        { assert small_step(Seq(SKIP, While(b, body)), s', While(b, body), s'); }
        small_step_star(While(b, body), s', SKIP, t);
        { BigStep_implies_SmallStepStar(While(b, body), s', t); }
        true;
      }
    }
}

inductive lemma lemma_7_13(c0: com, s0: state, c: com, t: state, c1: com)
  requires Total(s0) && small_step_star(c0, s0, c, t)
  ensures small_step_star(Seq(c0, c1), s0, Seq(c, c1), t)
{
  if c0 == c && s0 == t {
  } else {
    var c', s' :| small_step(c0, s0, c', s') && (small_step_ends_in_Total_state(c0, s0, c', s'); small_step_star#[_k-1](c', s', c, t));
    lemma_7_13(c', s', c, t, c1);
  }
}

inductive lemma SmallStepStar_implies_BigStep(c: com, s: state, t: state)
  requires Total(s) && small_step_star(c, s, SKIP, t)
  ensures big_step(c, s, t)
{
  if c == SKIP && s == t {
  } else {
    var c', s' :| small_step(c, s, c', s') && (small_step_ends_in_Total_state(c, s, c', s'); small_step_star#[_k-1](c', s', SKIP, t));
    SmallStepStar_implies_BigStep(c', s', t);
    SmallStep_plus_BigStep(c, s, c', s', t);
  }
}

inductive lemma SmallStep_plus_BigStep(c: com, s: state, c': com, s': state, t: state)
  requires Total(s) && Total(s') && small_step(c, s, c', s')
  ensures big_step(c', s', t) ==> big_step(c, s, t)
{
  match c
  case Assign(x, a) =>
  case Seq(c0, c1) =>
    if c0 == SKIP && c' == c1 && s' == s {
    } else {
      var c0' :| c' == Seq(c0', c1) && small_step(c0, s, c0', s');
      if big_step(c', s', t) {
        var k: nat :| big_step#[k](Seq(c0', c1), s', t);
        var s'' :| Total(s'') && big_step(c0', s', s'') && big_step(c1, s'', t);
        SmallStep_plus_BigStep(c0, s, c0', s', s'');
      }
    }
  case If(b, thn, els) =>
  case While(b, body) =>
    assert c' == If(b, Seq(body, While(b, body)), SKIP) && s' == s;
    if big_step(c', s', t) {
      assert big_step(if bval(b, s') then Seq(body, While(b, body)) else SKIP, s', t);
    }
}

// big-step and small-step semantics agree
lemma BigStep_SmallStepStar_Same(c: com, s: state, t: state)
  requires Total(s)
  ensures big_step(c, s, t) <==> small_step_star(c, s, SKIP, t)
{
  if big_step(c, s, t) {
    BigStep_implies_SmallStepStar(c, s, t);
  }
  if small_step_star(c, s, SKIP, t) {
    SmallStepStar_implies_BigStep(c, s, t);
  }
}

predicate final(c: com, s: state)
  requires Total(s)
{
  !exists c',s' :: small_step(c, s, c', s')
}

// lemma 7.17:
lemma final_is_skip(c: com, s: state)
  requires Total(s)
  ensures final(c, s) <==> c == SKIP
{
  if c == SKIP {
    assert final(c, s);
  } else {
    var _, _ := only_skip_has_no_next_state(c, s);
  }
}
lemma only_skip_has_no_next_state(c: com, s: state) returns (c': com, s': state)
  requires Total(s) && c != SKIP
  ensures small_step(c, s, c', s')
{
  match c
  case SKIP =>
  case Assign(x, a) =>
    c', s' := SKIP, s[x := aval(a, s)];
  case Seq(c0, c1) =>
    if c0 == SKIP {
      c', s' := c1, s;
    } else {
      c', s' := only_skip_has_no_next_state(c0, s);
      c' := Seq(c', c1);
    }
  case If(b, thn, els) =>
    c', s' := if bval(b, s) then thn else els, s;
  case While(b, body) =>
    c', s' := If(b, Seq(body, While(b, body)), SKIP), s;
}

lemma lemma_7_18(c: com, s: state)
  requires Total(s)
  ensures (exists t :: big_step(c, s, t)) <==>
          (exists c',s' :: small_step_star(c, s, c', s') &&
              (small_step_star_ends_in_Total_state(c, s, c', s'); final(c', s')))
{
  if exists t :: big_step(c, s, t) {
    var t :| big_step(c, s, t);
    BigStep_SmallStepStar_Same(c, s, t);
    small_step_star_ends_in_Total_state(c, s, SKIP, t);
    calc ==> {
      true;
      big_step(c, s, t);
      small_step_star(c, s, SKIP, t);
      { assert final(SKIP, t); }
      small_step_star(c, s, SKIP, t) && final(SKIP, t);
    }
  }
  if exists c',s' :: small_step_star(c, s, c', s') &&
              (small_step_star_ends_in_Total_state(c, s, c', s'); final(c', s')) {
    var c',s' :| small_step_star(c, s, c', s') &&
              (small_step_star_ends_in_Total_state(c, s, c', s'); final(c', s'));
    final_is_skip(c', s');
    BigStep_SmallStepStar_Same(c, s, s');
  }
}

(*
  This file defines a rose tree data structure as a co-inductive
  datatype called 'a ltree, which is short for lazy tree. This
  co-datatype has one constructor, called Branch that has type:

      Branch : 'a -> 'a ltree llist -> 'a ltree

  Note that this tree data structure allows for both infinite depth
  and infinite breadth.
*)
open HolKernel Parse boolLib bossLib term_tactic;
open arithmeticTheory listTheory llistTheory alistTheory optionTheory;
open mp_then pred_setTheory relationTheory pairTheory combinTheory;

val _ = new_theory "ltree";

(* make type definition *)

Type ltree_rep[local] = ``:num list -> 'a # num option``;

Overload NOTHING[local] = ``(ARB:'a, SOME (0:num))``;

Definition ltree_rep_ok_def:
  ltree_rep_ok f <=>
    !path x n.
      f path = (x, SOME n) ==>
      !pos rest. f (path ++ pos::rest) <> NOTHING ==> pos < n
End

Theorem type_inhabited[local]:
  ?f. ltree_rep_ok f
Proof
  qexists_tac `\p. NOTHING` \\ fs [ltree_rep_ok_def] \\ rw []
QED

val ltree_tydef = new_type_definition ("ltree", type_inhabited);

val repabs_fns = define_new_type_bijections
  { name = "ltree_absrep",
    ABS  = "ltree_abs",
    REP  = "ltree_rep",
    tyax = ltree_tydef};


(* prove basic theorems about rep and abs functions *)

val ltree_absrep = CONJUNCT1 repabs_fns
val ltree_repabs = CONJUNCT2 repabs_fns

Theorem ltree_rep_ok_ltree_rep[local,simp]:
  ltree_rep_ok (ltree_rep f)
Proof
  fs [ltree_repabs, ltree_absrep]
QED

Theorem ltree_abs_11[local]:
  ltree_rep_ok r1 /\ ltree_rep_ok r2 ==> ((ltree_abs r1 = ltree_abs r2) = (r1 = r2))
Proof
  fs [ltree_repabs, EQ_IMP_THM] \\ metis_tac []
QED

Theorem ltree_rep_11[local]:
  (ltree_rep t1 = ltree_rep t2) = (t1 = t2)
Proof
  fs [EQ_IMP_THM] \\ metis_tac [ltree_absrep]
QED

Theorem every_ltree_rep_ok[local]:
  !ts. every ltree_rep_ok (LMAP ltree_rep ts)
Proof
  rw [] \\ qspec_then `ts` strip_assume_tac fromList_fromSeq
  \\ rw [LMAP_fromList,every_fromList_EVERY,EVERY_MEM,MEM_MAP]
  \\ fs [ltree_rep_ok_ltree_rep]
QED

Theorem LMAP_ltree_rep_11[local]:
  LMAP ltree_rep ts1 = LMAP ltree_rep ts2 <=> ts1 = ts2
Proof
  rw []
  \\ qspec_then `ts1` strip_assume_tac fromList_fromSeq \\ rw []
  \\ qspec_then `ts2` strip_assume_tac fromList_fromSeq \\ rw []
  \\ fs [LMAP_fromList]
  \\ fs [Once FUN_EQ_THM,ltree_rep_11] \\ fs [FUN_EQ_THM]
  \\ rename [`MAP _ l1 = MAP _ l2`]
  \\ qid_spec_tac `l1`
  \\ qid_spec_tac `l2`
  \\ Induct \\ Cases_on `l1` \\ fs [ltree_rep_11]
QED

Theorem LMAP_ltree_rep_ltree_abs[local]:
  every ltree_rep_ok ts ==>
  LMAP ltree_rep (LMAP ltree_abs ts) = ts
Proof
  rw [] \\ qspec_then `ts` strip_assume_tac fromList_fromSeq
  \\ fs [LMAP_fromList,every_fromList_EVERY,MEM_MAP,
         LMAP_fromList,MAP_MAP_o]
  \\ rw [ltree_repabs,FUN_EQ_THM] \\ fs [ltree_repabs]
  \\ Induct_on `l` \\ fs [ltree_repabs]
QED


(* define the only constructor: Branch *)

Definition Branch_rep_def:
  Branch_rep (x:'a) (xs:('a ltree_rep) llist) =
    \path. case path of
           | [] => (x, LLENGTH xs)
           | (n::rest) => case LNTH n xs of SOME t => t rest | NONE => NOTHING
End

Definition Branch:
  Branch a ts = ltree_abs (Branch_rep a (LMAP ltree_rep ts))
End

Theorem ltree_rep_ok_Branch_rep_every[local]:
  ltree_rep_ok (Branch_rep a ts) = every ltree_rep_ok ts
Proof
  fs [Branch_rep_def,ltree_rep_ok_def]
  \\ rw [] \\ reverse (qspec_then `ts` strip_assume_tac fromList_fromSeq)
  \\ rw [ltree_rep_ok_def]
  \\ eq_tac \\ rpt strip_tac
  THEN1
   (first_x_assum (qspecl_then [`i::path`,`x`,`n`] mp_tac)
    \\ fs [] \\ disch_then drule \\ fs [])
  THEN1
   (fs[AllCaseEqs()] >> rfs[] >> first_x_assum (drule_then irule) >>
    RULE_ASSUM_TAC (REWRITE_RULE [GSYM APPEND_ASSOC, APPEND]) >> metis_tac[])
  \\ fs [every_fromList_EVERY,LNTH_fromList]
  THEN1
   (rw [EVERY_EL,ltree_rep_ok_def]
    \\ first_x_assum (qspec_then `n::path` mp_tac) \\ fs []
    \\ disch_then drule \\ fs [])
  \\ fs [EVERY_EL,ltree_rep_ok_def]
  \\ Cases_on `path` \\ fs []
  \\ rw [] \\ fs [AllCaseEqs()]
  \\ res_tac \\ fs [] >> metis_tac[]
QED

Theorem ltree_rep_ok_Branch_rep[local]:
  every ltree_rep_ok ts ==> ltree_rep_ok (Branch_rep a ts)
Proof
  fs [ltree_rep_ok_Branch_rep_every]
QED

Theorem ltree_rep_ok_Branch_rep_IMP[local]:
  ltree_rep_ok (Branch_rep a ts) ==> every ltree_rep_ok ts
Proof
  fs [ltree_rep_ok_Branch_rep_every]
QED


(* prove injectivity *)

Theorem Branch_rep_11[local]:
  !a1 a2 ts1 ts2. Branch_rep a1 ts1 = Branch_rep a2 ts2 <=> a1 = a2 /\ ts1 = ts2
Proof
  fs [Branch_rep_def,FUN_EQ_THM]
  \\ rpt gen_tac \\ eq_tac \\ simp []
  \\ strip_tac
  \\ first_assum (qspec_then `[]` assume_tac) \\ fs [] \\ rw []
  \\ reverse (qspec_then `ts1` strip_assume_tac fromList_fromSeq) \\ rw []
  \\ reverse (qspec_then `ts2` strip_assume_tac fromList_fromSeq) \\ rw []
  \\ fs [LLENGTH_fromSeq,LLENGTH_fromList]
  THEN1
   (fs [FUN_EQ_THM] \\ rw []
    \\ first_x_assum (qspec_then `x::x'` mp_tac) \\ fs [])
  \\ fs [LNTH_fromList]
  \\ fs [LIST_EQ_REWRITE] \\ rw []
  \\ rw [FUN_EQ_THM]
  \\ first_x_assum (qspec_then `x::x'` mp_tac) \\ fs []
QED

Theorem Branch_11:
  !a1 a2 ts1 ts2. Branch a1 ts1 = Branch a2 ts2 <=> a1 = a2 /\ ts1 = ts2
Proof
  rw [Branch] \\ eq_tac \\ strip_tac \\ fs []
  \\ qspec_then `ts1` assume_tac every_ltree_rep_ok
  \\ drule ltree_rep_ok_Branch_rep
  \\ qspec_then `ts2` assume_tac every_ltree_rep_ok
  \\ drule ltree_rep_ok_Branch_rep
  \\ strip_tac \\ strip_tac
  \\ fs [ltree_abs_11]
  \\ fs [LMAP_ltree_rep_11,Branch_rep_11]
QED


(* prove cases theorem *)

Theorem Branch_rep_exists[local]:
  ltree_rep_ok f ==> ?a ts. f = Branch_rep a ts
Proof
  fs [ltree_rep_ok_def] \\ rw []
  \\ Cases_on `f []` \\ fs []
  \\ rename [`_ = (a,ts)`]
  \\ qexists_tac `a`
  \\ qexists_tac `LGENLIST (\n path. f (n::path)) ts`
  \\ fs [Branch_rep_def,FUN_EQ_THM]
  \\ Cases \\ fs [LNTH_LGENLIST]
  \\ Cases_on `f (h::t)` \\ fs []
  \\ Cases_on `ts` \\ fs []
  \\ IF_CASES_TAC \\ fs []
  \\ first_x_assum drule \\ fs []
  \\ disch_then (qspecl_then [`h`,`t`] mp_tac) \\ fs []
QED

Theorem ltree_cases:
  !t. ?a ts. t = Branch a ts
Proof
  fs [Branch] \\ fs [GSYM ltree_rep_11] \\ rw []
  \\ qspec_then `ts1` assume_tac every_ltree_rep_ok
  \\ qabbrev_tac `f = ltree_rep t`
  \\ `ltree_rep_ok f` by fs [Abbr`f`]
  \\ drule Branch_rep_exists \\ rw []
  \\ qexists_tac `a` \\ qexists_tac `LMAP ltree_abs ts`
  \\ imp_res_tac ltree_rep_ok_Branch_rep_IMP
  \\ fs [LMAP_ltree_rep_ltree_abs,ltree_repabs]
QED


(* define ltree_CASE constant *)

Definition dest_Branch_rep_def:
  dest_Branch_rep (l:'a ltree_rep) =
    let (x,len) = l [] in
      (x, LGENLIST (\n path. l (n::path)) len)
End

Theorem dest_Branch_rep_Branch_rep[local]:
  dest_Branch_rep (Branch_rep x xs) = (x,xs)
Proof
  fs [Branch_rep_def,dest_Branch_rep_def]
  \\ qspec_then `xs` strip_assume_tac fromList_fromSeq \\ fs []
  \\ fs [LGENLIST_EQ_fromSeq,FUN_EQ_THM,LGENLIST_EQ_fromList]
  \\ fs [LNTH_fromList]
  \\ CONV_TAC (RAND_CONV (ONCE_REWRITE_CONV [GSYM GENLIST_ID]))
  \\ fs [GENLIST_FUN_EQ,FUN_EQ_THM]
QED

Definition ltree_CASE[nocompute]:
  ltree_CASE t f =
    let (a,ts) = dest_Branch_rep (ltree_rep t) in
      f a (LMAP ltree_abs ts)
End

Theorem ltree_CASE[compute]:
  ltree_CASE (Branch a ts) f = f a ts
Proof
  fs [ltree_CASE,Branch]
  \\ qspec_then `ts` assume_tac every_ltree_rep_ok
  \\ drule ltree_rep_ok_Branch_rep
  \\ fs [ltree_repabs,dest_Branch_rep_Branch_rep]
  \\ fs [LMAP_MAP] \\ rw [] \\ AP_TERM_TAC
  \\ qspec_then `ts` strip_assume_tac fromList_fromSeq
  \\ fs [LMAP_fromList,LMAP_fromSeq,FUN_EQ_THM,ltree_absrep]
  \\ rpt (pop_assum kall_tac)
  \\ Induct_on `l` \\ fs [ltree_absrep]
QED

Theorem ltree_CASE_eq:
  ltree_CASE t f = v <=> ?a ts. t = Branch a ts /\ f a ts = v
Proof
  qspec_then `t` strip_assume_tac ltree_cases \\ rw []
  \\ fs [Branch_11,ltree_CASE]
QED


(* ltree generator *)

Definition path_ok_def:
  path_ok path f <=>
    !xs n ys k a.
      path = xs ++ n::ys /\ f xs = (a,SOME k) ==> n < k
End

Definition make_ltree_rep_def:
  make_ltree_rep f =
    \path. if path_ok path f then f path else NOTHING
End

Theorem ltree_rep_ok_make_ltree_rep[local]:
  !f. ltree_rep_ok (make_ltree_rep f)
Proof
  fs [ltree_rep_ok_def,make_ltree_rep_def] \\ rw []
  THEN1
   (fs [AllCaseEqs()] \\ fs []
    \\ fs [path_ok_def] \\ metis_tac [])
  \\ fs [AllCaseEqs()] \\ fs []
  \\ CCONTR_TAC \\ fs [] \\ fs []
  \\ fs [path_ok_def] \\ rw []
  \\ first_x_assum (qspecl_then [`xs`,`n`,`ys ++ pos::rest`] mp_tac)
  \\ fs []
QED

Definition gen_ltree_def[nocompute]:
  gen_ltree f = ltree_abs (make_ltree_rep f)
End

Theorem gen_ltree:
  gen_ltree f =
    let (a,len) = f [] in
      Branch a (LGENLIST (\n. gen_ltree (\path. f (n::path))) len)
Proof
  fs [UNCURRY,gen_ltree_def,Branch,o_DEF]
  \\ qspec_then `f` assume_tac ltree_rep_ok_make_ltree_rep
  \\ fs [REWRITE_RULE [ltree_rep_ok_make_ltree_rep]
          (Q.SPEC `make_ltree_rep f` ltree_repabs)]
  \\ AP_TERM_TAC \\ Cases_on `f []` \\ fs []
  \\ fs [Branch_rep_def,FUN_EQ_THM]
  \\ Cases \\ fs []
  THEN1 fs [make_ltree_rep_def,path_ok_def]
  \\ Cases_on `r` \\ fs []
  \\ fs [LNTH_LGENLIST]
  THEN1
   (fs [make_ltree_rep_def]
    \\ AP_THM_TAC \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ fs [path_ok_def]
    \\ rw [] \\ eq_tac \\ rw []
    THEN1
     (first_x_assum match_mp_tac
      \\ goal_assum (first_assum o mp_then.mp_then mp_then.Any mp_tac)
      \\ qexists_tac `ys` \\ fs [])
    \\ Cases_on `xs` \\ fs [] \\ rw []
    \\ metis_tac [])
  \\ fs [make_ltree_rep_def]
  \\ reverse (Cases_on `h < x`) \\ fs []
  THEN1 (rw [] \\ fs [path_ok_def] \\ metis_tac [APPEND])
  \\ AP_THM_TAC \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ fs [path_ok_def]
  \\ rw [] \\ eq_tac \\ rw []
  THEN1
   (first_x_assum match_mp_tac
    \\ goal_assum (first_assum o mp_then.mp_then mp_then.Any mp_tac)
    \\ qexists_tac `ys` \\ fs [])
  \\ Cases_on `xs` \\ fs [] \\ rw []
  \\ metis_tac []
QED

Theorem gen_ltree_LNIL:
  gen_ltree f = Branch a LNIL <=> f [] = (a, SOME 0)
Proof
  simp [Once gen_ltree,UNCURRY]
  \\ Cases_on `f []` \\ fs [Branch_11]
QED


(* ltree unfold *)

Definition make_unfold_def:
  make_unfold f seed [] =
    (let (a,seeds) = f seed in (a,LLENGTH seeds)) /\
  make_unfold f seed (n::path) =
    let (a,seeds) = f seed in
       make_unfold f (THE (LNTH n seeds)) path
End

Definition ltree_unfold:
  ltree_unfold f seed =
    gen_ltree (make_unfold f seed)
End

Theorem ltree_unfold:
  ltree_unfold f seed =
    let (a,seeds) = f seed in
      Branch a (LMAP (ltree_unfold f) seeds)
Proof
  fs [ltree_unfold]
  \\ once_rewrite_tac [gen_ltree]
  \\ simp [Once make_unfold_def]
  \\ Cases_on `f seed`
  \\ fs [Branch_11]
  \\ reverse (qspec_then `r` strip_assume_tac fromList_fromSeq)
  \\ fs [LGENLIST_EQ_fromSeq]
  THEN1
   (fs [FUN_EQ_THM,ltree_unfold] \\ rw []
    \\ AP_TERM_TAC \\ fs [FUN_EQ_THM] \\ rw []
    \\ fs [make_unfold_def])
  \\ fs [LGENLIST_EQ_fromList,LMAP_fromList]
  \\ fs [LIST_EQ_REWRITE,EL_MAP] \\ rw []
  \\ rw [ltree_unfold] \\ rw []
  \\ AP_TERM_TAC \\ fs [FUN_EQ_THM] \\ rw []
  \\ fs [make_unfold_def,LNTH_fromList]
QED


(* lemmas for proving equivalences *)

Definition ltree_el_def:
  ltree_el t [] =
    ltree_CASE t (\a ts. SOME (a, LLENGTH ts)) /\
  ltree_el t (n::ns) =
    ltree_CASE t (\a ts.
       case LNTH n ts of
       | NONE => NONE
       | SOME t => ltree_el t ns)
End

Theorem ltree_el_def:
  ltree_el (Branch a ts) [] = SOME (a, LLENGTH ts) /\
  ltree_el (Branch a ts) (n::ns) =
    case LNTH n ts of
    | NONE => NONE
    | SOME t => ltree_el t ns
Proof
  qspec_then `t` strip_assume_tac ltree_cases
  \\ fs [ltree_el_def,ltree_CASE]
QED


Theorem ltree_el_eqv:
  !t1 t2. t1 = t2 <=> !path. ltree_el t1 path = ltree_el t2 path
Proof
  rw [] \\ eq_tac \\ rw []
  \\ fs [GSYM ltree_rep_11,FUN_EQ_THM] \\ rw []
  \\ pop_assum mp_tac
  \\ qid_spec_tac `t1` \\ qid_spec_tac `t2`
  \\ Induct_on `x` \\ rw []
  \\ `ltree_rep_ok (ltree_rep t1) /\ ltree_rep_ok (ltree_rep t2)`
        by fs [ltree_rep_ok_ltree_rep]
  \\ qspec_then `t1` strip_assume_tac ltree_cases
  \\ qspec_then `t2` strip_assume_tac ltree_cases
  \\ rpt BasicProvers.var_eq_tac \\ simp [Branch]
  \\ `ltree_rep_ok (Branch_rep a (LMAP ltree_rep ts)) /\
      ltree_rep_ok (Branch_rep a' (LMAP ltree_rep ts'))` by
   (rw [ltree_rep_ok_Branch_rep_every]
    \\ rename [`LMAP _ ts2`]
    \\ qspec_then `ts2` strip_assume_tac fromList_fromSeq \\ fs []
    \\ fs [LMAP_fromList,every_fromList_EVERY,EVERY_MEM]
    \\ fs [MEM_MAP,PULL_EXISTS])
  \\ fs [ltree_repabs]
  \\ simp [Branch_rep_def,LLENGTH_MAP]
  \\ last_assum (qspec_then `[]` mp_tac)
  \\ rewrite_tac [ltree_el_def] \\ fs [] \\ rw []
  \\ Cases_on `LNTH h ts` \\ Cases_on `LNTH h ts'` \\ fs []
  THEN1 (qspec_then `ts` strip_assume_tac fromList_fromSeq
         \\ qspec_then `ts'` strip_assume_tac fromList_fromSeq
         \\ rw [] \\ fs [LNTH_fromList])
  THEN1 (qspec_then `ts` strip_assume_tac fromList_fromSeq
         \\ qspec_then `ts'` strip_assume_tac fromList_fromSeq
         \\ rw [] \\ fs [LNTH_fromList])
  \\ last_x_assum match_mp_tac \\ rw []
  \\ last_x_assum (qspec_then `h::path` mp_tac)
  \\ fs [ltree_el_def]
QED

Definition ltree_rel_def:
  ltree_rel R x y <=>
    !path.
      OPTREL (\x y. R (FST x) (FST y) /\ SND x = SND y)
        (ltree_el x path) (ltree_el y path)
End

Theorem ltree_rel:
  ltree_rel R (Branch a ts) (Branch b us) <=>
  R a b /\ llist_rel (ltree_rel R) ts us
Proof
  fs [ltree_rel_def,llist_rel_def] \\ rw [] \\ eq_tac \\ rw []
  THEN1 (first_x_assum (qspec_then `[]` mp_tac) \\ fs [ltree_el_def])
  THEN1 (first_x_assum (qspec_then `[]` mp_tac) \\ fs [ltree_el_def])
  THEN1 (first_x_assum (qspec_then `i::path` mp_tac) \\ fs [ltree_el_def])
  \\ Cases_on `path` \\ fs [ltree_el_def]
  \\ Cases_on `LNTH h ts` \\ fs []
  \\ Cases_on `LNTH h us` \\ fs []
  \\ qspec_then `ts` strip_assume_tac fromList_fromSeq
  \\ qspec_then `us` strip_assume_tac fromList_fromSeq
  \\ rw [] \\ fs [LNTH_fromList] \\ metis_tac []
QED

Theorem ltree_rel_eq:
  ltree_rel (=) x y <=> x = y
Proof
  fs [ltree_rel_def,ltree_el_eqv] \\ eq_tac \\ rw []
  \\ first_x_assum (qspec_then `path` mp_tac)
  \\ Cases_on `ltree_el x path` \\ Cases_on `ltree_el y path` \\ fs []
  \\ fs [UNCURRY]
  \\ rename [`FST y = FST z`]
  \\ Cases_on `y` \\ Cases_on `z` \\ fs []
QED

Theorem ltree_bisimulation:
  !t1 t2.
    t1 = t2 <=>
    ?R. R t1 t2 /\
        !a ts a' ts'.
          R (Branch a ts) (Branch a' ts') ==>
          a = a' /\ llist_rel R ts ts'
Proof
  rw [] \\ eq_tac \\ rw []
  THEN1 (qexists_tac `(=)` \\ fs [Branch_11,llist_rel_def] \\ rw [] \\ fs [])
  \\ simp [ltree_el_eqv]
  \\ strip_tac
  \\ last_x_assum mp_tac \\ qid_spec_tac `t1` \\ qid_spec_tac `t2`
  \\ Induct_on `path` \\ rw []
  \\ qspec_then `t1` strip_assume_tac ltree_cases
  \\ qspec_then `t2` strip_assume_tac ltree_cases
  \\ fs []
  THEN1 (fs [ltree_el_def] \\ res_tac \\ fs [llist_rel_def])
  \\ rw [] \\ fs [ltree_el_def]
  \\ res_tac \\ rw []
  \\ fs [llist_rel_def]
  \\ pop_assum (qspec_then `h` mp_tac)
  \\ Cases_on `LNTH h ts` \\ fs []
  \\ Cases_on `LNTH h ts'` \\ fs []
  \\ qspec_then `ts` strip_assume_tac fromList_fromSeq
  \\ qspec_then `ts'` strip_assume_tac fromList_fromSeq
  \\ rw [] \\ fs [LNTH_fromList]
QED


(* misc *)

Definition ltree_lookup_def:
  ltree_lookup t [] = SOME t /\
  ltree_lookup t (n::ns) =
    ltree_CASE t (\a ts.
       case LNTH n ts of
       | NONE => NONE
       | SOME t => ltree_lookup t ns)
End

Theorem ltree_lookup_def:
  ltree_lookup t [] = SOME t /\
  ltree_lookup (Branch a ts) (n::ns) =
    case LNTH n ts of
    | NONE => NONE
    | SOME t => ltree_lookup t ns
Proof
  qspec_then `t` strip_assume_tac ltree_cases
  \\ fs [ltree_lookup_def,ltree_CASE]
QED

Definition subtrees_def:
  subtrees t = { u | ?path. ltree_lookup t path = SOME u }
End

Theorem subtrees:
  subtrees (Branch a ts) =
    Branch a ts INSERT BIGUNION (IMAGE subtrees (LSET ts))
Proof
  fs [subtrees_def,Once EXTENSION,PULL_EXISTS] \\ rw []
  \\ qspec_then `x` strip_assume_tac ltree_cases
  \\ fs [Branch_11] \\ rw [] \\ reverse eq_tac \\ rw []
  THEN1 (qexists_tac `[]` \\ fs [ltree_lookup_def])
  THEN1 (fs [LSET_def,IN_DEF] \\ qexists_tac `n::path` \\ fs [ltree_lookup_def])
  \\ Cases_on `path` \\ fs []
  \\ fs [ltree_lookup_def,Branch_11]
  \\ Cases_on `LNTH h ts` \\ fs [] \\ disj2_tac
  \\ fs [LSET_def,IN_DEF,PULL_EXISTS]
  \\ rpt (goal_assum (first_assum o mp_then Any mp_tac))
QED

Definition ltree_set_def:
  ltree_set t = { a | ?ts. Branch a ts IN subtrees t }
End

Theorem ltree_set:
  ltree_set (Branch a ts) =
    a INSERT BIGUNION (IMAGE ltree_set (LSET ts))
Proof
  fs [ltree_set_def,subtrees,Once EXTENSION,Branch_11]
  \\ rw [] \\ Cases_on `a = x` \\ fs [] \\ fs [PULL_EXISTS] \\ metis_tac []
QED

Definition ltree_map_def:
  ltree_map f = ltree_unfold (\t. ltree_CASE t (\a ts. (f a,ts)))
End

Theorem ltree_map:
  ltree_map f (Branch a xs) = Branch (f a) (LMAP (ltree_map f) xs)
Proof
  fs [ltree_map_def,ltree_unfold,ltree_CASE]
QED

Theorem ltree_map_id:
  ltree_map I t = t
Proof
  fs [ltree_el_eqv] \\ qid_spec_tac `t`
  \\ Induct_on `path` \\ rw [] \\ fs [ltree_el_def]
  \\ qspec_then `t` strip_assume_tac ltree_cases
  \\ fs [ltree_map,ltree_el_def,LLENGTH_MAP]
  \\ rw [] \\ Cases_on `LNTH h ts` \\ fs []
QED

Theorem ltree_map_map:
  ltree_map f (ltree_map g t) = ltree_map (f o g) t
Proof
  fs [ltree_el_eqv] \\ qid_spec_tac `t`
  \\ Induct_on `path` \\ rw [] \\ fs [ltree_el_def]
  \\ qspec_then `t` strip_assume_tac ltree_cases
  \\ fs [ltree_map,ltree_el_def,LLENGTH_MAP]
  \\ rw [] \\ Cases_on `LNTH h ts` \\ fs []
QED

Triviality ltree_lookup_map:
  ltree_lookup (ltree_map f t) path =
    case ltree_lookup t path of
    | NONE => NONE
    | SOME t => ltree_CASE t (\a ts. SOME (Branch (f a) (LMAP (ltree_map f) ts)))
Proof
  qid_spec_tac `t` \\ Induct_on `path` \\ fs [ltree_lookup_def] \\ rw []
  \\ qspec_then `t` strip_assume_tac ltree_cases
  \\ fs [ltree_map,ltree_el_def,LLENGTH_MAP,ltree_CASE]
  \\ fs [ltree_lookup_def]
  \\ Cases_on `LNTH h ts` \\ fs []
QED

Theorem ltree_set_map:
  ltree_set (ltree_map f t) = IMAGE f (ltree_set t)
Proof
  fs [EXTENSION,ltree_set_def,subtrees_def]
  \\ fs [ltree_lookup_map,AllCaseEqs(),ltree_CASE_eq,PULL_EXISTS,Branch_11]
  \\ metis_tac []
QED

Theorem ltree_rel_O:
  ltree_rel R1 O ltree_rel R2 RSUBSET ltree_rel (R1 O R2)
Proof
  fs [ltree_rel_def,RSUBSET,O_DEF,PULL_EXISTS]
  \\ rw [] \\ rpt (first_x_assum (qspec_then `path` mp_tac)) \\ rw []
  \\ Cases_on `ltree_el x path` \\ Cases_on `ltree_el y path` \\ fs [OPTREL_def]
  \\ fs [UNCURRY] \\ metis_tac []
QED


(* update TypeBase *)

Theorem ltree_CASE_cong:
  !M M' f f'.
    M = M' /\
    (!a ts. M' = Branch a ts ==> f a ts = f' a ts) ==>
    ltree_CASE M f = ltree_CASE M' f'
Proof
  rw [] \\ qspec_then `M` strip_assume_tac ltree_cases
  \\ rw [] \\ fs [ltree_CASE]
QED

Overload "case" = “ltree_CASE”
val _ = TypeBase.export
  [TypeBasePure.mk_datatype_info
    { ax = TypeBasePure.ORIG TRUTH,
      induction = TypeBasePure.ORIG ltree_bisimulation,
      case_def = ltree_CASE,
      case_cong = ltree_CASE_cong,
      case_eq = ltree_CASE_eq,
      nchotomy = ltree_cases,
      size = NONE,
      encode = NONE,
      lift = NONE,
      one_one = SOME Branch_11,
      distinct = NONE,
      fields = [],
      accessors = [],
      updates = [],
      destructors = [],
      recognizers = [] } ]

Theorem datatype_ltree:
  DATATYPE ((ltree Branch):bool)
Proof
  rw [boolTheory.DATATYPE_TAG_THM]
QED


(* prove that every finite ltree is an inductively defined rose tree *)

Inductive ltree_finite:
  EVERY ltree_finite ts ==> ltree_finite (Branch a (fromList ts))
End

fun tidy_up ind = ind
  |> Q.SPEC `P` |> UNDISCH |> Q.SPEC `t` |> Q.GEN `t` |> DISCH_ALL |> Q.GEN `P`;

Theorem ltree_finite_ind = tidy_up ltree_finite_ind;
Theorem ltree_finite_strongind = tidy_up ltree_finite_strongind;

Theorem ltree_finite:
  ltree_finite (Branch a ts) <=>
  LFINITE ts /\ !t. t IN LSET ts ==> ltree_finite t
Proof
  simp [Once ltree_finite_cases]
  \\ qspec_then `ts` strip_assume_tac fromList_fromSeq
  \\ fs [LSET_def,IN_DEF,LNTH_fromList,PULL_EXISTS,LFINITE_fromList,EVERY_EL]
QED

Datatype:
  rose_tree = Rose 'a (rose_tree list)
End

Definition from_rose_def:
  from_rose (Rose a ts) = Branch a (fromList (MAP from_rose ts))
Termination
  WF_REL_TAC `measure (rose_tree_size (K 0))` \\ rw []
End

Theorem rose_tree_induction = from_rose_ind;

Theorem ltree_finite_from_rose:
  ltree_finite t <=> ?r. from_rose r = t
Proof
  eq_tac \\ qid_spec_tac `t` THEN1
   (ho_match_mp_tac ltree_finite_ind \\ fs [EVERY_MEM] \\ rw []
    \\ qsuff_tac `?rs. ts = MAP from_rose rs` THEN1
     (strip_tac \\ qexists_tac `Rose a rs` \\ fs [from_rose_def]
      \\ CONV_TAC (DEPTH_CONV ETA_CONV) \\ fs [])
    \\ Induct_on `ts` \\ fs [] \\ rw []
    \\ first_assum (qspec_then `h` assume_tac) \\ fs []
    \\ qexists_tac `r::rs` \\ fs [])
  \\ fs [PULL_EXISTS]
  \\ ho_match_mp_tac from_rose_ind \\ rw []
  \\ once_rewrite_tac [ltree_finite_cases]
  \\ fs [from_rose_def,Branch_11]
  \\ CONV_TAC (DEPTH_CONV ETA_CONV)
  \\ fs [EVERY_MEM,MEM_MAP,PULL_EXISTS]
QED


(* tidy up theory exports *)

val _ = List.app Theory.delete_binding
  ["Branch_rep_def", "dest_Branch_rep_def", "make_ltree_rep_def",
   "make_unfold_def", "path_ok_def", "ltree_absrep", "ltree_absrep",
   "gen_ltree_def", "ltree_rep_ok_def", "Branch",
   "from_rose_def_primitive", "ltree_finite_def"];

val _ = export_theory();

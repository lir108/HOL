(* ************************************************************************* *)
(* Sum of a real-valued function on a set: SIGMA f s                         *)
(* ************************************************************************* *)

open HolKernel Parse boolLib bossLib;

open arithmeticTheory combinTheory res_quanTools pairTheory pred_setTheory
     hurdUtils;

open realTheory realLib seqTheory transcTheory iterateTheory;

val _ = new_theory "real_sigma";

(* ----------------------------------------------------------------------
    REAL_SUM_IMAGE

    This constant is the same as standard mathematics \Sigma operator:

     \Sigma_{x\in P}{f(x)} = SUM_IMAGE f P

    Where f's range is the real numbers and P is finite.
   ---------------------------------------------------------------------- *)

Definition REAL_SUM_IMAGE_DEF :
    REAL_SUM_IMAGE f s = ITSET (\e acc. f e + acc) s (0:real)
End

Overload SIGMA = “REAL_SUM_IMAGE”

Theorem REAL_SUM_IMAGE_THM :
    !f. (REAL_SUM_IMAGE f {} = 0) /\
        (!e s. FINITE s ==>
               (REAL_SUM_IMAGE f (e INSERT s) =
                f e + REAL_SUM_IMAGE f (s DELETE e)))
Proof
  REPEAT STRIP_TAC
  >- SIMP_TAC (srw_ss()) [ITSET_THM, REAL_SUM_IMAGE_DEF]
  >> SIMP_TAC (srw_ss()) [REAL_SUM_IMAGE_DEF]
  >> Q.ABBREV_TAC `g = \e acc. f e + acc`
  >> Suff `ITSET g (e INSERT s) 0 =
                    g e (ITSET g (s DELETE e) 0)`
  >- (Q.UNABBREV_TAC `g` >> SRW_TAC [] [])
  >> MATCH_MP_TAC COMMUTING_ITSET_RECURSES
  >> Q.UNABBREV_TAC `g`
  >> RW_TAC real_ss []
  >> REAL_ARITH_TAC
QED

(* An equivalent theorem linking REAL_SUM_IMAGE and iterate$Sum *)
Theorem REAL_SUM_IMAGE_sum :
    !f s. FINITE s ==> REAL_SUM_IMAGE f s = iterate$Sum s f
Proof
    Q.X_GEN_TAC ‘f’
 >> HO_MATCH_MP_TAC FINITE_INDUCT
 >> CONJ_TAC >- rw [REAL_SUM_IMAGE_THM, SUM_CLAUSES]
 >> rpt STRIP_TAC
 >> ‘s DELETE e = s’ by METIS_TAC [DELETE_NON_ELEMENT]
 >> rw [REAL_SUM_IMAGE_THM, SUM_CLAUSES]
QED

(* it translates a sum theorem into a SIGMA theorem *)
fun translate th = SIMP_RULE std_ss [GSYM REAL_SUM_IMAGE_sum] th;

Theorem REAL_SUM_IMAGE_SING :
    !f e. REAL_SUM_IMAGE f {e} = f e
Proof
    SRW_TAC [][REAL_SUM_IMAGE_THM]
QED

Theorem REAL_SUM_IMAGE_POS :
    !f s. FINITE s /\ (!x. x IN s ==> 0 <= f x) ==>
          0 <= REAL_SUM_IMAGE f s
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_POS_LE]
QED

Theorem REAL_SUM_IMAGE_SPOS :
    !s. FINITE s /\ (~(s = {})) ==>
        !f. (!x. x IN s ==> 0 < f x) ==>
            0 < REAL_SUM_IMAGE f s
Proof
    rw [REAL_SUM_IMAGE_sum]
 >> MATCH_MP_TAC SUM_POS_LT >> art []
 >> CONJ_TAC >- METIS_TAC [REAL_LT_IMP_LE]
 >> fs [GSYM MEMBER_NOT_EMPTY]
 >> Q.EXISTS_TAC ‘x’ >> rw []
QED

(* ‘?x. x IN P’ already indicates ‘P <> {}’, thus the actual conclusion is just
   ‘SIGMA f P <> 0’
 *)
Theorem REAL_SUM_IMAGE_NONZERO :
    !P. FINITE P ==>
        !f. (!x. x IN P ==> 0 <= f x) /\ (?x. x IN P /\ ~(f x = 0)) ==>
            ((~(REAL_SUM_IMAGE f P = 0)) <=> (~(P = {})))
Proof
    rw [REAL_SUM_IMAGE_sum]
 >> ‘P <> {}’ by METIS_TAC [MEMBER_NOT_EMPTY]
 >> rw []
 >> Suff ‘0 < sum P f’ >- METIS_TAC [REAL_LT_IMP_NE]
 >> ‘0 < f x’ by METIS_TAC [REAL_LE_LT]
 >> MATCH_MP_TAC SUM_POS_LT >> rw []
 >> Q.EXISTS_TAC ‘x’ >> art []
QED

(* |- !f s.
        FINITE s /\ (!x. x IN s ==> 0 <= f x) /\ (?x. x IN s /\ 0 < f x) ==>
        0 < SIGMA f s
 *)
Theorem REAL_SUM_IMAGE_POS_LT = translate SUM_POS_LT

val REAL_SUM_IMAGE_IF_ELIM_lem = prove
  (``!s. FINITE s ==>
                (\s. !P f. (!x. x IN s ==> P x) ==>
                        (REAL_SUM_IMAGE (\x. if P x then f x else 0) s =
                         REAL_SUM_IMAGE f s)) s``,
   MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC real_ss [REAL_SUM_IMAGE_THM, IN_INSERT, DELETE_NON_ELEMENT]);

val REAL_SUM_IMAGE_IF_ELIM = store_thm
  ("REAL_SUM_IMAGE_IF_ELIM",
   ``!s P f. FINITE s /\ (!x. x IN s ==> P x) ==>
                (REAL_SUM_IMAGE (\x. if P x then f x else 0) s =
                 REAL_SUM_IMAGE f s)``,
   METIS_TAC [REAL_SUM_IMAGE_IF_ELIM_lem]);

val REAL_SUM_IMAGE_FINITE_SAME_lem = prove
  (``!P. FINITE P ==>
         (\P. !f p.
             p IN P /\ (!q. q IN P ==> (f p = f q)) ==> (REAL_SUM_IMAGE f P = (&(CARD P)) * f p)) P``,
   MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC real_ss [REAL_SUM_IMAGE_THM, CARD_EMPTY, DELETE_NON_ELEMENT]
   >> `f p = f e` by FULL_SIMP_TAC std_ss [IN_INSERT]
   >> FULL_SIMP_TAC std_ss [GSYM DELETE_NON_ELEMENT] >> POP_ASSUM (K ALL_TAC)
   >> RW_TAC real_ss [CARD_INSERT, ADD1]
   >> ONCE_REWRITE_TAC [GSYM REAL_ADD]
   >> RW_TAC real_ss [REAL_ADD_RDISTRIB]
   >> Suff `REAL_SUM_IMAGE f s = & (CARD s) * f e`
   >- RW_TAC real_ss [REAL_ADD_COMM]
   >> (MP_TAC o Q.SPECL [`s`]) SET_CASES >> RW_TAC std_ss []
   >- RW_TAC real_ss [REAL_SUM_IMAGE_THM, CARD_EMPTY]
   >> `f e = f x` by FULL_SIMP_TAC std_ss [IN_INSERT]
   >> FULL_SIMP_TAC std_ss [] >> POP_ASSUM (K ALL_TAC)
   >> Q.PAT_ASSUM `!f p. b` MATCH_MP_TAC >> METIS_TAC [IN_INSERT]);

val REAL_SUM_IMAGE_FINITE_SAME = store_thm
  ("REAL_SUM_IMAGE_FINITE_SAME",
   ``!P. FINITE P ==>
         !f p.
             p IN P /\ (!q. q IN P ==> (f p = f q)) ==> (REAL_SUM_IMAGE f P = (&(CARD P)) * f p)``,
   MP_TAC REAL_SUM_IMAGE_FINITE_SAME_lem >> RW_TAC std_ss []);

val REAL_SUM_IMAGE_FINITE_CONST = store_thm
  ("REAL_SUM_IMAGE_FINITE_CONST",
   ``!P. FINITE P ==>
        !f x. (!y. f y = x) ==> (REAL_SUM_IMAGE f P = (&(CARD P)) * x)``,
   REPEAT STRIP_TAC
   >> (MP_TAC o Q.SPECL [`P`]) REAL_SUM_IMAGE_FINITE_SAME
   >> RW_TAC std_ss []
   >> POP_ASSUM (MP_TAC o (Q.SPECL [`f`]))
   >> RW_TAC std_ss []
   >> (MP_TAC o Q.SPECL [`P`]) SET_CASES
   >> RW_TAC std_ss [] >- RW_TAC real_ss [REAL_SUM_IMAGE_THM, CARD_EMPTY]
   >> POP_ASSUM (K ALL_TAC)
   >> POP_ASSUM MATCH_MP_TAC
   >> Q.EXISTS_TAC `x'` >> RW_TAC std_ss [IN_INSERT]);

val REAL_SUM_IMAGE_FINITE_CONST2 = store_thm (* from "examples/diningcryptos" *)
  ("REAL_SUM_IMAGE_FINITE_CONST2",
   ``!P. FINITE P ==>
        !f x. (!y. y IN P ==> (f y = x)) ==> (REAL_SUM_IMAGE f P = (&(CARD P)) * x)``,
   REPEAT STRIP_TAC
   >> (MP_TAC o Q.SPECL [`P`]) REAL_SUM_IMAGE_FINITE_SAME
   >> RW_TAC std_ss []
   >> POP_ASSUM (MP_TAC o (Q.SPECL [`f`]))
   >> RW_TAC std_ss []
   >> (MP_TAC o Q.SPECL [`P`]) SET_CASES
   >> RW_TAC std_ss [] >- RW_TAC real_ss [REAL_SUM_IMAGE_THM, CARD_EMPTY]
   >> POP_ASSUM (K ALL_TAC)
   >> POP_ASSUM MATCH_MP_TAC
   >> Q.EXISTS_TAC `x'` >> RW_TAC std_ss [IN_INSERT]);

Theorem REAL_SUM_IMAGE_FINITE_CONST3 :
    !P. FINITE P ==>
        !c. (REAL_SUM_IMAGE (\x. c) P = (&(CARD P)) * c)
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_CONST]
QED

val REAL_SUM_IMAGE_IN_IF_lem = prove
  (``!P. FINITE P ==>
                (\P.!f. REAL_SUM_IMAGE f P = REAL_SUM_IMAGE (\x. if x IN P then f x else 0) P) P``,
   MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC real_ss [REAL_SUM_IMAGE_THM]
   >> POP_ASSUM MP_TAC
   >> ONCE_REWRITE_TAC [DELETE_NON_ELEMENT]
   >> SIMP_TAC real_ss [IN_INSERT]
   >> `REAL_SUM_IMAGE (\x. (if (x = e) \/ x IN s then f x else 0)) s =
       REAL_SUM_IMAGE (\x. (if x IN s then f x else 0)) s`
        by (POP_ASSUM (MP_TAC o Q.SPECL [`(\x. (if (x = e) \/ x IN s then f x else 0))`])
            >> RW_TAC std_ss [])
   >> POP_ORW
   >> POP_ASSUM (MP_TAC o Q.SPECL [`f`])
   >> RW_TAC real_ss []);

val REAL_SUM_IMAGE_IN_IF = store_thm
  ("REAL_SUM_IMAGE_IN_IF",
   ``!P. FINITE P ==>
        !f. REAL_SUM_IMAGE f P = REAL_SUM_IMAGE (\x. if x IN P then f x else 0) P``,
   METIS_TAC [REAL_SUM_IMAGE_IN_IF_lem]);

Theorem REAL_SUM_IMAGE_CMUL :
    !P. FINITE P ==>
        !f c. (REAL_SUM_IMAGE (\x. c * f x) P = c * (REAL_SUM_IMAGE f P))
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_LMUL]
QED

Theorem REAL_SUM_IMAGE_NEG :
    !P. FINITE P ==>
        !f. (REAL_SUM_IMAGE (\x. ~ f x) P = ~ (REAL_SUM_IMAGE f P))
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_NEG]
QED

Theorem REAL_SUM_IMAGE_IMAGE :
    !P. FINITE P ==>
        !f'. INJ f' P (IMAGE f' P) ==>
             !f. REAL_SUM_IMAGE f (IMAGE f' P) = REAL_SUM_IMAGE (f o f') P
Proof
    rw [REAL_SUM_IMAGE_sum, INJ_DEF]
 >> MATCH_MP_TAC SUM_IMAGE >> rw []
QED

Theorem REAL_SUM_IMAGE_DISJOINT_UNION :
    !P P'. FINITE P /\ FINITE P' /\ DISJOINT P P' ==>
                (!f. REAL_SUM_IMAGE f (P UNION P') =
                     REAL_SUM_IMAGE f P +
                     REAL_SUM_IMAGE f P')
Proof
    rw [REAL_SUM_IMAGE_sum]
 >> MATCH_MP_TAC SUM_UNION
 >> rw [GSYM DISJOINT_DEF, FINITE_UNION]
QED

val REAL_SUM_IMAGE_EQ_CARD_lem = prove
   (``!P. FINITE P ==>
        (\P. REAL_SUM_IMAGE (\x. if x IN P then 1 else 0) P = (&(CARD P))) P``,
   MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC real_ss [REAL_SUM_IMAGE_THM, CARD_EMPTY, IN_INSERT]
   >> (MP_TAC o Q.SPECL [`s`]) CARD_INSERT
   >> RW_TAC real_ss [ADD1] >> ONCE_REWRITE_TAC [GSYM REAL_ADD]
   >> Suff `REAL_SUM_IMAGE (\x. (if (x = e) \/ x IN s then 1 else 0)) (s DELETE e) =
                REAL_SUM_IMAGE (\x. (if x IN s then 1 else 0)) s`
   >- RW_TAC real_ss []
   >> Q.PAT_ASSUM `REAL_SUM_IMAGE (\x. (if x IN s then 1 else 0)) s = & (CARD s)` (K ALL_TAC)
   >> FULL_SIMP_TAC std_ss [DELETE_NON_ELEMENT]
   >> `REAL_SUM_IMAGE (\x. (if (x = e) \/ x IN s then 1 else 0)) s =
       REAL_SUM_IMAGE (\x. if x IN s then (\x. (if (x = e) \/ x IN s then 1 else 0)) x else 0) s`
        by (METIS_TAC [REAL_SUM_IMAGE_IN_IF])
   >> RW_TAC std_ss []);

val REAL_SUM_IMAGE_EQ_CARD = store_thm
  ("REAL_SUM_IMAGE_EQ_CARD",
   ``!P. FINITE P ==>
        (REAL_SUM_IMAGE (\x. if x IN P then 1 else 0) P = (&(CARD P)))``,
   METIS_TAC [REAL_SUM_IMAGE_EQ_CARD_lem]);

val REAL_SUM_IMAGE_INV_CARD_EQ_1 = store_thm
  ("REAL_SUM_IMAGE_INV_CARD_EQ_1",
   ``!P. (~(P = {})) /\ FINITE P ==>
                (REAL_SUM_IMAGE (\s. if s IN P then inv (& (CARD P)) else 0) P = 1)``,
    REPEAT STRIP_TAC
    >> `(\s. if s IN P then inv (& (CARD P)) else 0) = (\s. inv (& (CARD P)) * (\s. if s IN P then 1 else 0) s)`
        by (RW_TAC std_ss [FUN_EQ_THM] >> RW_TAC real_ss [])
    >> POP_ORW
    >> `REAL_SUM_IMAGE (\s. inv (& (CARD P)) * (\s. (if s IN P then 1 else 0)) s) P =
        (inv (& (CARD P))) * (REAL_SUM_IMAGE (\s. (if s IN P then 1 else 0)) P)`
                by (MATCH_MP_TAC REAL_SUM_IMAGE_CMUL >> RW_TAC std_ss [])
    >> POP_ORW
    >> `REAL_SUM_IMAGE (\s. (if s IN P then 1 else 0)) P = (&(CARD P))`
                by (MATCH_MP_TAC REAL_SUM_IMAGE_EQ_CARD >> RW_TAC std_ss [])
    >> POP_ORW
    >> MATCH_MP_TAC REAL_MUL_LINV
    >> RW_TAC real_ss []
    >> METIS_TAC [CARD_EQ_0]);

val REAL_SUM_IMAGE_INTER_NONZERO_lem = prove
  (``!P. FINITE P ==>
        (\P. !f. REAL_SUM_IMAGE f (P INTER (\p. ~(f p = 0))) =
                 REAL_SUM_IMAGE f P) P``,
   MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC std_ss [REAL_SUM_IMAGE_THM, INTER_EMPTY, INSERT_INTER]
   >> FULL_SIMP_TAC std_ss [DELETE_NON_ELEMENT]
   >> (RW_TAC std_ss [IN_DEF] >> RW_TAC real_ss [])
   >> `FINITE (s INTER (\p. ~(f p = 0)))` by (MATCH_MP_TAC INTER_FINITE >> RW_TAC std_ss [])
   >> RW_TAC std_ss [REAL_SUM_IMAGE_THM]
   >> FULL_SIMP_TAC std_ss [GSYM DELETE_NON_ELEMENT]
   >> `~(e IN (s INTER (\p. ~(f p = 0))))`
        by RW_TAC std_ss [IN_INTER]
   >> FULL_SIMP_TAC std_ss [DELETE_NON_ELEMENT]);

val REAL_SUM_IMAGE_INTER_NONZERO = store_thm
  ("REAL_SUM_IMAGE_INTER_NONZERO",
   ``!P. FINITE P ==>
        !f. REAL_SUM_IMAGE f (P INTER (\p. ~(f p = 0))) =
                 REAL_SUM_IMAGE f P``,
   METIS_TAC [REAL_SUM_IMAGE_INTER_NONZERO_lem]);

val REAL_SUM_IMAGE_INTER_ELIM_lem = prove
  (``!P. FINITE P ==>
        (\P. !f P'. (!x. (~(x IN P')) ==> (f x = 0)) ==>
                        (REAL_SUM_IMAGE f (P INTER P') =
                         REAL_SUM_IMAGE f P)) P``,
   MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC std_ss [INTER_EMPTY, REAL_SUM_IMAGE_THM, INSERT_INTER]
   >> Cases_on `e IN P'`
   >- (`~ (e IN (s INTER P'))` by RW_TAC std_ss [IN_INTER]
       >> FULL_SIMP_TAC std_ss [INTER_FINITE, REAL_SUM_IMAGE_THM, DELETE_NON_ELEMENT])
   >> FULL_SIMP_TAC real_ss []
   >> FULL_SIMP_TAC std_ss [DELETE_NON_ELEMENT]);

val REAL_SUM_IMAGE_INTER_ELIM = store_thm
  ("REAL_SUM_IMAGE_INTER_ELIM",
   ``!P. FINITE P ==>
         !f P'. (!x. (~(x IN P')) ==> (f x = 0)) ==>
                        (REAL_SUM_IMAGE f (P INTER P') =
                         REAL_SUM_IMAGE f P)``,
   METIS_TAC [REAL_SUM_IMAGE_INTER_ELIM_lem]);

val REAL_SUM_IMAGE_COUNT = store_thm
  ("REAL_SUM_IMAGE_COUNT",
   ``!f n. REAL_SUM_IMAGE f (pred_set$count n) =
           sum (0,n) f``,
   STRIP_TAC >> Induct
   >- RW_TAC std_ss [pred_setTheory.count_def, REAL_SUM_IMAGE_THM, GSPEC_F, sum]
   >> `pred_set$count (SUC n) = n INSERT pred_set$count n`
        by (RW_TAC std_ss [EXTENSION, IN_INSERT, pred_setTheory.IN_COUNT] >> DECIDE_TAC)
   >> RW_TAC std_ss [REAL_SUM_IMAGE_THM, sum, pred_setTheory.FINITE_COUNT]
   >> `pred_set$count n DELETE n = pred_set$count n`
        by RW_TAC arith_ss [DELETE_DEF, DIFF_DEF, IN_SING, pred_setTheory.IN_COUNT,
                            Once EXTENSION, pred_setTheory.IN_COUNT, GSPECIFICATION,
                            DECIDE ``!(x:num) (y:num). x < y ==> ~(x = y)``]
   >> RW_TAC std_ss [REAL_ADD_SYM]);

Theorem REAL_SUM_IMAGE_MONO :
    !P. FINITE P ==>
        !f f'. (!x. x IN P ==> f x <= f' x) ==>
               REAL_SUM_IMAGE f P <= REAL_SUM_IMAGE f' P
Proof
    rw [REAL_SUM_IMAGE_sum]
 >> MATCH_MP_TAC SUM_MONO_LE >> rw []
QED

(* |- !f g s.
        FINITE s /\ (!x. x IN s ==> f x <= g x) /\ (?x. x IN s /\ f x < g x) ==>
        SIGMA f s < SIGMA g s
 *)
Theorem REAL_SUM_IMAGE_MONO_LT = translate SUM_MONO_LT

val REAL_SUM_IMAGE_POS_MEM_LE = store_thm
  ("REAL_SUM_IMAGE_POS_MEM_LE",
   ``!P. FINITE P ==>
        !f. (!x. x IN P ==> 0 <= f x) ==>
            (!x. x IN P ==> f x <= REAL_SUM_IMAGE f P)``,
   Suff `!P. FINITE P ==>
        (\P. !f. (!x. x IN P ==> 0 <= f x) ==>
            (!x. x IN P ==> f x <= REAL_SUM_IMAGE f P)) P`
   >- PROVE_TAC []
   >> MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC std_ss [REAL_SUM_IMAGE_THM, NOT_IN_EMPTY, IN_INSERT,
                     DISJ_IMP_THM, FORALL_AND_THM,
                     DELETE_NON_ELEMENT]
   >- (Suff `f e + 0 <= f e + REAL_SUM_IMAGE f s` >- RW_TAC real_ss []
       >> MATCH_MP_TAC REAL_LE_LADD_IMP
       >> MATCH_MP_TAC REAL_SUM_IMAGE_POS >> ASM_REWRITE_TAC [])
   >> Suff `0 + f x <= f e + REAL_SUM_IMAGE f s` >- RW_TAC real_ss []
   >> MATCH_MP_TAC REAL_LE_ADD2 >> PROVE_TAC []);

val REAL_SUM_IMAGE_CONST_EQ_1_EQ_INV_CARD = store_thm
  ("REAL_SUM_IMAGE_CONST_EQ_1_EQ_INV_CARD",
   ``!P. FINITE P ==>
        !f. (REAL_SUM_IMAGE f P = 1) /\
            (!x y. x IN P /\ y IN P ==> (f x = f y)) ==>
            (!x. x IN P ==> (f x = inv (& (CARD P))))``,
   Suff `!P. FINITE P ==>
        (\P. !f. (REAL_SUM_IMAGE f P = 1) /\
            (!x y. x IN P /\ y IN P ==> (f x = f y)) ==>
            (!x. x IN P ==> (f x = inv (& (CARD P))))) P`
  >- RW_TAC std_ss []
  >> MATCH_MP_TAC FINITE_INDUCT
  >> RW_TAC real_ss [REAL_SUM_IMAGE_THM, IN_INSERT, DELETE_NON_ELEMENT]
  >- (RW_TAC std_ss [(UNDISCH o Q.SPEC `s`) CARD_INSERT]
      >> FULL_SIMP_TAC std_ss [GSYM DELETE_NON_ELEMENT]
      >> Q.PAT_ASSUM `(f:'a->real) e + REAL_SUM_IMAGE f s = 1`
        (MP_TAC o REWRITE_RULE [Once ((UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_IN_IF)])
      >> `(\x:'a. (if (x IN s) then (f:'a -> real) x else (0:real))) =
               (\x:'a. (if (x IN s) then (\x:'a. (f:'a -> real) e) x else (0:real)))`
        by METIS_TAC []
      >> POP_ORW
      >> ONCE_REWRITE_TAC [(GSYM o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_IN_IF]
      >> (MP_TAC o Q.SPECL [`(\x. (f:'a->real) e)`, `(f:'a->real) e`] o
          UNDISCH o Q.ISPEC `s:'a -> bool`) REAL_SUM_IMAGE_FINITE_CONST
      >> SIMP_TAC std_ss []
      >> STRIP_TAC >> POP_ASSUM (K ALL_TAC)
      >> `f e + & (CARD s) * f e = f e *( & (CARD s) + 1)` by REAL_ARITH_TAC
      >> POP_ORW
      >> `1:real = &1` by RW_TAC real_ss []
      >> POP_ASSUM (fn thm => SIMP_TAC std_ss [thm, REAL_OF_NUM_ADD, GSYM ADD1])
      >> REPEAT (POP_ASSUM (K ALL_TAC))
      >> METIS_TAC [REAL_NZ_IMP_LT, GSYM REAL_EQ_RDIV_EQ, REAL_INV_1OVER, SUC_NOT])
   >> FULL_SIMP_TAC std_ss [GSYM DELETE_NON_ELEMENT]
   >> RW_TAC std_ss [(UNDISCH o Q.SPEC `s`) CARD_INSERT]
   >> Q.PAT_ASSUM `f e + REAL_SUM_IMAGE f s = 1`
        (MP_TAC o REWRITE_RULE [Once ((UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_IN_IF)])
   >> `(\x:'a. (if (x IN s) then (f:'a -> real) x else (0:real))) =
               (\x:'a. (if (x IN s) then (\x:'a. (f:'a -> real) e) x else (0:real)))`
        by METIS_TAC []
   >> POP_ORW
   >> ONCE_REWRITE_TAC [(GSYM o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_IN_IF]
   >> (MP_TAC o Q.SPECL [`(\x. (f:'a->real) e)`, `(f:'a->real) e`] o
          UNDISCH o Q.ISPEC `s:'a -> bool`) REAL_SUM_IMAGE_FINITE_CONST
   >> SIMP_TAC std_ss []
   >> STRIP_TAC >> POP_ASSUM (K ALL_TAC)
   >> `f e + & (CARD s) * f e = f e *( & (CARD s) + 1)` by REAL_ARITH_TAC
   >> POP_ORW
   >> `1:real = &1` by RW_TAC real_ss []
   >> POP_ASSUM (fn thm => SIMP_TAC std_ss [thm, REAL_OF_NUM_ADD, GSYM ADD1])
   >> `f x = f e` by METIS_TAC [] >> POP_ORW
   >> REPEAT (POP_ASSUM (K ALL_TAC))
   >> METIS_TAC [REAL_NZ_IMP_LT, GSYM REAL_EQ_RDIV_EQ, REAL_INV_1OVER, SUC_NOT]);

Theorem REAL_SUM_IMAGE_ADD :
    !s. FINITE s ==>
        !f f'. REAL_SUM_IMAGE (\x. f x + f' x) s =
               REAL_SUM_IMAGE f s + REAL_SUM_IMAGE f' s
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_ADD]
QED

val REAL_SUM_IMAGE_REAL_SUM_IMAGE = store_thm
  ("REAL_SUM_IMAGE_REAL_SUM_IMAGE",
   ``!s s' f. FINITE s /\ FINITE s' ==>
        (REAL_SUM_IMAGE (\x. REAL_SUM_IMAGE (f x) s') s =
         REAL_SUM_IMAGE (\x. f (FST x) (SND x)) (s CROSS s'))``,
   Suff `!s. FINITE s ==>
             (\s. !s' f. FINITE s' ==>
        (REAL_SUM_IMAGE (\x. REAL_SUM_IMAGE (f x) s') s =
         REAL_SUM_IMAGE (\x. f (FST x) (SND x)) (s CROSS s'))) s`
   >- RW_TAC std_ss []
   >> MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC std_ss [CROSS_EMPTY, REAL_SUM_IMAGE_THM, DELETE_NON_ELEMENT]
   >> `((e INSERT s) CROSS s') = (IMAGE (\x. (e,x)) s') UNION (s CROSS s')`
        by (RW_TAC std_ss [Once EXTENSION, IN_INSERT, IN_SING, IN_CROSS, IN_UNION, IN_IMAGE]
            >> (MP_TAC o Q.ISPEC `x:'a#'b`) pair_CASES
            >> RW_TAC std_ss [] >> FULL_SIMP_TAC std_ss [FST,SND, GSYM DELETE_NON_ELEMENT]
            >> METIS_TAC [])
   >> POP_ORW
   >> `DISJOINT (IMAGE (\x. (e,x)) s') (s CROSS s')`
        by (FULL_SIMP_TAC std_ss [GSYM DELETE_NON_ELEMENT, DISJOINT_DEF, Once EXTENSION,
                                  NOT_IN_EMPTY, IN_INTER, IN_CROSS, IN_SING, IN_IMAGE]
            >> STRIP_TAC >> (MP_TAC o Q.ISPEC `x:'a#'b`) pair_CASES
            >> RW_TAC std_ss [FST, SND]
            >> METIS_TAC [])
   >> (MP_TAC o REWRITE_RULE [GSYM AND_IMP_INTRO] o
        Q.ISPECL [`IMAGE (\x. (e:'a,x)) (s':'b->bool)`, `(s:'a->bool) CROSS (s':'b->bool)`])
        REAL_SUM_IMAGE_DISJOINT_UNION
   >> RW_TAC std_ss [FINITE_CROSS, IMAGE_FINITE]
   >> POP_ASSUM (K ALL_TAC)
   >> (MP_TAC o Q.SPEC `(\x. (e,x))` o UNDISCH o Q.SPEC `s'` o
        INST_TYPE [``:'c``|->``:'a # 'b``] o INST_TYPE [``:'a``|->``:'b``] o
        INST_TYPE [``:'b``|->``:'c``]) REAL_SUM_IMAGE_IMAGE
   >> RW_TAC std_ss [INJ_DEF, IN_IMAGE, o_DEF] >> METIS_TAC []);

Theorem REAL_SUM_IMAGE_0 :
    !s. FINITE s ==> (REAL_SUM_IMAGE (\x. 0) s = 0)
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_0]
QED

val SEQ_REAL_SUM_IMAGE = store_thm
  ("SEQ_REAL_SUM_IMAGE",
   ``!s. FINITE s ==>
        !f f'. (!x. x IN s ==> (\n. f n x) --> f' x) ==>
                (\n. REAL_SUM_IMAGE (f n) s) -->
                REAL_SUM_IMAGE f' s``,
   Suff `!s. FINITE s ==>
                (\s. !f f'. (!x. x IN s ==> (\n. f n x) --> f' x) ==>
                (\n. REAL_SUM_IMAGE (f n) s) -->
                REAL_SUM_IMAGE f' s) s`
   >- RW_TAC std_ss []
   >> MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC std_ss [REAL_SUM_IMAGE_THM, SEQ_CONST, IN_INSERT, DELETE_NON_ELEMENT]
   >> `(\n. f n e + REAL_SUM_IMAGE (f n) s) = (\n. (\n. f n e) n + (\n. REAL_SUM_IMAGE (f n) s) n)`
        by RW_TAC std_ss []
   >> POP_ORW
   >> MATCH_MP_TAC SEQ_ADD
   >> METIS_TAC []);

val NESTED_REAL_SUM_IMAGE_REVERSE = store_thm
  ("NESTED_REAL_SUM_IMAGE_REVERSE",
   ``!f s s'. FINITE s /\ FINITE s' ==>
                (REAL_SUM_IMAGE (\x. REAL_SUM_IMAGE (f x) s') s =
                 REAL_SUM_IMAGE (\x. REAL_SUM_IMAGE (\y. f y x) s) s')``,
   RW_TAC std_ss [REAL_SUM_IMAGE_REAL_SUM_IMAGE]
   >> `(s' CROSS s) = IMAGE (\x. (SND x, FST x)) (s CROSS s')`
        by (RW_TAC std_ss [EXTENSION, IN_CROSS, IN_IMAGE]
            >> EQ_TAC >- (STRIP_TAC >> Q.EXISTS_TAC `(SND x, FST x)` >> RW_TAC std_ss [PAIR])
            >> RW_TAC std_ss [] >> RW_TAC std_ss [FST, SND])
   >> POP_ORW
   >> `FINITE (s CROSS s')` by RW_TAC std_ss [FINITE_CROSS]
   >> `INJ (\x. (SND x,FST x)) (s CROSS s') (IMAGE (\x. (SND x,FST x)) (s CROSS s'))`
        by (RW_TAC std_ss [INJ_DEF, IN_IMAGE] >- METIS_TAC []
            >> METIS_TAC [PAIR, PAIR_EQ])
   >> `REAL_SUM_IMAGE (\x. f (SND x) (FST x)) (IMAGE (\x. (SND x,FST x)) (s CROSS s')) =
       REAL_SUM_IMAGE ((\x. f (SND x) (FST x)) o (\x. (SND x,FST x))) (s CROSS s')`
        by METIS_TAC [REAL_SUM_IMAGE_IMAGE]
   >> POP_ORW
   >> RW_TAC std_ss [o_DEF]);

val REAL_SUM_IMAGE_EQ_sum = store_thm
("REAL_SUM_IMAGE_EQ_sum", ``!n r. sum (0,n) r = REAL_SUM_IMAGE r (count n)``,
  RW_TAC std_ss []
  >> Induct_on `n`
  >- RW_TAC std_ss [sum,REAL_SUM_IMAGE_THM,COUNT_ZERO]
  >> RW_TAC std_ss [sum,COUNT_SUC,REAL_SUM_IMAGE_THM,FINITE_COUNT]
  >> Suff `count n DELETE n = count n`
  >- RW_TAC std_ss [REAL_ADD_COMM]
  >> RW_TAC std_ss [GSYM DELETE_NON_ELEMENT,IN_COUNT]);

val REAL_SUM_IMAGE_POW = store_thm
 ("REAL_SUM_IMAGE_POW",``!a s. FINITE s
           ==> ((REAL_SUM_IMAGE a s) pow 2 =
                REAL_SUM_IMAGE (\(i,j). a i * a j) (s CROSS s):real)``,
  RW_TAC std_ss []
  >> `(\(i,j). a i * a j) = (\x. (\i j. a i * a j) (FST x) (SND x))`
       by (RW_TAC std_ss [FUN_EQ_THM]
           >> Cases_on `x`
           >> RW_TAC std_ss [])
  >> POP_ORW
  >> (MP_TAC o GSYM o Q.SPECL [`s`,`s`,`(\i j. a i * a j)`] o
          INST_TYPE [``:'b`` |-> ``:'a``]) REAL_SUM_IMAGE_REAL_SUM_IMAGE
  >> RW_TAC std_ss [REAL_SUM_IMAGE_CMUL]
  >> RW_TAC std_ss [Once REAL_MUL_COMM,REAL_SUM_IMAGE_CMUL,POW_2]);

Theorem REAL_SUM_IMAGE_EQ :
    !s (f:'a->real) f'. FINITE s /\ (!x. x IN s ==> (f x = f' x))
                    ==> (REAL_SUM_IMAGE f s = REAL_SUM_IMAGE f' s)
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_EQ]
QED

val REAL_SUM_IMAGE_IN_IF_ALT = store_thm
  ("REAL_SUM_IMAGE_IN_IF_ALT",``!s f z:real.
         FINITE s ==> (REAL_SUM_IMAGE f s = REAL_SUM_IMAGE (\x. if x IN s then f x else z) s)``,
  RW_TAC std_ss []
  >> MATCH_MP_TAC REAL_SUM_IMAGE_EQ
  >> RW_TAC std_ss []);

Theorem REAL_SUM_IMAGE_SUB :
    !s (f:'a -> real) f'. FINITE s ==>
                 (REAL_SUM_IMAGE (\x. f x - f' x) s =
                  REAL_SUM_IMAGE f s - REAL_SUM_IMAGE f' s)
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_SUB]
QED

val REAL_SUM_IMAGE_MONO_SET = store_thm
 ("REAL_SUM_IMAGE_MONO_SET", ``!(f:'a -> real) s t.
         FINITE s /\ FINITE t /\ s SUBSET t /\ (!x. x IN t ==> 0 <= f x)
              ==> REAL_SUM_IMAGE f s <= REAL_SUM_IMAGE f t``,
  RW_TAC std_ss []
  >> `t = s UNION (t DIFF s)` by RW_TAC std_ss [UNION_DIFF]
  >> `FINITE (t DIFF s)` by RW_TAC std_ss [FINITE_DIFF]
  >> `DISJOINT s (t DIFF s)` by (
        RW_TAC std_ss [DISJOINT_DEF,IN_DIFF,EXTENSION,GSPECIFICATION,
                       NOT_IN_EMPTY,IN_INTER] >-
        METIS_TAC [])
  >> `REAL_SUM_IMAGE f t = REAL_SUM_IMAGE f s + REAL_SUM_IMAGE f (t DIFF s)`
      by METIS_TAC [REAL_SUM_IMAGE_DISJOINT_UNION]
  >> POP_ORW
  >> Suff `0 <= REAL_SUM_IMAGE f (t DIFF s)`
  >- REAL_ARITH_TAC
  >> METIS_TAC [REAL_SUM_IMAGE_POS,IN_DIFF]);

val REAL_SUM_IMAGE_CROSS_SYM = store_thm
 ("REAL_SUM_IMAGE_CROSS_SYM", ``!f s1 s2. FINITE s1 /\ FINITE s2 ==>
   (REAL_SUM_IMAGE (\(x,y). f (x,y)) (s1 CROSS s2) = REAL_SUM_IMAGE (\(y,x). f (x,y)) (s2 CROSS s1))``,
  RW_TAC std_ss []
  >> `s2 CROSS s1 = IMAGE (\a. (SND a, FST a)) (s1 CROSS s2)`
        by (RW_TAC std_ss [IN_IMAGE, IN_CROSS,EXTENSION] >> METIS_TAC [FST,SND,PAIR])
  >> POP_ORW
  >> `INJ (\a. (SND a, FST a)) (s1 CROSS s2) (IMAGE (\a. (SND a, FST a)) (s1 CROSS s2))`
       by (RW_TAC std_ss [INJ_DEF, IN_IMAGE, IN_CROSS]
           >> METIS_TAC [FST,SND,PAIR])
  >> RW_TAC std_ss [REAL_SUM_IMAGE_IMAGE, IMAGE_FINITE, FINITE_CROSS, o_DEF]
  >> `(\(x,y). f (x,y)) = (\a. f a)`
       by (RW_TAC std_ss [FUN_EQ_THM]
           >> Cases_on `a`
           >> RW_TAC std_ss [])
  >> RW_TAC std_ss []);

Theorem REAL_SUM_IMAGE_ABS_TRIANGLE :
    !f s. FINITE s ==> abs (REAL_SUM_IMAGE f s) <= REAL_SUM_IMAGE (abs o f) s
Proof
    rw [REAL_SUM_IMAGE_sum, SUM_ABS, o_DEF]
QED

Theorem REAL_SUM_IMAGE_DELETE = translate SUM_DELETE
Theorem REAL_SUM_IMAGE_SWAP = translate SUM_SWAP
Theorem REAL_SUM_IMAGE_BOUND = translate SUM_BOUND

Theorem REAL_SUM_IMAGE_IMAGE_LE :
    !f:'a->'b g s.
        FINITE s /\
        (!x. x IN s ==> (0:real) <= g (f x))
        ==> REAL_SUM_IMAGE g (IMAGE f s) <= REAL_SUM_IMAGE (g o f) s
Proof
    rpt STRIP_TAC
 >> ‘FINITE (IMAGE f s)’ by METIS_TAC [IMAGE_FINITE]
 >> rw [REAL_SUM_IMAGE_sum]
 >> MATCH_MP_TAC SUM_IMAGE_LE >> art []
QED

Theorem REAL_SUM_IMAGE_PERMUTES :
    !f p s:'a->bool. FINITE s /\ p PERMUTES s ==>
                     REAL_SUM_IMAGE f s = REAL_SUM_IMAGE (f o p) s
Proof
    rw [BIJ_ALT, REAL_SUM_IMAGE_sum, IN_FUNSET]
 >> MATCH_MP_TAC SUM_BIJECTION >> rw []
 >> Q.PAT_X_ASSUM ‘!y. y IN s ==> ?!x. P’ (MP_TAC o Q.SPEC ‘y’)
 >> RW_TAC bool_ss [EXISTS_UNIQUE_DEF] (* why it takes so long time? *)
 >> Q.EXISTS_TAC ‘x’ >> art []
QED

(* ------------------------------------------------------------------------- *)
(* ---- jensen's inequality (from "miller" example)             ------------ *)
(* ------------------------------------------------------------------------- *)

val jensen_convex_SIGMA = store_thm
  ("jensen_convex_SIGMA",
   ``!s. FINITE s ==>
         !f g g'. (SIGMA g s = 1) /\
                  (!x. x IN s ==> 0 <= g x /\ g x <= 1) /\
                  f IN convex_fn ==>
                        f (SIGMA (\x. g x * g' x) s) <= SIGMA (\x. g x * f (g' x)) s``,
   Suff `!s. FINITE s ==>
             (\s. !f g g'. (SIGMA g s = 1) /\
                  (!x. x IN s ==> 0 <= g x /\ g x <= 1) /\
                  f IN convex_fn ==>
                        f (SIGMA (\x. g x * g' x) s) <= SIGMA (\x. g x * f (g' x)) s) s`
   >- RW_TAC std_ss []
   >> MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC real_ss [REAL_SUM_IMAGE_THM, DELETE_NON_ELEMENT, IN_INSERT, DISJ_IMP_THM, FORALL_AND_THM]
   >> Cases_on `g e = 0` >- FULL_SIMP_TAC real_ss []
   >> Cases_on `g e = 1`
   >- ( FULL_SIMP_TAC real_ss []
        >> Know `!s. FINITE s ==>
                (\s. !g. (SIGMA g s = 0) /\ (!x. x IN s ==> 0 <= g x /\ g x <= 1) ==>
                            (!x. x IN s ==> (g x = 0))) s`
        >- (MATCH_MP_TAC FINITE_INDUCT \\
            RW_TAC real_ss [REAL_SUM_IMAGE_THM, DELETE_NON_ELEMENT, IN_INSERT, DISJ_IMP_THM,
                            FORALL_AND_THM, NOT_IN_EMPTY] >| (* 2 sub-goals *)
            [ (* goal 1 (of 2) *)
              Know `!(x:real) y. 0 <= x /\ 0 <= y /\ (x + y = 0) ==> ((x = 0) /\ (y = 0))`
              >- REAL_ARITH_TAC
              >> PROVE_TAC [REAL_SUM_IMAGE_POS],
              (* goal 2 (of 2) *)
              Know `!(x:real) y. 0 <= x /\ 0 <= y /\ (x + y = 0) ==> ((x = 0) /\ (y = 0))`
              >- REAL_ARITH_TAC
              >> Q.PAT_X_ASSUM `!g. (SIGMA g s' = 0) /\ (!x. x IN s' ==> 0 <= g x /\ g x <= 1) ==>
                                !x. x IN s' ==> (g x = 0)`
                (MP_TAC o Q.SPEC `g'`)
              >> PROVE_TAC [REAL_SUM_IMAGE_POS] ])
        >> Know `!x:real. (1 + x = 1) = (x = 0)` >- REAL_ARITH_TAC
        >> STRIP_TAC >> FULL_SIMP_TAC real_ss []
        >> POP_ASSUM (K ALL_TAC)
        >> (ASSUME_TAC o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_IN_IF
        >> POP_ORW
        >> DISCH_TAC
        >> POP_ASSUM (ASSUME_TAC o UNDISCH_ALL o (REWRITE_RULE [GSYM AND_IMP_INTRO]) o
                      (Q.SPEC `g`) o UNDISCH o (Q.SPEC `s`))
        >> `(\x. (if x IN s then (\x. g x * g' x) x else 0)) = (\x. 0)`
                by RW_TAC real_ss [FUN_EQ_THM]
        >> POP_ORW
        >> `(\x. (if x IN s then (\x. g x * f (g' x)) x else 0)) = (\x. 0)`
                by RW_TAC real_ss [FUN_EQ_THM]
        >> POP_ORW
        >> Suff `SIGMA (\x. 0) s = 0` >- RW_TAC real_ss []
        >> (MP_TAC o Q.SPECL [`(\x. 0)`, `0`] o
                UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_FINITE_CONST
        >> RW_TAC real_ss [])

   >> Suff `(SIGMA (\x. g x * g' x) s = (1 - g e) * SIGMA (\x. (g x / (1 - g e)) * g' x) s) /\
            (SIGMA (\x. g x * f(g' x)) s = (1 - g e) * SIGMA (\x. (g x / (1 - g e)) * f(g' x)) s)`
   >- (RW_TAC std_ss [] >> FULL_SIMP_TAC std_ss [convex_fn, GSPECIFICATION]
       >> Q.PAT_X_ASSUM `!f' g'' g'''.
        (SIGMA g'' s = 1) /\
        (!x. x IN s ==> 0 <= g'' x /\ g'' x <= 1) /\
        (!x y t.
           0 <= t /\ t <= 1 ==>
           f' (t * x + (1 - t) * y) <= t * f' x + (1 - t) * f' y) ==>
        f' (SIGMA (\x. g'' x * g''' x) s) <=
        SIGMA (\x. g'' x * f' (g''' x)) s` (MP_TAC o Q.SPECL [`f`, `(\x. g x / (1 - g e))`, `g'`])
       >> RW_TAC std_ss []
       >> Q.PAT_X_ASSUM `!x y t. P`
                (MP_TAC o Q.SPECL [`g' e`, `SIGMA (\x. g x / (1 - g e) * g' x) s`, `g e`])
       >> RW_TAC std_ss []
       >> MATCH_MP_TAC REAL_LE_TRANS
       >> Q.EXISTS_TAC `g e * f (g' e) + (1 - g e) * f (SIGMA (\x. g x / (1 - g e) * g' x) s)`
       >> RW_TAC real_ss [REAL_LE_LADD]
       >> Cases_on `g e = 1` >- RW_TAC real_ss []
       >> Know `0 < 1 - g e`
       >- (Q.PAT_X_ASSUM `g e <= 1` MP_TAC >> Q.PAT_X_ASSUM `~ (g e = 1)` MP_TAC >> REAL_ARITH_TAC)
       >> STRIP_TAC
       >> Suff `f (SIGMA (\x. g x / (1 - g e) * g' x) s) <=
                SIGMA (\x. g x / (1 - g e) * f (g' x)) s`
       >- PROVE_TAC [REAL_LE_LMUL]
       >> Q.PAT_X_ASSUM `(SIGMA (\x. g x / (1 - g e)) s = 1) /\
                        (!x. x IN s ==> 0 <= g x / (1 - g e) /\ g x / (1 - g e) <= 1) ==>
                        f (SIGMA (\x. g x / (1 - g e) * g' x) s) <=
                        SIGMA (\x. g x / (1 - g e) * f (g' x)) s` MATCH_MP_TAC
       >> CONJ_TAC
       >- ((MP_TAC o Q.SPECL [`g`, `inv (1- g e)`] o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_CMUL
           >> RW_TAC real_ss [real_div] >> ASM_REWRITE_TAC [Once REAL_MUL_COMM]
           >> RW_TAC std_ss [Once REAL_MUL_COMM, GSYM real_div]
           >> Suff `SIGMA g s = 1 * (1 - g e)`
           >- PROVE_TAC [REAL_EQ_LDIV_EQ]
           >> Q.PAT_X_ASSUM `g e + SIGMA g s = 1` MP_TAC
           >> REAL_ARITH_TAC)
       >> RW_TAC std_ss [] >- PROVE_TAC [REAL_LE_DIV, REAL_LT_IMP_LE]
       >> Suff `g x <= 1 * (1 - g e)` >- PROVE_TAC [REAL_LE_LDIV_EQ]
       >> Suff `g e + g x <= 1` >- REAL_ARITH_TAC
       >> Q.PAT_X_ASSUM `g e + SIGMA g s = 1` (fn thm => ONCE_REWRITE_TAC [GSYM thm])
       >> MATCH_MP_TAC REAL_LE_ADD2
       >> PROVE_TAC [REAL_LE_REFL, REAL_SUM_IMAGE_POS_MEM_LE])
   >> Know `~(1-g e = 0)` >- (POP_ASSUM MP_TAC >> REAL_ARITH_TAC)
   >> RW_TAC real_ss [(REWRITE_RULE [Once EQ_SYM_EQ] o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_CMUL,
                     REAL_MUL_ASSOC, REAL_DIV_LMUL]);

val jensen_concave_SIGMA = store_thm
  ("jensen_concave_SIGMA",
   ``!s. FINITE s ==>
         !f g g'. (SIGMA g s = 1) /\
                  (!x. x IN s ==> 0 <= g x /\ g x <= 1) /\
                  f IN concave_fn ==>
                         SIGMA (\x. g x * f (g' x)) s <= f (SIGMA (\x. g x * g' x) s)``,
   REPEAT STRIP_TAC
   >> ONCE_REWRITE_TAC [GSYM REAL_LE_NEG2]
   >> RW_TAC std_ss [(REWRITE_RULE [Once EQ_SYM_EQ]) REAL_SUM_IMAGE_NEG]
   >> Suff `(\x. ~ f x) (SIGMA (\x. g x * g' x) s) <=
            SIGMA (\x. g x * (\x. ~ f x) (g' x)) s`
   >- RW_TAC real_ss []
   >> Q.ABBREV_TAC `f' = (\x. ~f x)`
   >> (MATCH_MP_TAC o UNDISCH o Q.SPEC `s`) jensen_convex_SIGMA
   >> Q.UNABBREV_TAC `f'`
   >> FULL_SIMP_TAC std_ss [concave_fn, GSPECIFICATION]);

val jensen_pos_convex_SIGMA = store_thm
  ("jensen_pos_convex_SIGMA",
   ``!s. FINITE s ==>
         !f g g'. (SIGMA g s = 1) /\
                  (!x. x IN s ==> 0 <= g x /\ g x <= 1) /\
                  (!x. x IN s ==> (0 < g x ==> 0 < g' x)) /\
                  f IN pos_convex_fn ==>
                        f (SIGMA (\x. g x * g' x) s) <= SIGMA (\x. g x * f (g' x)) s``,
   Suff `!s. FINITE s ==>
             (\s. !f g g'. (SIGMA g s = 1) /\
                  (!x. x IN s ==> 0 <= g x /\ g x <= 1) /\
                  (!x. x IN s ==> (0 < g x ==> 0 < g' x)) /\
                  f IN pos_convex_fn ==>
                        f (SIGMA (\x. g x * g' x) s) <= SIGMA (\x. g x * f (g' x)) s) s`
   >- RW_TAC std_ss []
   >> MATCH_MP_TAC FINITE_INDUCT
   >> RW_TAC real_ss [REAL_SUM_IMAGE_THM, DELETE_NON_ELEMENT, IN_INSERT, DISJ_IMP_THM, FORALL_AND_THM]
   >> Cases_on `g e = 0` >- FULL_SIMP_TAC real_ss []
   >> Cases_on `g e = 1`
   >- ( FULL_SIMP_TAC real_ss []
        >> Know `!s. FINITE s ==>
                (\s. !g. (SIGMA g s = 0) /\ (!x. x IN s ==> 0 <= g x /\ g x <= 1) ==>
                            (!x. x IN s ==> (g x = 0))) s`
        >- (MATCH_MP_TAC FINITE_INDUCT
            >> RW_TAC real_ss [REAL_SUM_IMAGE_THM, DELETE_NON_ELEMENT, IN_INSERT, DISJ_IMP_THM,
                               FORALL_AND_THM, NOT_IN_EMPTY] (* 2 sub-goals *)
            >- (Know `!(x:real) y. 0 <= x /\ 0 <= y /\ (x + y = 0) ==> ((x = 0) /\ (y = 0))`
                >- REAL_ARITH_TAC
                >> PROVE_TAC [REAL_SUM_IMAGE_POS])
            >>
            ( Know `!(x:real) y. 0 <= x /\ 0 <= y /\ (x + y = 0) ==> ((x = 0) /\ (y = 0))`
              >- REAL_ARITH_TAC
              >> Q.PAT_X_ASSUM `!g. (SIGMA g s' = 0) /\ (!x. x IN s' ==> 0 <= g x /\ g x <= 1) ==>
                                !x. x IN s' ==> (g x = 0)`
                (MP_TAC o Q.SPEC `g''`)
              >> PROVE_TAC [REAL_SUM_IMAGE_POS] ))
        >> Know `!x:real. (1 + x = 1) = (x = 0)` >- REAL_ARITH_TAC
        >> STRIP_TAC >> FULL_SIMP_TAC real_ss []
        >> POP_ASSUM (K ALL_TAC)
        >> (ASSUME_TAC o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_IN_IF
        >> POP_ORW
        >> DISCH_TAC
        >> POP_ASSUM (ASSUME_TAC o UNDISCH_ALL o REWRITE_RULE [GSYM AND_IMP_INTRO] o
                      (Q.SPEC `g`) o UNDISCH o (Q.SPEC `s`))
        >> `(\x. (if x IN s then (\x. g x * g' x) x else 0)) = (\x. 0)`
                by RW_TAC real_ss [FUN_EQ_THM]
        >> POP_ORW
        >> `(\x. (if x IN s then (\x. g x * f (g' x)) x else 0)) = (\x. 0)`
                by RW_TAC real_ss [FUN_EQ_THM]
        >> POP_ORW
        >> Suff `SIGMA (\x. 0) s = 0` >- RW_TAC real_ss []
        >> (MP_TAC o Q.SPECL [`(\x. 0)`, `0`] o
                UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_FINITE_CONST
        >> RW_TAC real_ss [])
   >> Suff `(SIGMA (\x. g x * g' x) s = (1 - g e) * SIGMA (\x. (g x / (1 - g e)) * g' x) s) /\
            (SIGMA (\x. g x * f(g' x)) s = (1 - g e) * SIGMA (\x. (g x / (1 - g e)) * f(g' x)) s)`
   >- (RW_TAC std_ss [] >> FULL_SIMP_TAC std_ss [pos_convex_fn, GSPECIFICATION]
       >> Q.PAT_X_ASSUM `!f' g'' g'''.
        (SIGMA g'' s = 1) /\
        (!x. x IN s ==> 0 <= g'' x /\ g'' x <= 1) /\
        (!x. x IN s ==> 0 < g'' x ==> 0 < g''' x) /\
        (!x y t.
           0 < x /\ 0 < y /\ 0 <= t /\ t <= 1 ==>
           f' (t * x + (1 - t) * y) <= t * f' x + (1 - t) * f' y) ==>
        f' (SIGMA (\x. g'' x * g''' x) s) <=
        SIGMA (\x. g'' x * f' (g''' x)) s` (MP_TAC o Q.SPECL [`f`, `(\x. g x / (1 - g e))`, `g'`])
       >> RW_TAC std_ss []
       >> Know `0 < 1 - g e`
       >- (Q.PAT_X_ASSUM `g e <= 1` MP_TAC >> Q.PAT_X_ASSUM `~ (g e = 1)` MP_TAC >> REAL_ARITH_TAC)
       >> STRIP_TAC
       >> Know `SIGMA (\x. g x / (1 - g e)) s = 1`
       >- ((MP_TAC o Q.SPECL [`g`, `inv (1- g e)`] o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_CMUL
           >> RW_TAC real_ss [real_div] >> ASM_REWRITE_TAC [Once REAL_MUL_COMM]
           >> RW_TAC std_ss [Once REAL_MUL_COMM, GSYM real_div]
           >> Suff `SIGMA g s = 1 * (1 - g e)`
           >- PROVE_TAC [REAL_EQ_LDIV_EQ]
           >> Q.PAT_X_ASSUM `g e + SIGMA g s = 1` MP_TAC
           >> REAL_ARITH_TAC)
       >> STRIP_TAC
       >> FULL_SIMP_TAC std_ss []
       >> Cases_on `s = {}` >- FULL_SIMP_TAC real_ss [REAL_SUM_IMAGE_THM]
       >> Know `0 < SIGMA (\x. g x / (1 - g e) * g' x) s`
       >- ( RW_TAC std_ss [REAL_LT_LE]
            >- ((MATCH_MP_TAC o UNDISCH o REWRITE_RULE [GSYM AND_IMP_INTRO] o
                        Q.SPECL [`(\x. g x / (1 - g e) * g' x)`,`s`]) REAL_SUM_IMAGE_POS
                >> RW_TAC real_ss [] >> Cases_on `g x = 0` >- RW_TAC real_ss []
                >> MATCH_MP_TAC REAL_LE_MUL
                >> reverse CONJ_TAC >- PROVE_TAC [REAL_LT_IMP_LE, REAL_LT_LE]
                >> RW_TAC real_ss [] >> MATCH_MP_TAC REAL_LE_DIV
                >> RW_TAC real_ss [] >> PROVE_TAC [REAL_LT_IMP_LE])
            >> Q.PAT_X_ASSUM `SIGMA (\x. g x * g' x) s =
                                (1 - g e) * SIGMA (\x. g x / (1 - g e) * g' x) s`
                (MP_TAC o REWRITE_RULE [Once REAL_MUL_COMM] o GSYM)
            >> RW_TAC std_ss [GSYM REAL_EQ_RDIV_EQ]
            >> RW_TAC std_ss [real_div, REAL_ENTIRE, REAL_INV_EQ_0, REAL_LT_IMP_NE]
            >> SPOSE_NOT_THEN STRIP_ASSUME_TAC
            >> Know `!s. FINITE s ==>
                    (\s. !g g'. (!x. x IN s ==> 0 <= g x) /\ (!x. x IN s ==> 0 < g x ==> 0 < g' x) /\
                                (SIGMA (\x. g x * g' x) s = 0) ==>
                                (!x. x IN s ==> (g x = 0))) s`
            >- ( REPEAT (POP_ASSUM (K ALL_TAC))
                 >> MATCH_MP_TAC FINITE_INDUCT
                 >> RW_TAC std_ss [REAL_SUM_IMAGE_THM, NOT_IN_EMPTY, DELETE_NON_ELEMENT,
                                   IN_INSERT, Once DISJ_IMP_THM, Once FORALL_AND_THM]
                 >- ( SPOSE_NOT_THEN STRIP_ASSUME_TAC
                      >> Cases_on `SIGMA (\x. g x * g' x) s = 0`
                      >- ( FULL_SIMP_TAC real_ss [REAL_ENTIRE] \\
                           PROVE_TAC [REAL_LT_IMP_NE, REAL_LT_LE] )
                      >> `0 < g e * g' e + SIGMA (\x. g x * g' x) s`
                                by (MATCH_MP_TAC REAL_LT_ADD
                                    >> CONJ_TAC
                                    >- (MATCH_MP_TAC REAL_LT_MUL >> PROVE_TAC [REAL_LT_LE])
                                    >> RW_TAC std_ss [REAL_LT_LE]
                                    >> (MATCH_MP_TAC o UNDISCH o REWRITE_RULE [GSYM AND_IMP_INTRO] o
                                        Q.SPECL [`(\x. g x * g' x)`,`s`]) REAL_SUM_IMAGE_POS
                                    >> RW_TAC std_ss []
                                    >> Cases_on `g x = 0` >- RW_TAC real_ss []
                                    >> PROVE_TAC [REAL_LE_MUL, REAL_LT_IMP_LE, REAL_LT_LE])
                      >> PROVE_TAC [REAL_LT_IMP_NE] )
                 >> Cases_on `SIGMA (\x. g x * g' x) s = 0`
                 >- METIS_TAC []
                 >> Cases_on `g e = 0`
                 >- FULL_SIMP_TAC real_ss []
                 >> `0 < g e * g' e + SIGMA (\x. g x * g' x) s`
                        by (MATCH_MP_TAC REAL_LT_ADD
                            >> CONJ_TAC
                            >- (MATCH_MP_TAC REAL_LT_MUL >> METIS_TAC [REAL_LT_LE])
                            >> RW_TAC std_ss [REAL_LT_LE]
                            >> (MATCH_MP_TAC o UNDISCH o REWRITE_RULE [GSYM AND_IMP_INTRO] o
                                Q.SPECL [`(\x. g x * g' x)`,`s`]) REAL_SUM_IMAGE_POS
                            >> RW_TAC std_ss []
                            >> Cases_on `g x' = 0` >- RW_TAC real_ss []
                            >> PROVE_TAC [REAL_LE_MUL, REAL_LT_IMP_LE, REAL_LT_LE])
                 >> METIS_TAC [REAL_LT_IMP_NE] )
            >> DISCH_TAC
            >> POP_ASSUM (ASSUME_TAC o UNDISCH o Q.SPEC `s`)
            >> FULL_SIMP_TAC std_ss [IMP_CONJ_THM, Once FORALL_AND_THM]
            >> POP_ASSUM (ASSUME_TAC o UNDISCH_ALL o REWRITE_RULE [GSYM AND_IMP_INTRO] o
                          (Q.SPECL [`g`,`g'`]))
            >> (ASSUME_TAC o Q.SPECL [`(\x. if x IN s then g x else 0)`, `0`] o
                UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_FINITE_CONST
            >> `SIGMA (\x. (if x IN s then g x else 0)) s = SIGMA g s`
                  by METIS_TAC [GSYM REAL_SUM_IMAGE_IN_IF]
            >> FULL_SIMP_TAC real_ss [] )
       >> DISCH_TAC
       >> Q.PAT_X_ASSUM `!x y t. P`
              (MP_TAC o Q.SPECL [`g' e`, `SIGMA (\x. g x / (1 - g e) * g' x) s`, `g e`])
       >> Know `0 < g' e` >- METIS_TAC [REAL_LT_LE]
       >> RW_TAC std_ss []
       >> MATCH_MP_TAC REAL_LE_TRANS
       >> Q.EXISTS_TAC `g e * f (g' e) + (1 - g e) * f (SIGMA (\x. g x / (1 - g e) * g' x) s)`
       >> RW_TAC real_ss [REAL_LE_LADD]
       >> Suff `f (SIGMA (\x. g x / (1 - g e) * g' x) s) <=
                SIGMA (\x. g x / (1 - g e) * f (g' x)) s`
       >- PROVE_TAC [REAL_LE_LMUL]
       >> Q.PAT_X_ASSUM `(!x. x IN s ==> 0 <= g x / (1 - g e) /\ g x / (1 - g e) <= 1) /\
       (!x. x IN s ==> 0 < g x / (1 - g e) ==> 0 < g' x) ==>
       f (SIGMA (\x. g x / (1 - g e) * g' x) s) <=
       SIGMA (\x. g x / (1 - g e) * f (g' x)) s` MATCH_MP_TAC
       >> RW_TAC std_ss [] (* 3 sub-goals *)
       >| [PROVE_TAC [REAL_LE_DIV, REAL_LT_IMP_LE],
           Suff `g x <= 1 * (1 - g e)` >- PROVE_TAC [REAL_LE_LDIV_EQ]
           >> Suff `g e + g x <= 1` >- REAL_ARITH_TAC
           >> Q.PAT_X_ASSUM `g e + SIGMA g s = 1` (fn thm => ONCE_REWRITE_TAC [GSYM thm])
           >> MATCH_MP_TAC REAL_LE_ADD2
           >> PROVE_TAC [REAL_LE_REFL, REAL_SUM_IMAGE_POS_MEM_LE],
           Cases_on `g x = 0` >- FULL_SIMP_TAC real_ss []
           >> PROVE_TAC [REAL_LT_LE] ])
   >> Know `~(1-g e = 0)` >- (POP_ASSUM MP_TAC >> REAL_ARITH_TAC)
   >> RW_TAC real_ss [(REWRITE_RULE [Once EQ_SYM_EQ] o UNDISCH o Q.SPEC `s`) REAL_SUM_IMAGE_CMUL,
                     REAL_MUL_ASSOC, REAL_DIV_LMUL]);

val jensen_pos_concave_SIGMA = store_thm
  ("jensen_pos_concave_SIGMA",
   ``!s. FINITE s ==>
         !f g g'. (SIGMA g s = 1) /\
                  (!x. x IN s ==> 0 <= g x /\ g x <= 1) /\
                  (!x. x IN s ==> (0 < g x ==> 0 < g' x)) /\
                  f IN pos_concave_fn ==>
                        SIGMA (\x. g x * f (g' x)) s <= f (SIGMA (\x. g x * g' x) s)``,
   REPEAT STRIP_TAC
   >> ONCE_REWRITE_TAC [GSYM REAL_LE_NEG2]
   >> RW_TAC std_ss [(REWRITE_RULE [Once EQ_SYM_EQ]) REAL_SUM_IMAGE_NEG]
   >> Suff `(\x. ~ f x) (SIGMA (\x. g x * g' x) s) <=
            SIGMA (\x. g x * (\x. ~ f x) (g' x)) s`
   >- RW_TAC real_ss []
   >> Q.ABBREV_TAC `f' = (\x. ~f x)`
   >> (MATCH_MP_TAC o UNDISCH o Q.SPEC `s`) jensen_pos_convex_SIGMA
   >> Q.UNABBREV_TAC `f'`
   >> FULL_SIMP_TAC std_ss [pos_concave_fn, GSPECIFICATION]);

(* ------------------------------------------------------------------------- *)
(* Some convexity-derived inequalities including AGM and Young's inequality. *)
(* Ported from hol-light (AGM stands for "arithmetic and geometric means")   *)
(* ------------------------------------------------------------------------- *)

(* moved here from iterateTheory (which does not depend on transcTheory now) *)
Theorem LN_PRODUCT :
    !f s. FINITE s /\ (!x. x IN s ==> &0 < f x) ==>
          ln (product s f) = sum s (\x. ln (f x))
Proof
    rpt STRIP_TAC
 >> NTAC 2 (POP_ASSUM MP_TAC)
 >> Q.SPEC_TAC (‘s’, ‘s’)
 >> HO_MATCH_MP_TAC FINITE_INDUCT
 >> rw [PRODUCT_CLAUSES, SUM_CLAUSES, LN_1]
 >> ‘0 < f e’ by PROVE_TAC []
 >> ‘0 < product s f’ by (MATCH_MP_TAC PRODUCT_POS_LT >> rw [])
 >> rw [LN_MUL]
QED

(* moved here from iterateTheory (which does not depend on transcTheory now)

   NOTE: added ‘n <> 0 /\ (!x. x IN s ==> &0 <= f x)’ to hol-light's statements
 *)
Theorem ROOT_PRODUCT :
    !n f s. FINITE s /\ n <> 0 /\ (!x. x IN s ==> &0 <= f x)
        ==> root n (product s f) = product s (\i. root n (f i))
Proof
    rpt STRIP_TAC
 >> Cases_on ‘n’ >- fs []
 >> rename1 ‘SUC n <> 0’
 >> POP_ASSUM MP_TAC
 >> Q.PAT_X_ASSUM ‘FINITE s’ MP_TAC
 >> Q.SPEC_TAC (‘s’, ‘s’)
 >> HO_MATCH_MP_TAC FINITE_INDUCT
 >> rw [PRODUCT_CLAUSES, ROOT_1]
 >> ‘0 <= f e’ by PROVE_TAC []
 >> ‘0 <= product s f’ by (MATCH_MP_TAC PRODUCT_POS_LE >> rw [])
 >> rw [ROOT_MUL]
QED

(* NOTE: changed ‘0 <= x i’ (hol-light) to ‘0 < x i’ *)
Theorem AGM_GEN :
    !a x s. FINITE s /\ sum s a = &1 /\ (!i. i IN s ==> &0 <= a i /\ &0 < x i)
        ==> product s (\i. x i rpow a i) <= sum s (\i. a i * x i)
Proof
    rpt STRIP_TAC
 >> Q.ABBREV_TAC ‘f = \i. x i rpow a i’
 >> Know ‘!n. n IN s ==> 0 < f n’
 >- (rw [Abbr ‘f’] \\
     MATCH_MP_TAC RPOW_POS_LT >> rw [])
 >> DISCH_TAC
 >> Know ‘product s f <= sum s (\i. a i * x i) <=>
          ln (product s f) <= ln (sum s (\i. a i * x i))’
 >- (MATCH_MP_TAC (GSYM LN_MONO_LE) >> CONJ_TAC >|
     [ (* goal 1 (of 2) *)
       MATCH_MP_TAC PRODUCT_POS_LT >> simp [],
       (* goal 2 (of 2) *)
       MATCH_MP_TAC SUM_POS_LT >> simp [] \\
       CONJ_TAC >- (Q.X_GEN_TAC ‘n’ >> DISCH_TAC \\
                    MATCH_MP_TAC REAL_LE_MUL >> rw [] \\
                    MATCH_MP_TAC REAL_LT_IMP_LE >> rw []) \\
       Cases_on ‘?i. i IN s /\ 0 < a i’
       >- (POP_ASSUM STRIP_ASSUME_TAC >> Q.EXISTS_TAC ‘i’ >> art [] \\
           MATCH_MP_TAC REAL_LT_MUL >> rw []) \\
       FULL_SIMP_TAC std_ss [GSYM IMP_DISJ_THM, GSYM real_lte] \\
       Know ‘sum s a <= &CARD s * 0’
       >- (MATCH_MP_TAC SUM_BOUND >> rw []) >> rw [] ])
 >> Rewr'
 >> Know ‘ln (product s f) = sum s (\x. ln (f x))’
 >- (MATCH_MP_TAC LN_PRODUCT >> rw [])
 >> Rewr'
 >> Know ‘!g. sum s g = SIGMA g s’
 >- (Q.X_GEN_TAC ‘g’ \\
     MATCH_MP_TAC (GSYM REAL_SUM_IMAGE_sum) >> art [])
 >> DISCH_THEN (FULL_SIMP_TAC std_ss o wrap)
 >> simp [Abbr ‘f’]
 >> Know ‘SIGMA (\x'. ln (x x' rpow a x')) s = SIGMA (\i. a i * ln (x i)) s’
 >- (MATCH_MP_TAC REAL_SUM_IMAGE_EQ >> art [] \\
     Q.X_GEN_TAC ‘i’ >> rw [] \\
     MATCH_MP_TAC LN_RPOW >> rw [])
 >> Rewr'
 >> MP_TAC (Q.SPECL [‘ln’, ‘a’, ‘x’]
                    (MATCH_MP jensen_pos_concave_SIGMA (ASSUME “FINITE s”)))
 >> rw [pos_concave_ln]
 >> POP_ASSUM MATCH_MP_TAC
 >> MATCH_MP_TAC SUM_POS_BOUND >> rw []
 >> Suff ‘sum s a = SIGMA a s’ >- rw [REAL_LE_REFL]
 >> MATCH_MP_TAC (GSYM REAL_SUM_IMAGE_sum) >> art []
QED

(* NOTE: changed ‘0 <= x i’ (hol-light) to ‘0 < x i’ *)
Theorem AGM_RPOW :
    !s x n. s HAS_SIZE n /\ ~(n = 0) /\ (!i. i IN s ==> &0 < x(i))
        ==> product s (\i. x(i) rpow (&1 / &n)) <= sum s (\i. x(i) / &n)
Proof
    RW_TAC std_ss [HAS_SIZE]
 >> MP_TAC (Q.SPECL [‘\i. &1 / &CARD (s :'a set)’, ‘x’, ‘s’] AGM_GEN)
 >> rw [SUM_CONST, GSYM real_div]
QED

Theorem AGM_ROOT :
    !s x n. s HAS_SIZE n /\ ~(n = 0) /\ (!i. i IN s ==> &0 <= x(i))
        ==> root n (product s x) <= sum s x / &n
Proof
    RW_TAC std_ss [HAS_SIZE]
 >> Cases_on ‘!i. i IN s ==> &0 < x(i)’
 >- (RW_TAC std_ss [ROOT_PRODUCT, real_div] \\
     Know ‘product s (\i. root (CARD s) (x i)) =
           product s (\i. (x i) rpow (inv &CARD s))’
     >- (MATCH_MP_TAC PRODUCT_EQ \\
         Q.X_GEN_TAC ‘i’ >> rw [REAL_ROOT_RPOW]) >> Rewr' \\
     REWRITE_TAC [GSYM SUM_RMUL] \\
     REWRITE_TAC [GSYM real_div, REAL_INV_1OVER] \\
     MATCH_MP_TAC AGM_RPOW >> rw [HAS_SIZE])
 (* extra work to support ‘!i. i IN s ==> 0 <= x i’ *)
 >> FULL_SIMP_TAC std_ss [real_lt]
 >> ‘x i = 0’ by PROVE_TAC [REAL_LE_ANTISYM]
 >> Know ‘product s x = 0’
 >- (REWRITE_TAC [MATCH_MP PRODUCT_EQ_0 (ASSUME “FINITE s”)] \\
     Q.EXISTS_TAC ‘i’ >> art [])
 >> Rewr'
 >> Q.ABBREV_TAC ‘n = CARD s’
 >> Cases_on ‘n’ >- fs []
 >> rw [ROOT_0]
 >> MATCH_MP_TAC SUM_POS_LE >> rw []
QED

Theorem AGM_SQRT :
    !x y. &0 <= x /\ &0 <= y ==> sqrt(x * y) <= (x + y) / &2
Proof
    rpt STRIP_TAC
 >> MP_TAC (ISPECL [“{0; (1:num)}”,
                    “\(n :num). if n = 0 then (x:real) else (y:real)”,
                    “(2:num)”] AGM_ROOT)
 >> ‘FINITE {0; (1:num)}’ by PROVE_TAC [FINITE_INSERT, FINITE_SING]
 >> simp [SUM_CLAUSES, PRODUCT_CLAUSES, sqrt]
 >> DISCH_THEN MATCH_MP_TAC
 >> rw [HAS_SIZE]
QED

Theorem AGM :
    !s x n. s HAS_SIZE n /\ ~(n = 0) /\ (!i. i IN s ==> &0 <= x(i))
        ==> product s x <= (sum s x / &n) pow n
Proof
    rpt STRIP_TAC
 >> Cases_on ‘n’ >- fs []
 >> rename1 ‘SUC n <> 0’
 >> Know ‘0 <= sum s x / &SUC n’
 >- (MATCH_MP_TAC REAL_LE_DIV >> rw [] \\
     MATCH_MP_TAC SUM_POS_LE >> rw [])
 >> DISCH_TAC
 >> Know ‘product s x <= (sum s x / &SUC n) pow (SUC n) <=>
          root (SUC n) (product s x) <=
          root (SUC n) ((sum s x / &(SUC n)) pow (SUC n))’
 >- (MATCH_MP_TAC (GSYM ROOT_MONO_LE_EQ) >> rw [] \\
     MATCH_MP_TAC PRODUCT_POS_LE >> fs [HAS_SIZE])
 >> Rewr'
 >> RW_TAC std_ss [POW_ROOT_POS]
 >> MATCH_MP_TAC AGM_ROOT >> rw []
QED

(* NOTE: changed ‘0 <= x /\ 0 <= y’ (hol-light) to ‘0 < x /\ 0 < y’ *)
Theorem AGM_2 :
    !x y u v. &0 < x /\ &0 < y /\ &0 <= u /\ &0 <= v /\ u + v = &1
          ==> x rpow u * y rpow v <= u * x + v * y
Proof
    rpt STRIP_TAC
 >> qspecl_then [‘\i. if i = 0n then u else v’, ‘\i. if i = 0 then x else y’,
                 ‘{0..SUC 0}’] MP_TAC AGM_GEN
 >> simp [SUM_CLAUSES_NUMSEG, PRODUCT_CLAUSES_NUMSEG, FINITE_NUMSEG]
 >> DISCH_THEN MATCH_MP_TAC
 >> rw []
QED

(* NOTE: changed ‘0 <= a /\ 0 <= b’ (hol-light) to ‘0 < a /\ 0 < b’ *)
Theorem YOUNG_INEQUALITY :
    !a b p q. &0 < a /\ &0 < b /\ &0 < p /\ &0 < q /\ inv(p) + inv(q) = &1
          ==> a * b <= a rpow p / p + b rpow q / q
Proof
    rpt STRIP_TAC
 >> ‘p <> 0 /\ q <> 0’ by PROVE_TAC [REAL_LT_IMP_NE]
 >> ‘0 <= p /\ 0 <= q’ by PROVE_TAC [REAL_LT_IMP_LE]
 >> MP_TAC (Q.SPECL [`a rpow p`, `b rpow q`, `inv p:real`, `inv q:real`] AGM_2)
 >> rw [RPOW_RPOW, RPOW_1, RPOW_POS_LT, real_div]
QED

val _ = export_theory ();

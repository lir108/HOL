(* ------------------------------------------------------------------------- *)
(* Useful Theorems, some are taken from various theories by Hurd and Coble   *)
(* Authors: Tarek Mhamdi, Osman Hasan, Sofiene Tahar                         *)
(* HVG Group, Concordia University, Montreal                                 *)
(*                                                                           *)
(* Extended by Chun Tian (2019-2020)                                         *)
(* Fondazione Bruno Kessler and University of Trento, Italy                  *)
(* ------------------------------------------------------------------------- *)

open HolKernel Parse boolLib bossLib;

open metisLib pairTheory combinTheory pred_setTheory pred_setLib jrhUtils
     arithmeticTheory numLib numpairTheory hurdUtils whileTheory;

open realTheory realLib transcTheory seqTheory real_sigmaTheory RealArith;

open topologyTheory iterateTheory;

val _ = new_theory "util_prob";

fun METIS ths tm = prove(tm, METIS_TAC ths);

(* ------------------------------------------------------------------------- *)

val _ = set_fixity "->" (Infixr 250);
val _ = overload_on ("->",
      ``FUNSET  :'a set -> 'b set -> ('a -> 'b) set``);

val _ = overload_on ("-->", (* "Pi" in Isabelle's FuncSet.thy *)
      ``DFUNSET :'a set -> ('a -> 'b set) -> ('a -> 'b) set``);

(* RIGHTWARDS ARROW *)
val _ = Unicode.unicode_version {u = UTF8.chr 0x2192, tmnm = "->"};

(* LONG RIGHTWARDS ARROW *)
val _ = Unicode.unicode_version {u = UTF8.chr 0x27F6, tmnm = "-->"};

val _ = TeX_notation {hol = "->",            TeX = ("\\HOLTokenMap{}", 1)};
val _ = TeX_notation {hol = UTF8.chr 0x2192, TeX = ("\\HOLTokenMap{}", 1)};
val _ = TeX_notation {hol = "-->",           TeX = ("\\HOLTokenLongmap{}", 1)};
val _ = TeX_notation {hol = UTF8.chr 0x27F6, TeX = ("\\HOLTokenLongmap{}", 1)};

Theorem PAIRED_BETA_THM :
    !f z. UNCURRY f z = f (FST z) (SND z)
Proof
    STRIP_TAC >> Cases >> RW_TAC std_ss []
QED

Theorem IN_o :
    !x f s. x IN (s o f) <=> f x IN s
Proof
    RW_TAC std_ss [SPECIFICATION, o_THM]
QED

val prod_sets_def = Define `
    prod_sets a b = {s CROSS t | s IN a /\ t IN b}`;

Theorem IN_PROD_SETS[simp] :
    !s a b. s IN prod_sets a b <=> ?t u. (s = t CROSS u) /\ t IN a /\ u IN b
Proof
    RW_TAC std_ss [prod_sets_def, GSPECIFICATION, UNCURRY]
 >> EQ_TAC >- PROVE_TAC []
 >> RW_TAC std_ss []
 >> Q.EXISTS_TAC `(t,u)`
 >> RW_TAC std_ss []
QED

(* ------------------------------------------------------------------------- *)
(* ----- Defining real-valued power, log, and log base 2 functions --------- *)
(* ------------------------------------------------------------------------- *)

val _ = set_fixity "powr" (Infixr 700);
val _ = overload_on ("powr", ``$rpow``); (* transcTheory *)

val logr_def = Define `logr a x = ln x / ln a`;
val lg_def   = Define `lg x = logr 2 x`;

val lg_1 = store_thm
  ("lg_1", ``lg 1 = 0``,
   RW_TAC real_ss [lg_def, logr_def, LN_1]);

val logr_1 = store_thm
  ("logr_1", ``!b. logr b 1 = 0``,
   RW_TAC real_ss [logr_def, LN_1]);

val lg_nonzero = store_thm
  ("lg_nonzero", ``!x. x <> 0 /\ 0 <= x ==> (lg x <> 0 <=> x <> 1)``,
    RW_TAC std_ss [REAL_ARITH ``x <> 0 /\ 0 <= x <=> 0 < x``]
 >> RW_TAC std_ss [GSYM lg_1]
 >> RW_TAC std_ss [lg_def, logr_def, real_div, REAL_EQ_RMUL, REAL_INV_EQ_0]
 >> (MP_TAC o Q.SPECL [`2`, `1`]) LN_INJ >> RW_TAC real_ss [LN_1]
 >> RW_TAC std_ss [GSYM LN_1]
 >> MATCH_MP_TAC LN_INJ
 >> RW_TAC real_ss []);

val lg_mul = store_thm
  ("lg_mul", ``!x y. 0 < x /\ 0 < y ==> (lg (x * y) = lg x + lg y)``,
   RW_TAC real_ss [lg_def, logr_def, LN_MUL]);

val logr_mul = store_thm
  ("logr_mul", ``!b x y. 0 < x /\ 0 < y ==> (logr b (x * y) = logr b x + logr b y)``,
   RW_TAC real_ss [logr_def, LN_MUL]);

val lg_2 = store_thm
  ("lg_2", ``lg 2 = 1``,
   RW_TAC real_ss [lg_def, logr_def]
   >> MATCH_MP_TAC REAL_DIV_REFL
   >> (ASSUME_TAC o Q.SPECL [`1`, `2`]) LN_MONO_LT
   >> FULL_SIMP_TAC real_ss [LN_1]
   >> ONCE_REWRITE_TAC [EQ_SYM_EQ]
   >> MATCH_MP_TAC REAL_LT_IMP_NE
   >> ASM_REWRITE_TAC []);

val lg_inv = store_thm
  ("lg_inv", ``!x. 0 < x ==> (lg (inv x) = ~lg x)``,
   RW_TAC real_ss [lg_def, logr_def, LN_INV, real_div]);

val logr_inv = store_thm
  ("logr_inv", ``!b x. 0 < x ==> (logr b (inv x) = ~ logr b x)``,
   RW_TAC real_ss [logr_def, LN_INV, real_div]);

val logr_div = store_thm
  ("logr_div", ``!b x y. 0 < x /\ 0 < y ==> (logr b (x/y) = logr b x - logr b y)``,
   RW_TAC real_ss [real_div, logr_mul, logr_inv, GSYM real_sub]);

val neg_lg = store_thm
  ("neg_lg", ``!x. 0 < x ==> ((~(lg x)) = lg (inv x))``,
   RW_TAC real_ss [lg_def, logr_def, real_div]
   >> `~(ln x * inv (ln 2)) = (~ ln x) * inv (ln 2)` by REAL_ARITH_TAC
   >> POP_ASSUM (fn thm => ONCE_REWRITE_TAC [thm])
   >> RW_TAC real_ss [REAL_EQ_RMUL]
   >> DISJ2_TAC >> ONCE_REWRITE_TAC [EQ_SYM_EQ] >> MATCH_MP_TAC LN_INV
   >> RW_TAC std_ss []);

val neg_logr = store_thm
  ("neg_logr", ``!b x. 0 < x ==> ((~(logr b x)) = logr b (inv x))``,
   RW_TAC real_ss [logr_def, real_div]
   >> `~(ln x * inv (ln b)) = (~ ln x) * inv (ln b)` by REAL_ARITH_TAC
   >> POP_ASSUM (fn thm => ONCE_REWRITE_TAC [thm])
   >> RW_TAC real_ss [REAL_EQ_RMUL]
   >> DISJ2_TAC >> ONCE_REWRITE_TAC [EQ_SYM_EQ] >> MATCH_MP_TAC LN_INV
   >> RW_TAC std_ss []);

val lg_pow = store_thm
  ("lg_pow", ``!n. lg (2 pow n) = &n``,
   RW_TAC real_ss [lg_def, logr_def, LN_POW]
   >> `~(ln 2 = 0)`
        by (ONCE_REWRITE_TAC [EQ_SYM_EQ] >> MATCH_MP_TAC REAL_LT_IMP_NE
            >> MATCH_MP_TAC REAL_LET_TRANS >> Q.EXISTS_TAC `ln 1`
            >> RW_TAC real_ss [LN_POS, LN_MONO_LT])
   >> RW_TAC real_ss [real_div, GSYM REAL_MUL_ASSOC, REAL_MUL_RINV]);

(* cf. LN_MONO_LT *)
Theorem LOGR_MONO_LT :
    !x :real y b. 0 < x /\ 0 < y /\ 1 < b ==> (logr b x < logr b y <=> x < y)
Proof
    RW_TAC std_ss [logr_def,real_div]
 >> `0 < ln b` by METIS_TAC [REAL_LT_01, LN_1, REAL_LT_TRANS, LN_MONO_LT]
 >> METIS_TAC [REAL_LT_INV_EQ, REAL_LT_RMUL, LN_MONO_LT]
QED

Theorem LOGR_MONO_LE :
    !x:real y b. 0 < x /\ 0 < y /\ 1 < b ==> (logr b x <= logr b y <=> x <= y)
Proof
  RW_TAC std_ss [logr_def,real_div]
  >> `0 < ln b` by METIS_TAC [REAL_LT_01, LN_1, REAL_LT_TRANS, LN_MONO_LT]
  >> METIS_TAC [REAL_LT_INV_EQ, REAL_LE_RMUL, LN_MONO_LE]
QED

Theorem LOGR_MONO_LE_IMP :
    !x:real y b. 0 < x /\ x <= y /\ 1 <= b ==> (logr b x <= logr b y)
Proof
    RW_TAC std_ss [logr_def,real_div]
 >> `0 <= ln b` by METIS_TAC [REAL_LT_01, LN_1, REAL_LTE_TRANS, LN_MONO_LE]
 >> METIS_TAC [REAL_LE_INV_EQ, REAL_LE_RMUL_IMP, LN_MONO_LE, REAL_LTE_TRANS]
QED

(* from extra_realScript.sml of "miller" example *)
val pos_concave_lg = store_thm
  ("pos_concave_lg",
   ``lg IN pos_concave_fn``,
   RW_TAC std_ss [lg_def, logr_def, pos_concave_fn, pos_convex_fn, EXTENSION,
                  NOT_IN_EMPTY, GSPECIFICATION]
   >> `~(ln (t * x + (1 - t) * y) / ln 2) =
       (inv (ln 2))*(~(ln (t * x + (1 - t) * y)))` by (RW_TAC real_ss [real_div] >> REAL_ARITH_TAC)
   >> POP_ASSUM (fn thm => ONCE_REWRITE_TAC [thm])
   >> `t * ~(ln x / ln 2) + (1 - t) * ~(ln y / ln 2) =
       (inv (ln 2)) * (t * ~ ln x + (1-t) * ~ln y)`  by (RW_TAC real_ss [real_div] >> REAL_ARITH_TAC)
   >> POP_ASSUM (fn thm => ONCE_REWRITE_TAC [thm])
   >> MATCH_MP_TAC REAL_LE_LMUL_IMP
   >> CONJ_TAC >- (RW_TAC real_ss [REAL_LE_INV_EQ] >> MATCH_MP_TAC LN_POS >> RW_TAC real_ss [])
   >> MP_TAC pos_concave_ln
   >> RW_TAC std_ss [pos_concave_fn, pos_convex_fn, EXTENSION,
                     NOT_IN_EMPTY, GSPECIFICATION]);

(* from extra_realScript.sml of "miller" example *)
val pos_concave_logr = store_thm
  ("pos_concave_logr",
   ``!b. 1 <= b ==> (logr b) IN pos_concave_fn``,
   RW_TAC std_ss [logr_def, pos_concave_fn, pos_convex_fn, EXTENSION,
                  NOT_IN_EMPTY, GSPECIFICATION]
   >> `~(ln (t * x + (1 - t) * y) / ln b) =
       (inv (ln b))*(~(ln (t * x + (1 - t) * y)))` by (RW_TAC real_ss [real_div] >> REAL_ARITH_TAC)
   >> POP_ASSUM (fn thm => ONCE_REWRITE_TAC [thm])
   >> `t * ~(ln x / ln b) + (1 - t) * ~(ln y / ln b) =
       (inv (ln b)) * (t * ~ ln x + (1-t) * ~ln y)`  by (RW_TAC real_ss [real_div] >> REAL_ARITH_TAC)
   >> POP_ASSUM (fn thm => ONCE_REWRITE_TAC [thm])
   >> MATCH_MP_TAC REAL_LE_LMUL_IMP
   >> CONJ_TAC >- (RW_TAC real_ss [REAL_LE_INV_EQ] >> MATCH_MP_TAC LN_POS >> RW_TAC real_ss [])
   >> MP_TAC pos_concave_ln
   >> RW_TAC std_ss [pos_concave_fn, pos_convex_fn, EXTENSION,
                     NOT_IN_EMPTY, GSPECIFICATION]);

(********************************************************************************************)

val NUM_2D_BIJ = store_thm
  ("NUM_2D_BIJ",
   ``?f.
       BIJ f ((UNIV : num -> bool) CROSS (UNIV : num -> bool))
       (UNIV : num -> bool)``,
   MATCH_MP_TAC BIJ_INJ_SURJ
   >> reverse CONJ_TAC
   >- (Q.EXISTS_TAC `FST`
       >> RW_TAC std_ss [SURJ_DEF, IN_UNIV, IN_CROSS]
       >> Q.EXISTS_TAC `(x, 0)`
       >> RW_TAC std_ss [FST])
   >> Q.EXISTS_TAC `UNCURRY ind_type$NUMPAIR`
   >> RW_TAC std_ss [INJ_DEF, IN_UNIV, IN_CROSS]
   >> Cases_on `x`
   >> Cases_on `y`
   >> POP_ASSUM MP_TAC
   >> RW_TAC std_ss [UNCURRY_DEF, ind_typeTheory.NUMPAIR_INJ]);

val NUM_2D_BIJ_INV = store_thm
  ("NUM_2D_BIJ_INV",
   ``?f.
       BIJ f (UNIV : num -> bool)
       ((UNIV : num -> bool) CROSS (UNIV : num -> bool))``,
   PROVE_TAC [NUM_2D_BIJ, BIJ_SYM]);

val NUM_2D_BIJ_NZ = store_thm
  ("NUM_2D_BIJ_NZ",
   ``?f.
       BIJ f ((UNIV : num -> bool) CROSS ((UNIV : num -> bool) DIFF {0}))
       (UNIV : num -> bool)``,
   MATCH_MP_TAC BIJ_INJ_SURJ
   >> reverse CONJ_TAC
   >- (Q.EXISTS_TAC `FST`
       >> RW_TAC std_ss [SURJ_DEF, IN_UNIV, IN_CROSS,DIFF_DEF,GSPECIFICATION,IN_UNIV,IN_SING]
       >> Q.EXISTS_TAC `(x, 1)`
       >> RW_TAC std_ss [FST])
   >> Q.EXISTS_TAC `UNCURRY ind_type$NUMPAIR`
   >> RW_TAC std_ss [INJ_DEF, IN_UNIV, IN_CROSS]
   >> Cases_on `x`
   >> Cases_on `y`
   >> POP_ASSUM MP_TAC
   >> RW_TAC std_ss [UNCURRY_DEF, ind_typeTheory.NUMPAIR_INJ]);

val NUM_2D_BIJ_NZ_INV = store_thm
  ("NUM_2D_BIJ_NZ_INV",
   ``?f.
       BIJ f (UNIV : num -> bool)
       ((UNIV : num -> bool) CROSS ((UNIV : num -> bool) DIFF {0}))``,
   PROVE_TAC [NUM_2D_BIJ_NZ, BIJ_SYM]);

val NUM_2D_BIJ_NZ_ALT = store_thm
  ("NUM_2D_BIJ_NZ_ALT",
   ``?f.
       BIJ f ((UNIV : num -> bool) CROSS (UNIV : num -> bool))
       ((UNIV : num -> bool) DIFF {0})``,
   MATCH_MP_TAC BIJ_INJ_SURJ
   >> reverse CONJ_TAC
   >- (Q.EXISTS_TAC `(\(x,y). x + 1:num)`
       >> RW_TAC std_ss [SURJ_DEF, IN_UNIV, IN_CROSS]
                >- (Cases_on `x` >> RW_TAC std_ss [DIFF_DEF,GSPECIFICATION,IN_UNIV,IN_SING])
       >> Q.EXISTS_TAC `(x-1,1)`
       >> RW_TAC std_ss []
       >> MATCH_MP_TAC SUB_ADD
       >> FULL_SIMP_TAC real_ss [DIFF_DEF,GSPECIFICATION,IN_UNIV,IN_SING])
   >> Q.EXISTS_TAC `UNCURRY ind_type$NUMPAIR`
   >> RW_TAC std_ss [INJ_DEF, IN_UNIV, IN_CROSS]
   >- ( Cases_on `x`
        >> RW_TAC std_ss [UNCURRY_DEF, ind_typeTheory.NUMPAIR_INJ,DIFF_DEF,
                          GSPECIFICATION,IN_UNIV,IN_SING]
        >> RW_TAC real_ss [ind_typeTheory.NUMPAIR])
   >> Cases_on `x`
   >> Cases_on `y`
   >> POP_ASSUM MP_TAC
   >> RW_TAC std_ss [UNCURRY_DEF, ind_typeTheory.NUMPAIR_INJ]);

val NUM_2D_BIJ_NZ_ALT_INV = store_thm
  ("NUM_2D_BIJ_NZ_ALT_INV",
   ``?f.
       BIJ f ((UNIV : num -> bool) DIFF {0})
       ((UNIV : num -> bool) CROSS (UNIV : num -> bool))``,
   PROVE_TAC [NUM_2D_BIJ_NZ_ALT, BIJ_SYM]);

val NUM_2D_BIJ_NZ_ALT2 = store_thm
  ("NUM_2D_BIJ_NZ_ALT2",
   ``?f.
       BIJ f (((UNIV : num -> bool) DIFF {0}) CROSS ((UNIV : num -> bool) DIFF {0}))
       (UNIV : num -> bool)``,
   MATCH_MP_TAC BIJ_INJ_SURJ
   >> reverse CONJ_TAC
   >- (Q.EXISTS_TAC `(\(x,y). x - 1:num)`
       >> RW_TAC std_ss [SURJ_DEF, IN_UNIV, IN_CROSS]
       >> Q.EXISTS_TAC `(x+1,1)`
       >> RW_TAC std_ss [DIFF_DEF,GSPECIFICATION,IN_UNIV,IN_SING]
       )
   >> Q.EXISTS_TAC `UNCURRY ind_type$NUMPAIR`
   >> RW_TAC std_ss [INJ_DEF, IN_UNIV, IN_CROSS]
   >> Cases_on `x`
   >> Cases_on `y`
   >> POP_ASSUM MP_TAC
   >> RW_TAC std_ss [UNCURRY_DEF, ind_typeTheory.NUMPAIR_INJ]);

val NUM_2D_BIJ_NZ_ALT2_INV = store_thm
  ("NUM_2D_BIJ_NZ_ALT2_INV",
   ``?f.
       BIJ f (UNIV : num -> bool)
       (((UNIV : num -> bool) DIFF {0}) CROSS ((UNIV : num -> bool) DIFF {0}))``,
   PROVE_TAC [NUM_2D_BIJ_NZ_ALT2, BIJ_SYM]);

(* Two concrete NUM_2D_BIJ lemmas using numpairTheory *)
val NUM_2D_BIJ_nfst_nsnd = store_thm
  ("NUM_2D_BIJ_nfst_nsnd", ``BIJ (\n. (nfst n, nsnd n)) UNIV (UNIV CROSS UNIV)``,
    REWRITE_TAC [BIJ_ALT, IN_CROSS, IN_FUNSET, IN_UNIV]
 >> BETA_TAC >> GEN_TAC >> Cases_on `y`
 >> SIMP_TAC std_ss [EXISTS_UNIQUE_ALT]
 >> Q.EXISTS_TAC `npair q r`
 >> GEN_TAC >> STRIP_ASSUME_TAC (Q.SPEC `x'` npair_cases)
 >> POP_ASSUM (REWRITE_TAC o wrap)
 >> REWRITE_TAC [nfst_npair, nsnd_npair, npair_11]);

val NUM_2D_BIJ_npair = store_thm
  ("NUM_2D_BIJ_npair", ``BIJ (UNCURRY npair) (UNIV CROSS UNIV) UNIV``,
    REWRITE_TAC [BIJ_ALT, IN_CROSS, IN_FUNSET, IN_UNIV, UNCURRY]
 >> GEN_TAC >> SIMP_TAC std_ss [EXISTS_UNIQUE_ALT]
 >> Q.EXISTS_TAC `nfst y, nsnd y`
 >> GEN_TAC >> STRIP_ASSUME_TAC (Q.SPEC `y` npair_cases)
 >> POP_ASSUM (REWRITE_TAC o wrap)
 >> REWRITE_TAC [nfst_npair, nsnd_npair, npair_11]
 >> Cases_on `x'` >> SIMP_TAC std_ss []);

val finite_enumeration_of_sets_has_max_non_empty = store_thm
  ("finite_enumeration_of_sets_has_max_non_empty",
   ``!f s. FINITE s /\ (!x. f x IN s) /\
            (!m n. ~(m = n) ==> DISJOINT (f m) (f n)) ==>
            ?N. !n:num. n >= N ==> (f n = {})``,
        `!s. FINITE s ==>
        (\s. !f. (!x. f x IN {} INSERT s) /\
                 (~({} IN s)) /\
                 (!m n. ~(m = n) ==> DISJOINT (f m) (f n)) ==>
                 ?N. !n:num. n >= N ==> (f n = {})) s`
        by (MATCH_MP_TAC FINITE_INDUCT
            >> RW_TAC std_ss [NOT_IN_EMPTY, IN_INSERT]
            >> Q.PAT_X_ASSUM `!f. (!x. (f x = {}) \/ f x IN s) /\ ~({} IN s) /\
                                (!m n. ~(m = n) ==> DISJOINT (f m) (f n)) ==>
                                ?N:num. !n. n >= N ==> (f n = {})`
                (MP_TAC o Q.SPEC `(\x. if f x = e then {} else f x)`)
            >> `(!x. ((\x. (if f x = e then {} else f x)) x = {}) \/
                     (\x. (if f x = e then {} else f x)) x IN s) /\ ~({} IN s)`
                by METIS_TAC []
            >> ASM_SIMP_TAC std_ss []
            >> `(!m n. ~(m = n) ==> DISJOINT (if f m = e then {} else f m)
                        (if f n = e then {} else f n))`
                by (RW_TAC std_ss [IN_DISJOINT, NOT_IN_EMPTY]
                            >> METIS_TAC [IN_DISJOINT])
            >> ASM_SIMP_TAC std_ss []
            >> RW_TAC std_ss []
            >> Cases_on `?n. f n = e`
            >- (FULL_SIMP_TAC std_ss []
                >> Cases_on `n < N`
                >- (Q.EXISTS_TAC `N`
                    >> RW_TAC std_ss [GREATER_EQ]
                    >> `~(n' = n)`
                        by METIS_TAC [LESS_LESS_EQ_TRANS,
                                      DECIDE ``!m (n:num). m < n ==> ~(m=n)``]
                    >> Cases_on `f n' = f n`
                    >- (`DISJOINT (f n') (f n)` by METIS_TAC []
                        >> FULL_SIMP_TAC std_ss [IN_DISJOINT, EXTENSION, NOT_IN_EMPTY]
                        >> METIS_TAC [])
                    >> Q.PAT_X_ASSUM
                                `!n'. n' >= N ==> ((if f n' = f n then {} else f n') = {})`
                                (MP_TAC o Q.SPEC `n'`)
                    >> ASM_SIMP_TAC std_ss [GREATER_EQ])
                >> Q.EXISTS_TAC `SUC n`
                >> RW_TAC std_ss [GREATER_EQ]
                >> FULL_SIMP_TAC std_ss [NOT_LESS]
                >> `~(n' = n)`
                        by METIS_TAC [LESS_LESS_EQ_TRANS,
                                      DECIDE ``!n:num. n < SUC n``,
                                      DECIDE ``!m (n:num). m < n ==> ~(m=n)``]
                >> Cases_on `f n' = f n`
                >- (`DISJOINT (f n') (f n)` by METIS_TAC []
                    >> FULL_SIMP_TAC std_ss [IN_DISJOINT, EXTENSION, NOT_IN_EMPTY]
                    >> METIS_TAC [])
                >> `N <= n'` by METIS_TAC [LESS_EQ_IMP_LESS_SUC,
                                           LESS_LESS_EQ_TRANS,
                                           LESS_IMP_LESS_OR_EQ]
                >> Q.PAT_X_ASSUM
                                `!n'. n' >= N ==> ((if f n' = f n then {} else f n') = {})`
                                (MP_TAC o Q.SPEC `n'`)
                >> ASM_SIMP_TAC std_ss [GREATER_EQ])
        >> METIS_TAC [])
   >> REPEAT STRIP_TAC
   >> Cases_on `{} IN s`
   >- (Q.PAT_X_ASSUM `!s. FINITE s ==> P` (MP_TAC o Q.SPEC `s DELETE {}`)
       >> RW_TAC std_ss [FINITE_DELETE, IN_INSERT, IN_DELETE])
   >> METIS_TAC [IN_INSERT]);

val PREIMAGE_REAL_COMPL1 = store_thm
  ("PREIMAGE_REAL_COMPL1", ``!c:real. COMPL {x | c < x} = {x | x <= c}``,
  RW_TAC real_ss [COMPL_DEF,UNIV_DEF,DIFF_DEF,EXTENSION]
  >> RW_TAC real_ss [GSPECIFICATION,GSYM real_lte,SPECIFICATION]);

val PREIMAGE_REAL_COMPL2 = store_thm
  ("PREIMAGE_REAL_COMPL2", ``!c:real. COMPL {x | c <= x} = {x | x < c}``,
  RW_TAC real_ss [COMPL_DEF,UNIV_DEF,DIFF_DEF,EXTENSION]
  >> RW_TAC real_ss [GSPECIFICATION,GSYM real_lt,SPECIFICATION]);

val PREIMAGE_REAL_COMPL3 = store_thm
  ("PREIMAGE_REAL_COMPL3", ``!c:real. COMPL {x | x <= c} = {x | c < x}``,
  RW_TAC real_ss [COMPL_DEF,UNIV_DEF,DIFF_DEF,EXTENSION]
  >> RW_TAC real_ss [GSPECIFICATION,GSYM real_lt,SPECIFICATION]);

val PREIMAGE_REAL_COMPL4 = store_thm
  ("PREIMAGE_REAL_COMPL4", ``!c:real. COMPL {x | x < c} = {x | c <= x}``,
  RW_TAC real_ss [COMPL_DEF,UNIV_DEF,DIFF_DEF,EXTENSION]
  >> RW_TAC real_ss [GSPECIFICATION,GSYM real_lte,SPECIFICATION]);

val GBIGUNION_IMAGE = store_thm
  ("GBIGUNION_IMAGE",
   ``!s p n. {s | ?n. p s n} = BIGUNION (IMAGE (\n. {s | p s n}) UNIV)``,
   RW_TAC std_ss [EXTENSION, GSPECIFICATION, IN_BIGUNION_IMAGE, IN_UNIV]);

(* ********************************************* *)
(*       Useful Theorems on Real Numbers         *)
(* ********************************************* *)

val POW_HALF_POS = store_thm
  ("POW_HALF_POS",
   ``!n. 0:real < (1/2) pow n``,
   STRIP_TAC
   >> Cases_on `n` >- PROVE_TAC [REAL_ARITH ``0:real < 1``, pow]
   >> PROVE_TAC [HALF_POS, POW_POS_LT]);

val POW_HALF_SMALL = store_thm
  ("POW_HALF_SMALL",
   ``!e:real. 0 < e ==> ?n. (1 / 2) pow n < e``,
   RW_TAC std_ss []
   >> MP_TAC (Q.SPEC `1 / 2` SEQ_POWER)
   >> RW_TAC std_ss [abs, HALF_LT_1, HALF_POS, REAL_LT_IMP_LE, SEQ]
   >> POP_ASSUM (MP_TAC o Q.SPEC `e`)
   >> RW_TAC std_ss [REAL_SUB_RZERO, POW_HALF_POS, REAL_LT_IMP_LE,
                      GREATER_EQ]
   >> PROVE_TAC [LESS_EQ_REFL]);

val POW_HALF_MONO = store_thm
  ("POW_HALF_MONO",
   ``!m n. m <= n ==> ((1:real)/2) pow n <= (1/2) pow m``,
   REPEAT STRIP_TAC
   >> Induct_on `n` >|
   [STRIP_TAC
    >> Know `m:num = 0` >- DECIDE_TAC
    >> PROVE_TAC [REAL_ARITH ``a:real <= a``],
    Cases_on `m = SUC n` >- PROVE_TAC [REAL_ARITH ``a:real <= a``]
    >> ONCE_REWRITE_TAC [pow]
    >> STRIP_TAC
    >> Know `m:num <= n` >- DECIDE_TAC
    >> STRIP_TAC
    >> Suff `(2:real) * ((1/2) * (1/2) pow n) <= 2 * (1/2) pow m`
    >- PROVE_TAC [REAL_ARITH ``0:real < 2``, REAL_LE_LMUL]
    >> Suff `((1:real)/2) pow n <= 2 * (1/2) pow m`
    >- (KILL_TAC
        >> PROVE_TAC [GSYM REAL_MUL_ASSOC, HALF_CANCEL, REAL_MUL_LID])
    >> PROVE_TAC [REAL_ARITH ``!x y. 0:real < x /\ x <= y ==> x <= 2 * y``,
                  POW_HALF_POS]]);

val REAL_LE_LT_MUL = store_thm
  ("REAL_LE_LT_MUL",
   ``!x y : real. 0 <= x /\ 0 < y ==> 0 <= x * y``,
   rpt STRIP_TAC
   >> MP_TAC (Q.SPECL [`0`, `x`, `y`] REAL_LE_RMUL)
   >> RW_TAC std_ss [REAL_MUL_LZERO]);

val REAL_LT_LE_MUL = store_thm
  ("REAL_LT_LE_MUL",
   ``!x y : real. 0 < x /\ 0 <= y ==> 0 <= x * y``,
   PROVE_TAC [REAL_LE_LT_MUL, REAL_MUL_SYM]);

val REAL_MUL_IDEMPOT = store_thm
  ("REAL_MUL_IDEMPOT",
   ``!r: real. (r * r = r) <=> (r = 0) \/ (r = 1)``,
   GEN_TAC
   >> reverse EQ_TAC
   >- (RW_TAC real_ss [] >> RW_TAC std_ss [REAL_MUL_LZERO, REAL_MUL_LID])
   >> RW_TAC std_ss []
   >> Know `r * r = 1 * r` >- RW_TAC real_ss []
   >> RW_TAC std_ss [REAL_EQ_RMUL]);

val REAL_SUP_LE_X = store_thm
  ("REAL_SUP_LE_X",
   ``!P x:real. (?r. P r) /\ (!r. P r ==> r <= x) ==> sup P <= x``,
   RW_TAC real_ss []
   >> Suff `~(x < sup P)` >- REAL_ARITH_TAC
   >> STRIP_TAC
   >> MP_TAC (SPEC ``P:real->bool`` REAL_SUP_LE)
   >> RW_TAC real_ss [] >|
   [PROVE_TAC [],
    PROVE_TAC [],
    EXISTS_TAC ``x:real``
    >> RW_TAC real_ss []
    >> PROVE_TAC [real_lte]]);

val REAL_X_LE_SUP = store_thm
  ("REAL_X_LE_SUP",
   ``!P x:real. (?r. P r) /\ (?z. !r. P r ==> r <= z) /\ (?r. P r /\ x <= r)
           ==> x <= sup P``,
   RW_TAC real_ss []
   >> Suff `!y. P y ==> y <= sup P` >- PROVE_TAC [REAL_LE_TRANS]
   >> MATCH_MP_TAC REAL_SUP_UBOUND_LE
   >> PROVE_TAC []);

val INF_DEF_ALT = store_thm (* c.f. "inf_alt" in seqTheory *)
  ("INF_DEF_ALT",
   ``!p. inf p = ~(sup (\r. ~r IN p)):real``,
   RW_TAC std_ss []
   >> PURE_REWRITE_TAC [inf_def, IMAGE_DEF]
   >> Suff `(\r. p (-r)) = (\r. -r IN p)`
   >- RW_TAC std_ss []
   >> RW_TAC std_ss [FUN_EQ_THM,SPECIFICATION]);

val LE_INF = store_thm
  ("LE_INF",
   ``!p r:real. (?x. x IN p) /\ (!x. x IN p ==> r <= x) ==> r <= inf p``,
   RW_TAC std_ss [INF_DEF_ALT, SPECIFICATION]
   >> POP_ASSUM MP_TAC
   >> ONCE_REWRITE_TAC [GSYM REAL_NEGNEG]
   >> Q.SPEC_TAC (`~r`, `r`)
   >> RW_TAC real_ss [REAL_NEGNEG, REAL_LE_NEG]
   >> MATCH_MP_TAC REAL_SUP_LE_X
   >> RW_TAC std_ss []
   >> PROVE_TAC [REAL_NEGNEG]);

val INF_LE = store_thm
  ("INF_LE",
   ``!p r:real.
       (?z. !x. x IN p ==> z <= x) /\ (?x. x IN p /\ x <= r) ==> inf p <= r``,
   RW_TAC std_ss [INF_DEF_ALT, SPECIFICATION]
   >> POP_ASSUM MP_TAC
   >> ONCE_REWRITE_TAC [GSYM REAL_NEGNEG]
   >> Q.SPEC_TAC (`~r`, `r`)
   >> RW_TAC real_ss [REAL_NEGNEG, REAL_LE_NEG]
   >> MATCH_MP_TAC REAL_X_LE_SUP
   >> RW_TAC std_ss []
   >> PROVE_TAC [REAL_NEGNEG, REAL_LE_NEG]);

val INF_GREATER = store_thm
  ("INF_GREATER",
   ``!p z:real.
       (?x. x IN p) /\ inf p < z ==>
       (?x. x IN p /\ x < z)``,
   RW_TAC std_ss []
   >> Suff `~(!x. x IN p ==> ~(x < z))` >- PROVE_TAC []
   >> REWRITE_TAC [GSYM real_lte]
   >> STRIP_TAC
   >> Q.PAT_X_ASSUM `inf p < z` MP_TAC
   >> RW_TAC std_ss [GSYM real_lte]
   >> MATCH_MP_TAC LE_INF
   >> PROVE_TAC []);

val INF_CLOSE = store_thm
  ("INF_CLOSE",
   ``!p e:real.
       (?x. x IN p) /\ 0 < e ==> (?x. x IN p /\ x < inf p + e)``,
   RW_TAC std_ss []
   >> MATCH_MP_TAC INF_GREATER
   >> CONJ_TAC >- PROVE_TAC []
   >> POP_ASSUM MP_TAC
   >> REAL_ARITH_TAC);

Theorem REAL_NEG_NZ :
    !x:real. x < 0 ==> x <> 0
Proof
    GEN_TAC >> DISCH_TAC
 >> MATCH_MP_TAC REAL_LT_IMP_NE
 >> ASM_REWRITE_TAC []
QED

val REAL_LT_LMUL_0_NEG = store_thm
  ("REAL_LT_LMUL_0_NEG",``!x y:real. 0 < x * y /\ x < 0 ==> y < 0``,
 RW_TAC real_ss []
 >> SPOSE_NOT_THEN ASSUME_TAC
 >> FULL_SIMP_TAC real_ss [REAL_NOT_LT, GSYM REAL_NEG_GT0]
 >> METIS_TAC [REAL_MUL_LNEG, REAL_LT_IMP_LE, REAL_LE_MUL,
               REAL_NEG_GE0, REAL_NOT_LT]);

val REAL_LT_RMUL_0_NEG = store_thm
  ("REAL_LT_RMUL_0_NEG",``!x y:real. 0 < x * y /\ y < 0 ==> x < 0``,
 RW_TAC real_ss []
 >> SPOSE_NOT_THEN ASSUME_TAC
 >> FULL_SIMP_TAC real_ss [REAL_NOT_LT,GSYM REAL_NEG_GT0]
 >> METIS_TAC [REAL_MUL_RNEG, REAL_LT_IMP_LE, REAL_LE_MUL, REAL_NEG_GE0, REAL_NOT_LT]);

val REAL_LT_LMUL_NEG_0 = store_thm
  ("REAL_LT_LMUL_NEG_0",``!x y:real. x * y < 0 /\ 0 < x ==> y < 0``,
 RW_TAC real_ss []
 >> METIS_TAC [REAL_NEG_GT0, REAL_NEG_RMUL, REAL_LT_LMUL_0]);

val REAL_LT_RMUL_NEG_0 = store_thm
  ("REAL_LT_RMUL_NEG_0",``!x y:real. x * y < 0 /\ 0 < y ==> x < 0``,
 RW_TAC real_ss []
 >> METIS_TAC [REAL_NEG_GT0, REAL_NEG_LMUL, REAL_LT_RMUL_0]);

val REAL_LT_LMUL_NEG_0_NEG = store_thm
 ("REAL_LT_LMUL_NEG_0_NEG",``!x y:real. x * y < 0 /\ x < 0 ==> 0 < y``,
 RW_TAC real_ss []
 >> METIS_TAC [REAL_NEG_GT0, REAL_NEG_LMUL, REAL_LT_LMUL_0]);

val REAL_LT_RMUL_NEG_0_NEG = store_thm
 ("REAL_LT_RMUL_NEG_0_NEG",``!x y:real. x * y < 0 /\ y < 0 ==> 0 < x``,
 RW_TAC real_ss []
 >> METIS_TAC [REAL_NEG_GT0, REAL_NEG_RMUL, REAL_LT_RMUL_0]);

val REAL_LT_RDIV_EQ_NEG = store_thm
  ("REAL_LT_RDIV_EQ_NEG", ``!x y z. z < 0:real ==> (y / z < x <=> x * z < y)``,
  RW_TAC real_ss []
  >> `0<-z` by RW_TAC real_ss [REAL_NEG_GT0]
  >> `z<>0` by (METIS_TAC [REAL_LT_IMP_NE])
  >>EQ_TAC
  >- (RW_TAC real_ss []
      >> `y/z*(-z) < x*(-z)` by METIS_TAC [GSYM REAL_LT_RMUL]
      >> FULL_SIMP_TAC real_ss []
      >> METIS_TAC [REAL_DIV_RMUL, REAL_LT_NEG])
  >> RW_TAC real_ss []
  >> `-y < x*(-z)` by FULL_SIMP_TAC real_ss [REAL_LT_NEG]
  >> `-y * inv(-z) < x` by METIS_TAC [GSYM REAL_LT_LDIV_EQ, real_div]
  >> METIS_TAC [REAL_NEG_INV, REAL_NEG_MUL2, GSYM real_div]);

val REAL_LE_RDIV_EQ_NEG = store_thm
  ("REAL_LE_RDIV_EQ_NEG", ``!x y z. z < 0:real ==> (y / z <= x <=> x * z <= y)``,
  RW_TAC real_ss []
  >> `0 < -z` by RW_TAC real_ss [REAL_NEG_GT0]
  >> `z <> 0` by (METIS_TAC [REAL_LT_IMP_NE])
  >>EQ_TAC
  >- (RW_TAC real_ss []
      >> `y / z * (-z) <= x * (-z)` by METIS_TAC [GSYM REAL_LE_RMUL]
      >> FULL_SIMP_TAC real_ss []
      >> METIS_TAC [REAL_DIV_RMUL,REAL_LE_NEG])
  >> RW_TAC real_ss []
  >> `-y <= x * (-z)` by FULL_SIMP_TAC real_ss [REAL_LE_NEG]
  >> `-y * inv (-z) <= x` by METIS_TAC [GSYM REAL_LE_LDIV_EQ, real_div]
  >> METIS_TAC [REAL_NEG_INV, REAL_NEG_MUL2, GSYM real_div]);

val POW_POS_EVEN = store_thm
  ("POW_POS_EVEN",``!x:real. x < 0 ==> ((0 < x pow n) <=> (EVEN n))``,
  Induct_on `n`
  >- RW_TAC std_ss [pow,REAL_LT_01,EVEN]
  >> RW_TAC std_ss [pow,EVEN]
  >> EQ_TAC
  >- METIS_TAC [REAL_LT_ANTISYM, REAL_LT_RMUL_0_NEG, REAL_MUL_COMM]
  >> RW_TAC std_ss []
  >> `x pow n <= 0` by METIS_TAC [real_lt]
  >> `x pow n <> 0` by METIS_TAC [POW_NZ, REAL_LT_IMP_NE]
  >> `x pow n < 0` by METIS_TAC [REAL_LT_LE]
  >> METIS_TAC [REAL_NEG_GT0, REAL_NEG_MUL2, REAL_LT_MUL]);

val POW_NEG_ODD = store_thm
  ("POW_NEG_ODD",``!x:real. x < 0 ==> ((x pow n < 0) <=> (ODD n))``,
  Induct_on `n`
  >- RW_TAC std_ss [pow,GSYM real_lte,REAL_LE_01]
  >> RW_TAC std_ss [pow,ODD]
  >> EQ_TAC
  >- METIS_TAC [REAL_LT_RMUL_NEG_0_NEG, REAL_MUL_COMM, REAL_LT_ANTISYM]
  >> RW_TAC std_ss []
  >> `0 <= x pow n` by METIS_TAC [real_lt]
  >> `x pow n <> 0` by METIS_TAC [POW_NZ, REAL_LT_IMP_NE]
  >> `0 < x pow n` by METIS_TAC [REAL_LT_LE]
  >> METIS_TAC [REAL_NEG_GT0, REAL_MUL_LNEG, REAL_LT_MUL]);

Theorem REAL_MAX_REDUCE :
    !x y :real. x <= y \/ x < y ==> (max x y = y) /\ (max y x = y)
Proof
    PROVE_TAC [REAL_LT_IMP_LE, REAL_MAX_ACI, max_def]
QED

Theorem REAL_MIN_REDUCE :
    !x y :real. x <= y \/ x < y ==> (min x y = x) /\ (min y x = x)
Proof
    PROVE_TAC [REAL_LT_IMP_LE, REAL_MIN_ACI, min_def]
QED

Theorem REAL_LT_MAX_BETWEEN :
    !x b d :real. x < max b d /\ b <= x ==> x < d
Proof
    RW_TAC std_ss [max_def]
 >> fs [real_lte]
QED

Theorem REAL_MIN_LE_BETWEEN :
    !x a c :real. min a c <= x /\ x < a ==> c <= x
Proof
    RW_TAC std_ss [min_def]
 >> PROVE_TAC [REAL_LET_ANTISYM]
QED

Theorem REAL_ARCH_INV_SUC : (* was: reals_Archimedean *)
    !x:real. 0 < x ==> ?n. inv &(SUC n) < x
Proof
  RW_TAC real_ss [REAL_INV_1OVER] THEN SIMP_TAC real_ss [REAL_LT_LDIV_EQ] THEN
  ONCE_REWRITE_TAC [REAL_MUL_SYM] THEN
  ASM_SIMP_TAC real_ss [GSYM REAL_LT_LDIV_EQ] THEN
  MP_TAC (ISPEC ``1 / x:real`` SIMP_REAL_ARCH) THEN STRIP_TAC THEN
  Q.EXISTS_TAC `n` THEN FULL_SIMP_TAC real_ss [real_div] THEN
  RULE_ASSUM_TAC (ONCE_REWRITE_RULE [GSYM REAL_LT_INV_EQ]) THEN
  REWRITE_TAC [ADD1, GSYM add_ints] THEN REAL_ASM_ARITH_TAC
QED

Theorem REAL_ARCH_INV' : (* was: ex_inverse_of_nat_less *)
    !x:real. 0 < x ==> ?n. inv (&n) < x
Proof
  RW_TAC std_ss [] THEN FIRST_ASSUM (MP_TAC o MATCH_MP REAL_ARCH_INV_SUC) THEN
  METIS_TAC []
QED

Theorem REAL_LE_MUL' :
    !x y. x <= 0 /\ y <= 0 ==> 0 <= x * y
Proof
    rpt STRIP_TAC
 >> MP_TAC (Q.SPECL [‘-x’, ‘-y’] REAL_LE_MUL)
 >> REWRITE_TAC [GSYM REAL_NEG_LE0, REAL_NEGNEG, REAL_NEG_MUL2]
 >> DISCH_THEN MATCH_MP_TAC
 >> ASM_REWRITE_TAC []
QED

Theorem REAL_LT_MUL' :
    !x y. x < 0 /\ y < 0 ==> 0 < x * y
Proof
    rpt STRIP_TAC
 >> MP_TAC (Q.SPECL [‘-x’, ‘-y’] REAL_LT_MUL)
 >> REWRITE_TAC [GSYM REAL_NEG_LT0, REAL_NEGNEG, REAL_NEG_MUL2]
 >> DISCH_THEN MATCH_MP_TAC
 >> ASM_REWRITE_TAC []
QED

Theorem REAL_LT_LMUL' :
    !x y z. x < 0 ==> ((x * y) < (x * z) <=> z < y)
Proof
    rpt STRIP_TAC
 >> MP_TAC (Q.SPECL [‘-x’, ‘z’, ‘y’] REAL_LT_LMUL)
 >> ‘0 < -x’ by PROVE_TAC [GSYM REAL_NEG_LT0, REAL_NEGNEG]
 >> rw [GSYM REAL_NEG_RMUL, REAL_LT_NEG]
QED

Theorem REAL_LT_RMUL' :
    !x y z. z < 0 ==> ((x * z) < (y * z) <=> y < x)
Proof
    rpt STRIP_TAC
 >> MP_TAC (Q.SPECL [‘y’, ‘x’, ‘-z’] REAL_LT_RMUL)
 >> ‘0 < -z’ by PROVE_TAC [GSYM REAL_NEG_LT0, REAL_NEGNEG]
 >> rw [GSYM REAL_NEG_RMUL, REAL_LT_NEG]
QED

Theorem REAL_LT_LDIV_CANCEL :
    !x y (z :real). 0 < x /\ 0 < y /\ 0 < z ==> (z / x < z / y <=> y < x)
Proof
    RW_TAC bool_ss [real_div, REAL_LT_LMUL]
 >> MATCH_MP_TAC REAL_INV_LT_ANTIMONO
 >> ASM_REWRITE_TAC []
QED

Theorem REAL_LE_LDIV_CANCEL :
    !x y (z :real). 0 < x /\ 0 < y /\ 0 < z ==> (z / x <= z / y <=> y <= x)
Proof
    RW_TAC bool_ss [real_div, REAL_LE_LMUL]
 >> MATCH_MP_TAC REAL_INV_LE_ANTIMONO
 >> ASM_REWRITE_TAC []
QED

Theorem HARMONIC_SERIES_POW_2 :
    summable (\n. inv (&(SUC n) pow 2))
Proof
    MATCH_MP_TAC POS_SUMMABLE
 >> CONJ_TAC >- rw []
 >> Q.EXISTS_TAC `2`
 >> GEN_TAC
 >> Cases_on `n` >- rw [sum]
 >> rename1 ‘sum (0,SUC m) (\n. inv (&SUC n pow 2)) <= 2’
 >> MATCH_MP_TAC REAL_LE_TRANS
 >> Q.EXISTS_TAC `1 + sum (1,m) (\n. inv (&n) - inv (&SUC n))`
 >> CONJ_TAC
 >- (Know `sum (0,SUC m) (\n. inv (&SUC n pow 2)) =
           sum (0,1) (\n. inv (&SUC n pow 2)) + sum (1,m) (\n. inv (&SUC n pow 2))`
     >- (MATCH_MP_TAC EQ_SYM \\
         MP_TAC (Q.SPECL [`\n. inv (&SUC n pow 2)`, `1`, `m`] SUM_TWO) \\
         RW_TAC arith_ss [ADD1]) >> Rewr' \\
     Know `sum (0,1) (\n. inv (&SUC n pow 2)) = 1`
     >- (REWRITE_TAC [sum, ONE] >> rw []) >> Rewr' \\
     REWRITE_TAC [REAL_LE_LADD] \\
     MATCH_MP_TAC realTheory.SUM_LE \\
     RW_TAC real_ss [REAL_INV_1OVER] \\
    `&r <> 0` by RW_TAC real_ss [] \\
    `&SUC r <> 0` by RW_TAC real_ss [] \\
     ASM_SIMP_TAC real_ss [REAL_SUB_RAT] \\
    `&SUC r - &r = 1` by METIS_TAC [REAL, REAL_ADD_SUB] >> POP_ORW \\
     ASM_SIMP_TAC std_ss [POW_2, GSYM REAL_INV_1OVER] \\
    `0 < &SUC r * &SUC r` by rw [] \\
     Know `0 < &(r * SUC r)`
     >- (rw [] >> `0 = r * 0` by RW_TAC arith_ss [] >> POP_ORW \\
         rw [LT_MULT_LCANCEL]) >> DISCH_TAC \\
     MATCH_MP_TAC REAL_LT_IMP_LE \\
     ASM_SIMP_TAC real_ss [REAL_INV_LT_ANTIMONO] \\
    `SUC r ** 2 = SUC r * SUC r` by RW_TAC arith_ss [] >> POP_ORW \\
     RW_TAC arith_ss [LT_MULT_RCANCEL])
 >> `2 = 1 + (1 :real)` by RW_TAC real_ss [] >> POP_ORW
 >> REWRITE_TAC [REAL_LE_LADD]
 >> Q.ABBREV_TAC `f = \n. -inv (&n)`
 >> Know `!n. inv (&n) - inv (&SUC n) = f (SUC n) - f n`
 >- (RW_TAC real_ss [Abbr `f`] \\
     REAL_ASM_ARITH_TAC) >> Rewr'
 >> REWRITE_TAC [SUM_CANCEL]
 >> rw [Abbr `f`, REAL_SUB_NEG2, REAL_LE_SUB_RADD, REAL_LE_ADDR]
QED

(* ------------------------------------------------------------------------- *)
(*   Disjoint subsets (from HVG's lebesgue_measureTheory)                    *)
(* ------------------------------------------------------------------------- *)

Theorem DISJOINT_RESTRICT_L :
  !s t c. DISJOINT s t ==> DISJOINT (s INTER c) (t INTER c)
Proof SET_TAC []
QED

Theorem DISJOINT_RESTRICT_R :
  !s t c. DISJOINT s t ==> DISJOINT (c INTER s) (c INTER t)
Proof SET_TAC []
QED

Theorem DISJOINT_CROSS_L :
    !s t c. DISJOINT s t ==> DISJOINT (s CROSS c) (t CROSS c)
Proof
    RW_TAC std_ss [DISJOINT_ALT, CROSS_DEF, Once EXTENSION, IN_INTER,
                   NOT_IN_EMPTY, GSPECIFICATION]
QED

Theorem DISJOINT_CROSS_R :
    !s t c. DISJOINT s t ==> DISJOINT (c CROSS s) (c CROSS t)
Proof
    RW_TAC std_ss [DISJOINT_ALT, CROSS_DEF, Once EXTENSION, IN_INTER,
                   NOT_IN_EMPTY, GSPECIFICATION]
QED

Theorem SUBSET_RESTRICT_L :
  !r s t. s SUBSET t ==> (s INTER r) SUBSET (t INTER r)
Proof SET_TAC []
QED

Theorem SUBSET_RESTRICT_R :
  !r s t. s SUBSET t ==> (r INTER s) SUBSET (r INTER t)
Proof SET_TAC []
QED

Theorem SUBSET_RESTRICT_DIFF :
  !r s t. s SUBSET t ==> (r DIFF t) SUBSET (r DIFF s)
Proof SET_TAC []
QED

Theorem SUBSET_INTER_SUBSET_L :
  !r s t. s SUBSET t ==> (s INTER r) SUBSET t
Proof SET_TAC []
QED

Theorem SUBSET_INTER_SUBSET_R :
  !r s t. s SUBSET t ==> (r INTER s) SUBSET t
Proof SET_TAC []
QED

Theorem SUBSET_MONO_DIFF :
  !r s t. s SUBSET t ==> (s DIFF r) SUBSET (t DIFF r)
Proof SET_TAC []
QED

Theorem SUBSET_DIFF_SUBSET :
  !r s t. s SUBSET t ==> (s DIFF r) SUBSET t
Proof SET_TAC []
QED

Theorem SUBSET_DIFF_DISJOINT :
  !s1 s2 s3. (s1 SUBSET (s2 DIFF s3)) ==> DISJOINT s1 s3
Proof
    PROVE_TAC [SUBSET_DIFF]
QED

val disjoint_def = Define
   `disjoint A = !a b. a IN A /\ b IN A /\ (a <> b) ==> DISJOINT a b`;

(* |- !A. disjoint A <=> !a b. a IN A /\ b IN A /\ a <> b ==> (a INTER b = {} ) *)
val disjoint = save_thm
  ("disjoint", REWRITE_RULE [DISJOINT_DEF] disjoint_def);

val disjointI = store_thm
  ("disjointI",
  ``!A. (!a b . a IN A ==> b IN A ==> (a <> b) ==> DISJOINT a b) ==> disjoint A``,
    METIS_TAC [disjoint_def]);

val disjointD = store_thm
  ("disjointD",
  ``!A a b. disjoint A ==> a IN A ==> b IN A ==> (a <> b) ==> DISJOINT a b``,
    METIS_TAC [disjoint_def]);

val disjoint_empty = store_thm
  ("disjoint_empty", ``disjoint {}``,
    SET_TAC [disjoint_def]);

val disjoint_union = store_thm
  ("disjoint_union",
  ``!A B. disjoint A /\ disjoint B /\ (BIGUNION A INTER BIGUNION B = {}) ==>
          disjoint (A UNION B)``,
    SET_TAC [disjoint_def]);

val disjoint_sing = store_thm
  ("disjoint_sing", ``!a. disjoint {a}``,
    SET_TAC [disjoint_def]);

val disjoint_same = store_thm
  ("disjoint_same", ``!s t. (s = t) ==> disjoint {s; t}``,
    RW_TAC std_ss [IN_INSERT, IN_SING, disjoint_def]);

val disjoint_two = store_thm
  ("disjoint_two", ``!s t. s <> t /\ DISJOINT s t ==> disjoint {s; t}``,
    RW_TAC std_ss [IN_INSERT, IN_SING, disjoint_def] >- art []
 >> ASM_REWRITE_TAC [DISJOINT_SYM]);

val disjoint_image = store_thm (* new *)
  ("disjoint_image",
  ``!f. (!i j. i <> j ==> DISJOINT (f i) (f j)) ==> disjoint (IMAGE f UNIV)``,
    rpt STRIP_TAC
 >> MATCH_MP_TAC disjointI
 >> RW_TAC std_ss [IN_IMAGE, IN_UNIV]
 >> METIS_TAC []);

val disjoint_insert_imp = store_thm (* new *)
  ("disjoint_insert_imp",
  ``!e c. disjoint (e INSERT c) ==> disjoint c``,
    RW_TAC std_ss [disjoint_def]
 >> FIRST_ASSUM MATCH_MP_TAC
 >> METIS_TAC [IN_INSERT]);

val disjoint_insert_notin = store_thm (* new *)
  ("disjoint_insert_notin",
  ``!e c. disjoint (e INSERT c) /\ e NOTIN c ==> !s. s IN c ==> DISJOINT e s``,
    RW_TAC std_ss [disjoint_def]
 >> FIRST_ASSUM MATCH_MP_TAC
 >> METIS_TAC [IN_INSERT]);

val disjoint_insert = store_thm (* new *)
  ("disjoint_insert",
  ``!e c. disjoint c /\ (!x. x IN c ==> DISJOINT x e) ==> disjoint (e INSERT c)``,
    rpt STRIP_TAC
 >> Know `e INSERT c = {e} UNION c` >- SET_TAC [] >> Rewr'
 >> MATCH_MP_TAC disjoint_union
 >> art [disjoint_sing, BIGUNION_SING]
 >> ASM_SET_TAC []);

val disjoint_restrict = store_thm (* new *)
  ("disjoint_restrict",
  ``!e c. disjoint c ==> disjoint (IMAGE ($INTER e) c)``,
    RW_TAC std_ss [disjoint_def, IN_IMAGE, o_DEF]
 >> MATCH_MP_TAC DISJOINT_RESTRICT_R
 >> FIRST_X_ASSUM MATCH_MP_TAC >> art []
 >> CCONTR_TAC >> fs []);

(* ------------------------------------------------------------------------- *)
(* Binary Unions                                                             *)
(* ------------------------------------------------------------------------- *)

Definition binary_def :
    binary a b = (\x:num. if x = 0 then a else b)
End

Theorem BINARY_RANGE : (* was: range_binary_eq *)
    !a b. IMAGE (binary a b) UNIV = {a;b}
Proof
  RW_TAC std_ss [IMAGE_DEF, binary_def] THEN
  SIMP_TAC std_ss [EXTENSION, GSPECIFICATION, SET_RULE
   ``x IN {a;b} <=> (x = a) \/ (x = b)``] THEN
  GEN_TAC THEN EQ_TAC THEN STRIP_TAC THENL
  [METIS_TAC [], METIS_TAC [IN_UNIV],
   EXISTS_TAC ``1:num`` THEN ASM_SIMP_TAC arith_ss [IN_UNIV]]
QED

Theorem UNION_BINARY : (* was: Un_range_binary *)
    !a b. a UNION b = BIGUNION {binary a b i | i IN UNIV}
Proof
  SIMP_TAC arith_ss [GSYM IMAGE_DEF] THEN
  REWRITE_TAC [METIS [ETA_AX] ``(\i. binary a b i) = binary a b``] THEN
  SIMP_TAC std_ss [BINARY_RANGE] THEN SET_TAC []
QED

Theorem INTER_BINARY : (* was: Int_range_binary *)
    !a b. a INTER b = BIGINTER {binary a b i | i IN UNIV}
Proof
  SIMP_TAC arith_ss [GSYM IMAGE_DEF] THEN
  REWRITE_TAC [METIS [ETA_AX] ``(\i. binary a b i) = binary a b``] THEN
  SIMP_TAC std_ss [BINARY_RANGE] THEN SET_TAC []
QED

Theorem FINITE_TWO :
    !s t. FINITE {s; t}
Proof
    PROVE_TAC [FINITE_INSERT, FINITE_SING]
QED

Theorem SUBSET_TWO :
    !N s t. N SUBSET {s; t} /\ N <> {} ==> N = {s} \/ N = {t} \/ N = {s; t}
Proof
    rpt GEN_TAC
 >> SET_TAC []
QED

(* ------------------------------------------------------------------------- *)
(*  Some lemmas needed by CARATHEODORY in measureTheory (author: Chun Tian)  *)
(* ------------------------------------------------------------------------- *)

val DINTER_IMP_FINITE_INTER = store_thm
  ("DINTER_IMP_FINITE_INTER",
  ``!sts f. (!s t. s IN sts /\ t IN sts ==> s INTER t IN sts) /\
            f IN (UNIV -> sts)
        ==> !n. 0 < n ==> BIGINTER (IMAGE f (count n)) IN sts``,
    rpt GEN_TAC
 >> STRIP_TAC
 >> Induct_on `n`
 >> RW_TAC arith_ss []
 >> fs [IN_FUNSET, IN_UNIV]
 >> STRIP_ASSUME_TAC (Q.SPEC `n` LESS_0_CASES)
 >- RW_TAC std_ss [COUNT_SUC, COUNT_ZERO, IMAGE_INSERT, IMAGE_EMPTY,
                   BIGINTER_INSERT, IMAGE_EMPTY, BIGINTER_EMPTY, INTER_UNIV]
 >> fs [COUNT_SUC]);

(* Dual lemma of above, used in "ring_and_semiring" *)
val DUNION_IMP_FINITE_UNION = store_thm
  ("DUNION_IMP_FINITE_UNION",
  ``!sts f. (!s t. s IN sts /\ t IN sts ==> s UNION t IN sts) ==>
            !n. 0 < n /\ (!i. i < n ==> f i IN sts) ==>
                BIGUNION (IMAGE f (count n)) IN sts``,
    rpt GEN_TAC
 >> STRIP_TAC
 >> Induct_on `n`
 >> RW_TAC arith_ss []
 >> fs [IN_FUNSET, IN_UNIV]
 >> STRIP_ASSUME_TAC (Q.SPEC `n` LESS_0_CASES)
 >- RW_TAC std_ss [COUNT_SUC, COUNT_ZERO, IMAGE_INSERT, IMAGE_EMPTY,
                   BIGUNION_INSERT, IMAGE_EMPTY, BIGUNION_EMPTY, UNION_EMPTY]
 >> fs [COUNT_SUC]);

val GEN_DIFF_INTER = store_thm
  ("GEN_DIFF_INTER",
  ``!sp s t. s SUBSET sp /\ t SUBSET sp ==> (s DIFF t = s INTER (sp DIFF t))``,
    rpt STRIP_TAC
 >> ASM_SET_TAC []);

val GEN_COMPL_UNION = store_thm
  ("GEN_COMPL_UNION",
  ``!sp s t. s SUBSET sp /\ t SUBSET sp ==>
             (sp DIFF (s UNION t) = (sp DIFF s) INTER (sp DIFF t))``,
    rpt STRIP_TAC
 >> ASM_SET_TAC [])

val GEN_COMPL_INTER = store_thm
  ("GEN_COMPL_INTER",
  ``!sp s t. s SUBSET sp /\ t SUBSET sp ==>
             (sp DIFF (s INTER t) = (sp DIFF s) UNION (sp DIFF t))``,
    rpt STRIP_TAC
 >> ASM_SET_TAC [])

val COMPL_BIGINTER_IMAGE = store_thm
  ("COMPL_BIGINTER_IMAGE",
  ``!f. COMPL (BIGINTER (IMAGE f univ(:num))) = BIGUNION (IMAGE (COMPL o f) univ(:num))``,
    RW_TAC std_ss [EXTENSION, IN_COMPL, IN_BIGINTER_IMAGE, IN_BIGUNION_IMAGE, IN_UNIV]);

val COMPL_BIGUNION_IMAGE = store_thm
  ("COMPL_BIGUNION_IMAGE",
  ``!f. COMPL (BIGUNION (IMAGE f univ(:num))) = BIGINTER (IMAGE (COMPL o f) univ(:num))``,
    RW_TAC std_ss [EXTENSION, IN_COMPL, IN_BIGINTER_IMAGE, IN_BIGUNION_IMAGE, IN_UNIV]);

val GEN_COMPL_BIGINTER_IMAGE = store_thm
  ("GEN_COMPL_BIGINTER_IMAGE",
  ``!sp f. (!n. f n SUBSET sp) ==>
           (sp DIFF (BIGINTER (IMAGE f univ(:num))) =
            BIGUNION (IMAGE (\n. sp DIFF (f n)) univ(:num)))``,
    RW_TAC std_ss [EXTENSION, IN_DIFF, IN_BIGINTER_IMAGE, IN_BIGUNION_IMAGE, IN_UNIV]
 >> EQ_TAC >> rpt STRIP_TAC >> art []
 >- (Q.EXISTS_TAC `y` >> art [])
 >> Q.EXISTS_TAC `n` >> art []);

val GEN_COMPL_BIGUNION_IMAGE = store_thm
  ("GEN_COMPL_BIGUNION_IMAGE",
  ``!sp f. (!n. f n SUBSET sp) ==>
           (sp DIFF (BIGUNION (IMAGE f univ(:num))) =
            BIGINTER (IMAGE (\n. sp DIFF (f n)) univ(:num)))``,
    RW_TAC std_ss [EXTENSION, IN_DIFF, IN_BIGINTER_IMAGE, IN_BIGUNION_IMAGE, IN_UNIV]
 >> EQ_TAC >> rpt STRIP_TAC >> art []
 >> METIS_TAC []);

val COMPL_BIGINTER = store_thm
  ("COMPL_BIGINTER",
  ``!c. COMPL (BIGINTER c) = BIGUNION (IMAGE COMPL c)``,
    RW_TAC std_ss [EXTENSION, IN_COMPL, IN_BIGINTER, IN_BIGUNION_IMAGE]);

val COMPL_BIGUNION = store_thm
  ("COMPL_BIGUNION",
  ``!c. c <> {} ==> (COMPL (BIGUNION c) = BIGINTER (IMAGE COMPL c))``,
    RW_TAC std_ss [NOT_IN_EMPTY, EXTENSION, IN_COMPL, IN_BIGUNION, IN_BIGINTER_IMAGE]
 >> EQ_TAC >> rpt STRIP_TAC
 >> PROVE_TAC []);

val GEN_COMPL_BIGINTER = store_thm
  ("GEN_COMPL_BIGINTER",
  ``!sp c. (!x. x IN c ==> x SUBSET sp) ==>
           (sp DIFF (BIGINTER c) = BIGUNION (IMAGE (\x. sp DIFF x) c))``,
    RW_TAC std_ss [EXTENSION, IN_DIFF, IN_BIGINTER, IN_BIGUNION_IMAGE]
 >> EQ_TAC >> rpt STRIP_TAC >> art []
 >- (Q.EXISTS_TAC `P` >> art [])
 >> Q.EXISTS_TAC `x'` >> art []);

val GEN_COMPL_BIGUNION = store_thm
  ("GEN_COMPL_BIGUNION",
  ``!sp c. c <> {} /\ (!x. x IN c ==> x SUBSET sp) ==>
           (sp DIFF (BIGUNION c) = BIGINTER (IMAGE (\x. sp DIFF x) c))``,
    RW_TAC std_ss [EXTENSION, IN_DIFF, IN_BIGINTER, IN_BIGUNION, IN_BIGINTER_IMAGE,
                   NOT_IN_EMPTY]
 >> EQ_TAC >> rpt STRIP_TAC >> art []
 >> METIS_TAC []);

val GEN_COMPL_FINITE_UNION = store_thm
  ("GEN_COMPL_FINITE_UNION",
  ``!sp f n. 0 < n ==> (sp DIFF BIGUNION (IMAGE f (count n)) =
                        BIGINTER (IMAGE (\i. sp DIFF f i) (count n)))``,
    NTAC 2 GEN_TAC
 >> Induct_on `n`
 >> RW_TAC arith_ss []
 >> STRIP_ASSUME_TAC (Q.SPEC `n` LESS_0_CASES)
 >- RW_TAC std_ss [COUNT_SUC, COUNT_ZERO, IMAGE_INSERT, IMAGE_EMPTY, BIGINTER_SING,
                   BIGUNION_INSERT, IMAGE_EMPTY, BIGUNION_EMPTY, UNION_EMPTY]
 >> fs [COUNT_SUC]
 >> ONCE_REWRITE_TAC [UNION_COMM]
 >> ASM_REWRITE_TAC [DIFF_UNION]
 >> REWRITE_TAC [DIFF_INTER]
 >> Suff `(BIGINTER (IMAGE (\i. sp DIFF f i) (count n)) DIFF f n) SUBSET sp`
 >- (KILL_TAC >> DISCH_THEN (ASSUME_TAC o (MATCH_MP SUBSET_INTER2)) >> ASM_SET_TAC [])
 >> MATCH_MP_TAC SUBSET_TRANS
 >> Q.EXISTS_TAC `BIGINTER (IMAGE (\i. sp DIFF f i) (count n))`
 >> REWRITE_TAC [DIFF_SUBSET]
 >> REWRITE_TAC [SUBSET_DEF, IN_BIGINTER_IMAGE, IN_COUNT] >> BETA_TAC
 >> RW_TAC std_ss [IN_DIFF]
 >> RES_TAC);

val BIGINTER_PAIR = store_thm
  ("BIGINTER_PAIR",
  ``!s t. BIGINTER {s; t} = s INTER t``,
    RW_TAC std_ss [EXTENSION, IN_BIGINTER, IN_INTER, IN_INSERT, NOT_IN_EMPTY]
 >> PROVE_TAC []);

val DIFF_INTER_PAIR = store_thm
  ("DIFF_INTER_PAIR",
  ``!sp x y. sp DIFF (x INTER y) = (sp DIFF x) UNION (sp DIFF y)``,
    rpt GEN_TAC
 >> REWRITE_TAC [REWRITE_RULE [BIGINTER_PAIR] (Q.SPECL [`sp`, `{x; y}`] DIFF_BIGINTER1)]
 >> REWRITE_TAC [EXTENSION, IN_UNION, IN_BIGUNION_IMAGE]
 >> BETA_TAC
 >> GEN_TAC >> EQ_TAC >> rpt STRIP_TAC
 >| [ fs [IN_INSERT] >> PROVE_TAC [],
      Q.EXISTS_TAC `x` >> ASM_REWRITE_TAC [IN_INSERT],
      Q.EXISTS_TAC `y` >> ASM_REWRITE_TAC [IN_INSERT] ]);

val GEN_COMPL_FINITE_INTER = store_thm
  ("GEN_COMPL_FINITE_INTER",
  ``!sp f n. 0 < n ==> (sp DIFF BIGINTER (IMAGE f (count n)) =
                        BIGUNION (IMAGE (\i. sp DIFF f i) (count n)))``,
    NTAC 2 GEN_TAC
 >> Induct_on `n`
 >> RW_TAC arith_ss []
 >> STRIP_ASSUME_TAC (Q.SPEC `n` LESS_0_CASES)
 >- RW_TAC std_ss [COUNT_SUC, COUNT_ZERO, IMAGE_INSERT, IMAGE_EMPTY, BIGINTER_SING,
                   BIGUNION_INSERT, IMAGE_EMPTY, BIGUNION_EMPTY, UNION_EMPTY]
 >> fs [COUNT_SUC]
 >> ASM_REWRITE_TAC [DIFF_INTER_PAIR]);

(* This proof is provided by Thomas Tuerk, needed by SETS_TO_DISJOINT_SETS *)
val BIGUNION_IMAGE_COUNT_IMP_UNIV = store_thm
  ("BIGUNION_IMAGE_COUNT_IMP_UNIV",
  ``!f g. (!n. BIGUNION (IMAGE g (count n)) = BIGUNION (IMAGE f (count n))) ==>
          (BIGUNION (IMAGE f UNIV) = BIGUNION (IMAGE g UNIV))``,
 (* proof *)
   `!f g. (!n. BIGUNION (IMAGE g (count n)) = BIGUNION (IMAGE f (count n))) ==>
          (BIGUNION (IMAGE f UNIV) SUBSET BIGUNION (IMAGE g UNIV))`
       suffices_by PROVE_TAC [SUBSET_ANTISYM]
 >> REWRITE_TAC [SUBSET_DEF]
 >> REPEAT STRIP_TAC
 >> rename1 `e IN BIGUNION _`
 >> Know `?n. e IN BIGUNION (IMAGE f (count n))`
 >- (FULL_SIMP_TAC std_ss [IN_BIGUNION, IN_IMAGE, PULL_EXISTS, IN_COUNT] \\
     rename1 `e IN f n'` \\
     Q.EXISTS_TAC `SUC n'` \\
     Q.EXISTS_TAC `n'` \\
     ASM_SIMP_TAC arith_ss [])
 >> STRIP_TAC
 >> `e IN BIGUNION (IMAGE g (count n))` by PROVE_TAC []
 >> FULL_SIMP_TAC std_ss [IN_BIGUNION, IN_IMAGE, PULL_EXISTS, IN_UNIV]
 >> METIS_TAC []);

val BIGUNION_OVER_INTER_L = store_thm
  ("BIGUNION_OVER_INTER_L",
  ``!f d. BIGUNION (IMAGE f univ(:num)) INTER d =
          BIGUNION (IMAGE (\i. f i INTER d) univ(:num))``,
    rpt GEN_TAC
 >> REWRITE_TAC [EXTENSION]
 >> GEN_TAC >> EQ_TAC
 >| [ (* goal 1 (of 2) *)
      RW_TAC std_ss [IN_BIGUNION, IN_INTER, IN_IMAGE] \\
      `x IN (f x' INTER d)` by PROVE_TAC [IN_INTER] \\
      Q.EXISTS_TAC `f x' INTER d` >> art [] \\
      Q.EXISTS_TAC `x'` >> art [],
      (* goal 2 (of 2) *)
      RW_TAC std_ss [IN_BIGUNION, IN_INTER, IN_IMAGE] >|
      [ fs [IN_INTER] >> Q.EXISTS_TAC `f i` >> ASM_REWRITE_TAC [] \\
        Q.EXISTS_TAC `i` >> REWRITE_TAC [],
        PROVE_TAC [IN_INTER] ] ]);

val BIGUNION_OVER_INTER_R = store_thm
  ("BIGUNION_OVER_INTER_R",
  ``!f d. d INTER BIGUNION (IMAGE f univ(:num)) =
          BIGUNION (IMAGE (\i. d INTER f i) univ(:num))``,
    rpt GEN_TAC
 >> REWRITE_TAC [EXTENSION]
 >> GEN_TAC >> EQ_TAC
 >| [ (* goal 1 (of 2) *)
      RW_TAC std_ss [IN_BIGUNION, IN_INTER, IN_IMAGE, IN_UNIV] \\
      `x IN (d INTER f x')` by PROVE_TAC [IN_INTER] \\
      Q.EXISTS_TAC `d INTER f x'` >> art [] \\
      Q.EXISTS_TAC `x'` >> art [],
      (* goal 2 (of 2) *)
      RW_TAC std_ss [IN_BIGUNION, IN_INTER, IN_IMAGE, IN_UNIV] >|
      [ fs [IN_INTER] >> Q.EXISTS_TAC `f i` >> ASM_REWRITE_TAC [] \\
        Q.EXISTS_TAC `i` >> REWRITE_TAC [],
        PROVE_TAC [IN_INTER] ] ]);

val BIGUNION_OVER_DIFF = store_thm
  ("BIGUNION_OVER_DIFF",
  ``!f d. BIGUNION (IMAGE f univ(:num)) DIFF d =
          BIGUNION (IMAGE (\i. f i DIFF d) univ(:num))``,
    rpt GEN_TAC
 >> REWRITE_TAC [EXTENSION]
 >> GEN_TAC >> EQ_TAC
 >| [ (* goal 1 (of 2) *)
      RW_TAC std_ss [IN_BIGUNION, IN_DIFF, IN_IMAGE, IN_UNIV] \\
      `x IN (f x' DIFF d)` by PROVE_TAC [IN_DIFF] \\
      Q.EXISTS_TAC `f x' DIFF d` >> art [] \\
      Q.EXISTS_TAC `x'` >> art [],
      (* goal 2 (of 2) *)
      RW_TAC std_ss [IN_BIGUNION, IN_DIFF, IN_IMAGE, IN_UNIV] >|
      [ fs [IN_DIFF] >> Q.EXISTS_TAC `f i` >> art [] \\
        Q.EXISTS_TAC `i` >> REWRITE_TAC [],
        PROVE_TAC [IN_DIFF] ] ]);

val BIGUNION_IMAGE_OVER_INTER_L = store_thm
  ("BIGUNION_IMAGE_OVER_INTER_L",
  ``!f n d. BIGUNION (IMAGE f (count n)) INTER d =
            BIGUNION (IMAGE (\i. f i INTER d) (count n))``,
    rpt GEN_TAC
 >> REWRITE_TAC [EXTENSION]
 >> GEN_TAC >> EQ_TAC
 >| [ RW_TAC std_ss [IN_BIGUNION, IN_INTER, IN_IMAGE] \\
      `x IN (f x' INTER d)` by PROVE_TAC [IN_INTER] \\
      Q.EXISTS_TAC `f x' INTER d` >> art [] \\
      Q.EXISTS_TAC `x'` >> art [],
      RW_TAC std_ss [IN_BIGUNION, IN_INTER, IN_IMAGE] >|
      [ fs [IN_INTER] >> Q.EXISTS_TAC `f i` >> art [] \\
        Q.EXISTS_TAC `i` >> art [],
        PROVE_TAC [IN_INTER] ] ]);

val BIGUNION_IMAGE_OVER_INTER_R = store_thm
  ("BIGUNION_IMAGE_OVER_INTER_R",
  ``!f n d. d INTER BIGUNION (IMAGE f (count n)) =
            BIGUNION (IMAGE (\i. d INTER f i) (count n))``,
    rpt GEN_TAC
 >> ONCE_REWRITE_TAC [INTER_COMM]
 >> REWRITE_TAC [BIGUNION_IMAGE_OVER_INTER_L]);

val BIGINTER_IMAGE_OVER_INTER_L = store_thm
  ("BIGINTER_IMAGE_OVER_INTER_L",
  ``!f n d. 0 < n ==>
           (BIGINTER (IMAGE f (count n)) INTER d =
            BIGINTER (IMAGE (\i. f i INTER d) (count n)))``,
    rpt STRIP_TAC
 >> REWRITE_TAC [EXTENSION]
 >> GEN_TAC >> EQ_TAC
 >| [ RW_TAC std_ss [IN_BIGINTER_IMAGE, IN_INTER, IN_COUNT],
      RW_TAC std_ss [IN_BIGINTER_IMAGE, IN_INTER, IN_COUNT] >> RES_TAC ]);

val BIGINTER_IMAGE_OVER_INTER_R = store_thm
  ("BIGINTER_IMAGE_OVER_INTER_R",
  ``!f n d. 0 < n ==>
           (d INTER BIGINTER (IMAGE f (count n)) =
            BIGINTER (IMAGE (\i. d INTER f i) (count n)))``,
    rpt STRIP_TAC
 >> ONCE_REWRITE_TAC [INTER_COMM]
 >> MATCH_MP_TAC BIGINTER_IMAGE_OVER_INTER_L >> art []);

(* any finite set can be decomposed into a finite sequence of sets *)
val finite_decomposition_simple = store_thm (* new *)
  ("finite_decomposition_simple",
  ``!c. FINITE c ==> ?f n. (!x. x < n ==> f x IN c) /\ (c = IMAGE f (count n))``,
    GEN_TAC
 >> REWRITE_TAC [FINITE_BIJ_COUNT_EQ]
 >> rpt STRIP_TAC
 >> rename1 `BIJ f (count n) c`
 >> Q.EXISTS_TAC `f`
 >> Q.EXISTS_TAC `n`
 >> CONJ_TAC >- (rpt STRIP_TAC >> PROVE_TAC [BIJ_DEF, INJ_DEF, IN_COUNT])
 >> PROVE_TAC [BIJ_IMAGE]);

(* any finite set can be decomposed into a finite (non-repeated) sequence of sets *)
val finite_decomposition = store_thm (* new *)
  ("finite_decomposition",
  ``!c. FINITE c ==>
        ?f n. (!x. x < n ==> f x IN c) /\ (c = IMAGE f (count n)) /\
              (!i j. i < n /\ j < n /\ i <> j ==> f i <> f j)``,
    GEN_TAC
 >> REWRITE_TAC [FINITE_BIJ_COUNT_EQ]
 >> rpt STRIP_TAC
 >> rename1 `BIJ f (count n) c`
 >> Q.EXISTS_TAC `f`
 >> Q.EXISTS_TAC `n`
 >> CONJ_TAC >- (rpt STRIP_TAC >> PROVE_TAC [BIJ_DEF, INJ_DEF, IN_COUNT])
 >> CONJ_TAC >- PROVE_TAC [BIJ_IMAGE]
 >> rpt STRIP_TAC
 >> fs [BIJ_ALT, IN_FUNSET, IN_COUNT]
 >> METIS_TAC []);

(* any finite disjoint set can be decomposed into a finite pair-wise
   disjoint sequence of sets *)
val finite_disjoint_decomposition = store_thm (* new *)
  ("finite_disjoint_decomposition",
  ``!c. FINITE c /\ disjoint c ==>
        ?f n. (!i. i < n ==> f i IN c) /\ (c = IMAGE f (count n)) /\
              (!i j. i < n /\ j < n /\ i <> j ==> f i <> f j) /\
              (!i j. i < n /\ j < n /\ i <> j ==> DISJOINT (f i) (f j))``,
    GEN_TAC
 >> REWRITE_TAC [FINITE_BIJ_COUNT_EQ]
 >> rpt STRIP_TAC
 >> rename1 `BIJ f (count n) c`
 >> Q.EXISTS_TAC `f`
 >> Q.EXISTS_TAC `n`
 >> STRONG_CONJ_TAC
 >- (rpt STRIP_TAC >> PROVE_TAC [BIJ_DEF, INJ_DEF, IN_COUNT])
 >> DISCH_TAC
 >> CONJ_TAC >- PROVE_TAC [BIJ_IMAGE]
 >> STRONG_CONJ_TAC
 >- (rpt STRIP_TAC \\
     fs [BIJ_ALT, IN_FUNSET, IN_COUNT] >> METIS_TAC [])
 >> rpt STRIP_TAC
 >> fs [disjoint_def]
 >> FIRST_X_ASSUM MATCH_MP_TAC
 >> METIS_TAC []);

val countable_disjoint_decomposition = store_thm (* new *)
  ("countable_disjoint_decomposition",
  ``!c. FINITE c /\ disjoint c ==>
        ?f n. (!i. i < n ==> f i IN c) /\ (!i. n <= i ==> (f i = {})) /\
              (c = IMAGE f (count n)) /\
              (BIGUNION c = BIGUNION (IMAGE f univ(:num))) /\
              (!i j. i < n /\ j < n /\ i <> j ==> f i <> f j) /\
              (!i j. i < n /\ j < n /\ i <> j ==> DISJOINT (f i) (f j))``,
    rpt STRIP_TAC
 >> STRIP_ASSUME_TAC
        (MATCH_MP finite_disjoint_decomposition
                  (CONJ (ASSUME ``FINITE (c :'a set set)``)
                        (ASSUME ``disjoint (c :'a set set)``)))
 >> Q.EXISTS_TAC `\i. if i < n then f i else {}`
 >> Q.EXISTS_TAC `n`
 >> BETA_TAC
 >> CONJ_TAC >- METIS_TAC []
 >> CONJ_TAC >- METIS_TAC [NOT_LESS]
 >> CONJ_TAC
 >- (art [] >> MATCH_MP_TAC IMAGE_CONG >> RW_TAC std_ss [IN_COUNT])
 >> reverse CONJ_TAC >- METIS_TAC []
 >> art [] >> KILL_TAC
 >> SIMP_TAC std_ss [Once EXTENSION, IN_BIGUNION_IMAGE, IN_COUNT, IN_UNIV]
 >> GEN_TAC >> EQ_TAC >> rpt STRIP_TAC
 >| [ Q.EXISTS_TAC `x'` >> METIS_TAC [],
      Cases_on `i < n` >- (Q.EXISTS_TAC `i` >> METIS_TAC []) \\
      fs [NOT_IN_EMPTY] ]);

(* any union of two sets can be decomposed into 3 disjoint unions *)
val UNION_TO_3_DISJOINT_UNIONS = store_thm (* new *)
  ("UNION_TO_3_DISJOINT_UNIONS",
  ``!s t. (s UNION t = (s DIFF t) UNION (s INTER t) UNION (t DIFF s)) /\
          disjoint {(s DIFF t); (s INTER t); (t DIFF s)}``,
    NTAC 2 GEN_TAC
 >> CONJ_TAC >- SET_TAC []
 >> REWRITE_TAC [disjoint_def, DISJOINT_DEF]
 >> RW_TAC std_ss [IN_INSERT]
 >> ASM_SET_TAC []);

val BIGUNION_IMAGE_BIGUNION_IMAGE_UNIV = store_thm
  ("BIGUNION_IMAGE_BIGUNION_IMAGE_UNIV",
  ``!f. BIGUNION (IMAGE (\n. BIGUNION (IMAGE (f n) univ(:num))) univ(:num)) =
        BIGUNION (IMAGE (UNCURRY f) univ(:num # num))``,
    GEN_TAC
 >> RW_TAC std_ss [EXTENSION, IN_BIGUNION_IMAGE, IN_UNIV, IN_CROSS, UNCURRY]
 >> EQ_TAC >> STRIP_TAC
 >- (Q.EXISTS_TAC `(n, x')` >> art [FST, SND])
 >> Q.EXISTS_TAC `FST x'`
 >> Q.EXISTS_TAC `SND x'` >> art []);

val BIGUNION_IMAGE_UNIV_CROSS_UNIV = store_thm
  ("BIGUNION_IMAGE_UNIV_CROSS_UNIV",
  ``!f (h :num -> num # num). BIJ h UNIV (UNIV CROSS UNIV) ==>
       (BIGUNION (IMAGE (UNCURRY f) univ(:num # num)) =
        BIGUNION (IMAGE (UNCURRY f o h) univ(:num)))``,
    rpt STRIP_TAC
 >> RW_TAC std_ss [EXTENSION, IN_BIGUNION_IMAGE, IN_UNIV, IN_CROSS, UNCURRY, o_DEF]
 >> fs [BIJ_ALT, IN_FUNSET, IN_UNIV]
 >> EQ_TAC >> STRIP_TAC
 >- (Q.PAT_X_ASSUM `!y. ?!x. y = h x` (MP_TAC o (Q.SPEC `x'`)) >> METIS_TAC [])
 >> Q.EXISTS_TAC `h x'` >> art []);


(* ------------------------------------------------------------------------- *)
(*  Three series of lemmas on bigunion-equivalent sequences of sets          *)
(* ------------------------------------------------------------------------- *)

(* 1. for any sequence of sets, there is an increasing sequence of the same bigunion. *)
val SETS_TO_INCREASING_SETS = store_thm
  ("SETS_TO_INCREASING_SETS",
  ``!f :num->'a set.
       ?g. (g 0 = f 0) /\ (!n. g n = BIGUNION (IMAGE f (count (SUC n)))) /\
           (!n. g n SUBSET g (SUC n)) /\
           (BIGUNION (IMAGE f UNIV) = BIGUNION (IMAGE g UNIV))``,
    rpt STRIP_TAC
 >> Q.EXISTS_TAC `\n. BIGUNION (IMAGE f (count (SUC n)))`
 >> BETA_TAC
 >> RW_TAC bool_ss []
 >| [ (* goal 1 (of 3) *)
      REWRITE_TAC [COUNT_SUC, COUNT_ZERO, IMAGE_SING, BIGUNION_SING],
      (* goal 2 (of 3) *)
     `count (SUC (SUC n)) = (SUC n) INSERT (count (SUC n))`
          by PROVE_TAC [COUNT_SUC] >> POP_ORW \\
      REWRITE_TAC [IMAGE_INSERT, BIGUNION_INSERT] \\
      REWRITE_TAC [SUBSET_UNION],
      (* goal 3 (of 3) *)
      MATCH_MP_TAC BIGUNION_IMAGE_COUNT_IMP_UNIV \\
      Induct_on `n` >- REWRITE_TAC [COUNT_ZERO, IMAGE_EMPTY, BIGUNION_EMPTY] \\
     `count (SUC n) = n INSERT (count n)` by PROVE_TAC [COUNT_SUC] \\
      POP_ORW >> REWRITE_TAC [IMAGE_INSERT, BIGUNION_INSERT] \\
      POP_ASSUM (REWRITE_TAC o wrap) \\
      BETA_TAC \\
      Cases_on `n = 0` >> fs [COUNT_SUC, COUNT_ZERO, IMAGE_SING, BIGUNION_SING] \\
      REWRITE_TAC [GSYM UNION_ASSOC, UNION_IDEMPOT] ]);

(* another version with `g 0 = {}` *)
val SETS_TO_INCREASING_SETS' = store_thm
  ("SETS_TO_INCREASING_SETS'",
  ``!f :num -> 'a set.
       ?g. (g 0 = {}) /\ (!n. g n = BIGUNION (IMAGE f (count n))) /\
           (!n. g n SUBSET g (SUC n)) /\
           (BIGUNION (IMAGE f UNIV) = BIGUNION (IMAGE g UNIV))``,
    rpt STRIP_TAC
 >> Q.EXISTS_TAC `\n. BIGUNION (IMAGE f (count n))`
 >> BETA_TAC
 >> RW_TAC bool_ss []
 >| [ (* goal 1 (of 3) *)
      REWRITE_TAC [COUNT_ZERO, IMAGE_EMPTY, BIGUNION_EMPTY],
      (* goal 2 (of 3) *)
     `count (SUC n) = n INSERT (count n)` by PROVE_TAC [COUNT_SUC] \\
      POP_ORW >> REWRITE_TAC [IMAGE_INSERT, BIGUNION_INSERT] \\
      REWRITE_TAC [SUBSET_UNION],
      (* goal 3 (of 3) *)
      REWRITE_TAC [EXTENSION] \\
      GEN_TAC >> SIMP_TAC std_ss [IN_BIGUNION_IMAGE, IN_UNIV, IN_COUNT] \\
      EQ_TAC >> RW_TAC std_ss [] >|
      [ Q.EXISTS_TAC `SUC x'` \\
        Q.EXISTS_TAC `x'` >> ASM_SIMP_TAC arith_ss [],
        Q.EXISTS_TAC `x'` >> art [] ] ]);

(* 2. (hard) for any sequence of sets in a space, there is a disjoint family with
      the same bigunion. This lemma is needed by DYNKIN_LEMMA *)
val SETS_TO_DISJOINT_SETS = store_thm
  ("SETS_TO_DISJOINT_SETS",
  ``!sp sts f. (!s. s IN sts ==> s SUBSET sp) /\ (!n. f n IN sts) ==>
       ?g. (g 0 = f 0) /\
           (!n. 0 < n ==> (g n = f n INTER (BIGINTER (IMAGE (\i. sp DIFF f i) (count n))))) /\
           (!i j :num. i <> j ==> DISJOINT (g i) (g j)) /\
           (BIGUNION (IMAGE f UNIV) = BIGUNION (IMAGE g UNIV))``,
    rpt STRIP_TAC
 >> Q.EXISTS_TAC `\n. if n = 0:num then f n
                      else f n INTER (BIGINTER (IMAGE (\i. sp DIFF f i) (count n)))`
 >> BETA_TAC >> SIMP_TAC arith_ss []
 >> CONJ_TAC >> RW_TAC arith_ss []
 >| [ (* goal 1 (of 4)
        `DISJOINT (f 0) (f j INTER BIGINTER (IMAGE (\i. sp DIFF f i) (count j)))` *)
      `0 IN (count j)` by PROVE_TAC [NOT_ZERO_LT_ZERO, IN_COUNT] \\
      POP_ASSUM (MP_TAC o SYM o (MATCH_MP INSERT_DELETE)) \\
      DISCH_THEN (ONCE_REWRITE_TAC o wrap) \\
      REWRITE_TAC [IMAGE_INSERT, BIGINTER_INSERT] >> BETA_TAC \\
      REWRITE_TAC [INTER_ASSOC] \\
      `f j INTER (sp DIFF f 0) = (sp DIFF f 0) INTER f j` by PROVE_TAC [INTER_COMM] \\
      POP_ASSUM (ONCE_REWRITE_TAC o wrap) \\
      REWRITE_TAC [DIFF_INTER, DISJOINT_DIFF],
      (* goal 2 (of 4),
        `DISJOINT (f i INTER BIGINTER (IMAGE (\i. sp DIFF f i) (count i))) (f 0)` *)
     `0 IN (count i)` by PROVE_TAC [NOT_ZERO_LT_ZERO, IN_COUNT] \\
      POP_ASSUM (MP_TAC o SYM o (MATCH_MP INSERT_DELETE)) \\
      DISCH_THEN (ONCE_REWRITE_TAC o wrap) \\
      REWRITE_TAC [IMAGE_INSERT, BIGINTER_INSERT] >> BETA_TAC \\
      REWRITE_TAC [INTER_ASSOC] \\
     `f i INTER (sp DIFF f 0) = (sp DIFF f 0) INTER f i` by PROVE_TAC [INTER_COMM] \\
      POP_ASSUM (ONCE_REWRITE_TAC o wrap) \\
      REWRITE_TAC [DIFF_INTER, DISJOINT_DIFF],
      (* goal 3 (of 4),
        `DISJOINT (f i INTER BIGINTER (IMAGE (\i. sp DIFF f i) (count i)))
                  (f j INTER BIGINTER (IMAGE (\i. sp DIFF f i) (count j)))` *)
      STRIP_ASSUME_TAC (Q.SPECL [`i`, `j`] LESS_LESS_CASES) >| (* 2 subgoals *)
      [ (* goal 3.1 (of 2) *)
        ONCE_REWRITE_TAC [DISJOINT_SYM] \\
        MATCH_MP_TAC DISJOINT_SUBSET \\
        Q.EXISTS_TAC `f i` >> REWRITE_TAC [INTER_SUBSET] \\
       `i IN (count j)` by PROVE_TAC [IN_COUNT] \\
        POP_ASSUM (MP_TAC o SYM o (MATCH_MP INSERT_DELETE)) \\
        DISCH_THEN (ONCE_REWRITE_TAC o wrap) \\
        REWRITE_TAC [IMAGE_INSERT, BIGINTER_INSERT] >> BETA_TAC \\
        REWRITE_TAC [INTER_ASSOC] \\
       `f j INTER (sp DIFF f i) = (sp DIFF f i) INTER f j` by PROVE_TAC [INTER_COMM] \\
        POP_ASSUM (ONCE_REWRITE_TAC o wrap) \\
        REWRITE_TAC [DIFF_INTER, DISJOINT_DIFF],
        (* goal 3.2 (of 2) *)
        MATCH_MP_TAC DISJOINT_SUBSET \\
        Q.EXISTS_TAC `f j` >> REWRITE_TAC [INTER_SUBSET] \\
       `j IN (count i)` by PROVE_TAC [IN_COUNT] \\
        POP_ASSUM (MP_TAC o SYM o (MATCH_MP INSERT_DELETE)) \\
        DISCH_THEN (ONCE_REWRITE_TAC o wrap) \\
        REWRITE_TAC [IMAGE_INSERT, BIGINTER_INSERT] >> BETA_TAC \\
        REWRITE_TAC [INTER_ASSOC] \\
       `f i INTER (sp DIFF f j) = (sp DIFF f j) INTER f i` by PROVE_TAC [INTER_COMM] \\
        POP_ASSUM (ONCE_REWRITE_TAC o wrap) \\
        REWRITE_TAC [DIFF_INTER, DISJOINT_DIFF] ],
      (* goal 4 (of 4) *)
      MATCH_MP_TAC BIGUNION_IMAGE_COUNT_IMP_UNIV \\
      Induct_on `n` >- REWRITE_TAC [COUNT_ZERO, IMAGE_EMPTY, BIGUNION_EMPTY] \\
      REWRITE_TAC [COUNT_SUC, IMAGE_INSERT, BIGUNION_INSERT] \\
      POP_ASSUM (REWRITE_TAC o wrap) >> BETA_TAC \\
      Cases_on `n = 0` >> fs [] (* now ``n <> 0`` *) \\
      REWRITE_TAC [Once UNION_COMM, INTER_OVER_UNION] \\
      GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV) empty_rewrites [UNION_COMM] \\
      Suff `BIGUNION (IMAGE f (count n)) UNION (BIGINTER (IMAGE (\i. sp DIFF f i) (count n))) = sp`
      >- (DISCH_THEN (REWRITE_TAC o wrap) \\
          REWRITE_TAC [INTER_SUBSET_EQN, UNION_SUBSET] \\
          reverse CONJ_TAC >- PROVE_TAC [] \\
          REWRITE_TAC [BIGUNION_SUBSET, IN_IMAGE] >> PROVE_TAC []) \\
      (* BIGUNION (IMAGE f (count n)) UNION BIGINTER (IMAGE (\i. sp DIFF f i) (count n)) = sp *)
     `0 < n` by PROVE_TAC [NOT_ZERO_LT_ZERO] \\
      POP_ASSUM (REWRITE_TAC o wrap o GSYM o (MATCH_MP GEN_COMPL_FINITE_UNION)) \\
      Suff `BIGUNION (IMAGE f (count n)) SUBSET sp` >- ASM_SET_TAC [] \\
      REWRITE_TAC [BIGUNION_SUBSET, IN_IMAGE] >> PROVE_TAC [] ]);

(* A specific version without sts and sp *)
val SETS_TO_DISJOINT_SETS' = store_thm
  ("SETS_TO_DISJOINT_SETS'",
  ``!f. ?g. (g 0 = f 0) /\
            (!n. 0 < n ==> (g n = f n INTER (BIGINTER (IMAGE (COMPL o f) (count n))))) /\
            (!i j :num. i <> j ==> DISJOINT (g i) (g j)) /\
            (BIGUNION (IMAGE f UNIV) = BIGUNION (IMAGE g UNIV))``,
    GEN_TAC
 >> STRIP_ASSUME_TAC (Q.SPECL [`UNIV`, `UNIV`, `f`] SETS_TO_DISJOINT_SETS)
 >> fs [SUBSET_UNIV, o_DEF, COMPL_DEF]
 >> Q.EXISTS_TAC `g` >> art []);

(* 3. (hard) for any sequence of (straightly) increasing sets, there is a disjoint
      family with the same bigunion. *)
val INCREASING_TO_DISJOINT_SETS = store_thm
  ("INCREASING_TO_DISJOINT_SETS",
  ``!f :num -> 'a set. (!n. f n SUBSET f (SUC n)) ==>
       ?g. (g 0 = f 0) /\ (!n. 0 < n ==> (g n = f n DIFF f (PRE n))) /\
           (!i j :num. i <> j ==> DISJOINT (g i) (g j)) /\
           (BIGUNION (IMAGE f UNIV) = BIGUNION (IMAGE g UNIV))``,
    rpt STRIP_TAC
 >> Q.EXISTS_TAC `\n. if n = (0 :num) then f n else f n DIFF f (PRE n)`
 >> BETA_TAC
 (* preliminaries *)
 >> Know `!n. 0 < n ==> f 0 SUBSET (f n)`
 >- (Induct_on `n` >- RW_TAC arith_ss [] \\
     RW_TAC arith_ss [] \\
     Cases_on `n = 0` >- art [] \\
     IMP_RES_TAC NOT_ZERO_LT_ZERO >> RES_TAC \\
     MATCH_MP_TAC SUBSET_TRANS >> Q.EXISTS_TAC `f n` >> art [])
 >> DISCH_TAC
 >> Know `!n. 0 < n ==> f 0 SUBSET (f (PRE n))`
 >- (Induct_on `n` >- RW_TAC arith_ss [] \\
     RW_TAC arith_ss [] \\
     Cases_on `n = 0` >- art [SUBSET_REFL] \\
     IMP_RES_TAC NOT_ZERO_LT_ZERO >> RES_TAC)
 >> DISCH_TAC
 >> Know `!i j. i < j ==> f (SUC i) SUBSET (f j)`
 >- (GEN_TAC >> Induct_on `j` >- RW_TAC arith_ss [] \\
     STRIP_TAC \\
     fs [GSYM LESS_EQ_IFF_LESS_SUC, LESS_OR_EQ] \\
     MATCH_MP_TAC SUBSET_TRANS >> Q.EXISTS_TAC `f j` \\
     CONJ_TAC >- RES_TAC >> art [])
 >> DISCH_TAC
 >> Know `!n. 0 < n ==> f (PRE n) SUBSET f n`
 >- (rpt STRIP_TAC \\
     Q.PAT_X_ASSUM `!n. f n SUBSET f (SUC n)` (STRIP_ASSUME_TAC o (Q.SPEC `PRE n`)) \\
     PROVE_TAC [SUC_PRE])
 >> DISCH_TAC
 >> Know `!i j. i < j ==> f i SUBSET f (PRE j)`
 >- (GEN_TAC >> Induct_on `j` >- RW_TAC arith_ss [] \\
     STRIP_TAC \\
     fs [GSYM LESS_EQ_IFF_LESS_SUC, LESS_OR_EQ] \\
     MATCH_MP_TAC SUBSET_TRANS >> Q.EXISTS_TAC `f (PRE j)` \\
     CONJ_TAC >- RES_TAC \\
     Cases_on `j = 0` >- (RW_TAC arith_ss [SUBSET_REFL]) \\
     IMP_RES_TAC NOT_ZERO_LT_ZERO >> RES_TAC)
 >> DISCH_TAC
 >> RW_TAC arith_ss []
 >| [ (* goal 1 (of 4): DISJOINT (f 0) (f (SUC j) DIFF f j) *)
      MATCH_MP_TAC SUBSET_DIFF_DISJOINT \\
      Q.EXISTS_TAC `f j` \\
      IMP_RES_TAC NOT_ZERO_LT_ZERO \\
     `f j DIFF (f j DIFF f (PRE j)) = f (PRE j)`
          by PROVE_TAC [DIFF_DIFF_SUBSET] >> POP_ORW >> RES_TAC,
      (* goal 2 (of 4): DISJOINT (f (SUC i) DIFF f i) (f 0) *)
      ONCE_REWRITE_TAC [DISJOINT_SYM] \\
      MATCH_MP_TAC SUBSET_DIFF_DISJOINT \\
      Q.EXISTS_TAC `f i` \\
      IMP_RES_TAC NOT_ZERO_LT_ZERO \\
     `f i DIFF (f i DIFF f (PRE i)) = f (PRE i)`
          by PROVE_TAC [DIFF_DIFF_SUBSET] >> POP_ORW \\
      IMP_RES_TAC NOT_ZERO_LT_ZERO >> RES_TAC,
      (* goal 3 (of 4): DISJOINT (f (SUC i) DIFF f i) (f (SUC j) DIFF f j) *)
      STRIP_ASSUME_TAC (Q.SPECL [`i`, `j`] LESS_LESS_CASES) >| (* 2 subgoals *)
      [ (* goal 3.1 (of 2) *)
        ONCE_REWRITE_TAC [DISJOINT_SYM] \\
        MATCH_MP_TAC DISJOINT_SUBSET \\
        Q.EXISTS_TAC `f i` >> REWRITE_TAC [DIFF_SUBSET] \\
        ONCE_REWRITE_TAC [DISJOINT_SYM] \\
        MATCH_MP_TAC SUBSET_DIFF_DISJOINT \\
        Q.EXISTS_TAC `f j` \\
        IMP_RES_TAC NOT_ZERO_LT_ZERO \\
       `f j DIFF (f j DIFF f (PRE j)) = f (PRE j)`
          by PROVE_TAC [DIFF_DIFF_SUBSET] >> POP_ORW >> RES_TAC,
        (* goal 3.2 (of 2) *)
        MATCH_MP_TAC DISJOINT_SUBSET \\
        Q.EXISTS_TAC `f j` >> REWRITE_TAC [DIFF_SUBSET] \\
        ONCE_REWRITE_TAC [DISJOINT_SYM] \\
        MATCH_MP_TAC SUBSET_DIFF_DISJOINT \\
        Q.EXISTS_TAC `f i` \\
        IMP_RES_TAC NOT_ZERO_LT_ZERO \\
       `f i DIFF (f i DIFF f (PRE i)) = f (PRE i)`
          by PROVE_TAC [DIFF_DIFF_SUBSET] >> POP_ORW >> RES_TAC ],
      (* goal 4 (of 4): BIGUNION (IMAGE f univ(:num)) = ... *)
      MATCH_MP_TAC BIGUNION_IMAGE_COUNT_IMP_UNIV \\
      Induct_on `n` >- REWRITE_TAC [COUNT_ZERO, IMAGE_EMPTY, BIGUNION_EMPTY] \\
      REWRITE_TAC [COUNT_SUC, IMAGE_INSERT, BIGUNION_INSERT] \\
      POP_ASSUM (REWRITE_TAC o wrap) >> BETA_TAC \\
      Cases_on `n = 0` >> fs [] (* now ``n <> 0`` *) \\
      RW_TAC arith_ss [EXTENSION, IN_UNION, IN_BIGUNION_IMAGE, IN_COUNT, IN_DIFF] \\
      EQ_TAC >> rpt STRIP_TAC >| (* 4 subgoals *)
      [ DISJ1_TAC >> art [],
        DISJ2_TAC >> Q.EXISTS_TAC `x'` >> art [],
        Cases_on `x IN f (PRE n)` >- (DISJ2_TAC >> Q.EXISTS_TAC `PRE n` \\
                                      ASM_SIMP_TAC arith_ss []) \\
        DISJ1_TAC >> art [],
        DISJ2_TAC >> Q.EXISTS_TAC `x'` >> art [] ] ]);

(* Surprisingly, this variant of INCREASING_TO_DISJOINT_SETS cannot be
   easily proved without using the non-trivial SETS_TO_DISJOINT_SETS *)
val INCREASING_TO_DISJOINT_SETS' = store_thm
  ("INCREASING_TO_DISJOINT_SETS'",
  ``!f :num -> 'a set. (f 0 = {}) /\ (!n. f n SUBSET f (SUC n)) ==>
       ?g. (!n. g n = f (SUC n) DIFF f n) /\
           (!i j :num. i <> j ==> DISJOINT (g i) (g j)) /\
           (BIGUNION (IMAGE f UNIV) = BIGUNION (IMAGE g UNIV))``,
    rpt STRIP_TAC
 >> Q.EXISTS_TAC `\n. f (SUC n) DIFF f n`
 >> BETA_TAC
 (* preliminaries *)
 >> Know `!i j. i < j ==> f i SUBSET f j`
 >- (GEN_TAC >> Induct_on `j` >- RW_TAC arith_ss [] \\
     STRIP_TAC \\
     MATCH_MP_TAC SUBSET_TRANS >> Q.EXISTS_TAC `f j` >> art [] \\
     fs [GSYM LESS_EQ_IFF_LESS_SUC, LESS_OR_EQ])
 >> DISCH_TAC
 >> Know `!i j. i < j ==> f (SUC i) SUBSET f j`
 >- (GEN_TAC >> Induct_on `j` >- RW_TAC arith_ss [] \\
     STRIP_TAC \\
     Cases_on `i = j` >- PROVE_TAC [SUBSET_REFL] \\
     MATCH_MP_TAC SUBSET_TRANS >> Q.EXISTS_TAC `f j` >> art [] \\
     fs [GSYM LESS_EQ_IFF_LESS_SUC, LESS_OR_EQ])
 >> DISCH_TAC
 >> RW_TAC arith_ss [] (* 2 subgoals *)
 >| [ (* goal 1 (of 2): DISJOINT (f (SUC i) DIFF f i) (f (SUC j) DIFF f j) *)
      STRIP_ASSUME_TAC (Q.SPECL [`i`, `j`] LESS_LESS_CASES) >| (* 2 subgoals *)
      [ (* goal 1.1 (of 2) *)
        ONCE_REWRITE_TAC [DISJOINT_SYM] \\
        MATCH_MP_TAC DISJOINT_SUBSET \\
        Q.EXISTS_TAC `f (SUC i)` >> REWRITE_TAC [DIFF_SUBSET] \\
        ONCE_REWRITE_TAC [DISJOINT_SYM] \\
        MATCH_MP_TAC SUBSET_DIFF_DISJOINT \\
        Q.EXISTS_TAC `f (SUC j)` \\
        `f (SUC j) DIFF (f (SUC j) DIFF f j) = f j`
          by PROVE_TAC [DIFF_DIFF_SUBSET] >> POP_ORW >> RES_TAC,
        (* goal 1.2 (of 2) *)
        MATCH_MP_TAC DISJOINT_SUBSET \\
        Q.EXISTS_TAC `f (SUC j)` >> REWRITE_TAC [DIFF_SUBSET] \\
        ONCE_REWRITE_TAC [DISJOINT_SYM] \\
        MATCH_MP_TAC SUBSET_DIFF_DISJOINT \\
        Q.EXISTS_TAC `f (SUC i)` \\
       `f (SUC i) DIFF (f (SUC i) DIFF f i) = f i`
          by PROVE_TAC [DIFF_DIFF_SUBSET] >> POP_ORW >> RES_TAC ],
      (* goal 2 (of 2): BIGUNION (IMAGE f univ(:num)) = ... *)
      STRIP_ASSUME_TAC (Q.SPEC `f` SETS_TO_DISJOINT_SETS') >> art [] \\
      RW_TAC std_ss [EXTENSION, IN_BIGUNION_IMAGE, IN_UNIV, IN_DIFF] \\
      EQ_TAC >> rpt STRIP_TAC >| (* 2 subgoals *)
      [ (* goal 2.1 (of 2) *)
        Cases_on `x' = 0` >- PROVE_TAC [NOT_IN_EMPTY] \\
        IMP_RES_TAC NOT_ZERO_LT_ZERO \\
        Q.EXISTS_TAC `PRE x'` \\
       `SUC (PRE x') = x'` by PROVE_TAC [SUC_PRE] >> POP_ORW \\
        Q.PAT_X_ASSUM `x IN g x'` MP_TAC \\
        Q.PAT_X_ASSUM `!n. 0 < n ==> X`
            (fn th => REWRITE_TAC [MATCH_MP th (ASSUME ``0:num < x'``)]) \\
        RW_TAC std_ss [IN_INTER, IN_BIGINTER_IMAGE, IN_COUNT, o_DEF, IN_COMPL] \\
        FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss [],
        (* goal 2.2 (of 2) *)
        Q.EXISTS_TAC `SUC n` \\
       `0 < SUC n` by REWRITE_TAC [prim_recTheory.LESS_0] \\
        Q.PAT_X_ASSUM `!n. 0 < n ==> X`
            (fn th => REWRITE_TAC [MATCH_MP th (ASSUME ``0:num < SUC n``)]) \\
        RW_TAC std_ss [IN_INTER, IN_BIGINTER_IMAGE, IN_COUNT, o_DEF, IN_COMPL] \\
        fs [GSYM LESS_EQ_IFF_LESS_SUC, LESS_OR_EQ] \\
        CCONTR_TAC >> fs [] \\
       `x IN f n` by PROVE_TAC [SUBSET_DEF] ] ]);

(* ------------------------------------------------------------------------- *)
(* Other types of disjointness definitions (from Concordia HVG)              *)
(* ------------------------------------------------------------------------- *)

(* This is not more general than disjoint_def *)
val disjoint_family_on = new_definition ("disjoint_family_on",
  ``disjoint_family_on a s =
      (!m n. m IN s /\ n IN s /\ (m <> n) ==> (a m INTER a n = {}))``);

val disjoint_family = new_definition ("disjoint_family",
  ``disjoint_family A = disjoint_family_on A UNIV``);

(* This is the way to convert a family of sets into a disjoint family *)
(* of sets, cf. SETS_TO_DISJOINT_SETS -- Chun Tian *)
val disjointed = new_definition ("disjointed",
  ``!A n. disjointed A n =
          A n DIFF BIGUNION {A i | i IN {x:num | 0 <= x /\ x < n}}``);

val disjointed_subset = store_thm ("disjointed_subset",
  ``!A n. disjointed A n SUBSET A n``,
  RW_TAC std_ss [disjointed] THEN ASM_SET_TAC []);

val disjoint_family_disjoint = store_thm ("disjoint_family_disjoint",
  ``!A. disjoint_family (disjointed A)``,
  SIMP_TAC std_ss [disjoint_family, disjoint_family_on, IN_UNIV] THEN
  RW_TAC std_ss [disjointed, EXTENSION, GSPECIFICATION, IN_INTER] THEN
  SIMP_TAC std_ss [NOT_IN_EMPTY, IN_DIFF, IN_BIGUNION] THEN
  ASM_CASES_TAC ``(x NOTIN A (m:num) \/ ?s. x IN s /\ s IN {A i | i < m})`` THEN
  ASM_REWRITE_TAC [] THEN RW_TAC std_ss [] THEN
  ASM_CASES_TAC ``x NOTIN A (n:num)`` THEN FULL_SIMP_TAC std_ss [] THEN
  FULL_SIMP_TAC std_ss [GSPECIFICATION] THEN
  ASM_CASES_TAC ``m < n:num`` THENL [METIS_TAC [], ALL_TAC] THEN
  `n < m:num` by ASM_SIMP_TAC arith_ss [] THEN METIS_TAC []);

val finite_UN_disjointed_eq = prove (
  ``!A n. BIGUNION {disjointed A i | i IN {x | 0 <= x /\ x < n}} =
          BIGUNION {A i | i IN {x | 0 <= x /\ x < n}}``,
  GEN_TAC THEN INDUCT_TAC THENL
  [FULL_SIMP_TAC real_ss [GSPECIFICATION] THEN SET_TAC [], ALL_TAC] THEN
  FULL_SIMP_TAC real_ss [GSPECIFICATION] THEN
  GEN_REWR_TAC (LAND_CONV o ONCE_DEPTH_CONV)
   [ARITH_PROVE ``i < SUC n <=> i < n \/ (i = n)``] THEN
  REWRITE_TAC [SET_RULE ``BIGUNION {(A:num->'a->bool) i | i < n \/ (i = n)} =
                          BIGUNION {A i | i < n} UNION A n``] THEN
  ASM_REWRITE_TAC [disjointed] THEN SIMP_TAC std_ss [GSPECIFICATION] THEN
  SIMP_TAC std_ss [UNION_DEF] THEN
  REWRITE_TAC [ARITH_PROVE ``i < SUC n <=> i < n \/ (i = n)``] THEN
  REWRITE_TAC [SET_RULE ``BIGUNION {(A:num->'a->bool) i | i < n \/ (i = n)} =
                          BIGUNION {A i | i < n} UNION A n``] THEN
  SET_TAC []);

val atLeast0LessThan = prove (
  ``{x:num | 0 <= x /\ x < n} = {x | x < n}``,
  SIMP_TAC arith_ss [EXTENSION, GSPECIFICATION]);

val UN_UN_finite_eq = prove (
  ``!A.
     BIGUNION {BIGUNION {A i | i IN {x | 0 <= x /\ x < n}} | n IN univ(:num)} =
     BIGUNION {A n | n IN UNIV}``,
  SIMP_TAC std_ss [atLeast0LessThan] THEN
  RW_TAC std_ss [EXTENSION, GSPECIFICATION, IN_BIGUNION, IN_UNIV] THEN
  EQ_TAC THEN RW_TAC std_ss [] THENL
  [POP_ASSUM (MP_TAC o Q.SPEC `x`) THEN ASM_REWRITE_TAC [] THEN
   RW_TAC std_ss [] THEN METIS_TAC [], ALL_TAC] THEN
  Q.EXISTS_TAC `BIGUNION {A i | i IN {x | 0 <= x /\ x < SUC n}}` THEN
  RW_TAC std_ss [EXTENSION, GSPECIFICATION, IN_BIGUNION, IN_UNIV] THENL
  [ALL_TAC, METIS_TAC []] THEN Q.EXISTS_TAC `A n` THEN
  FULL_SIMP_TAC std_ss [] THEN Q.EXISTS_TAC `n` THEN
  SIMP_TAC arith_ss []);

val UN_finite_subset = prove (
  ``!A C. (!n. BIGUNION {A i | i IN {x | 0 <= x /\ x < n}} SUBSET C) ==>
               BIGUNION {A n | n IN univ(:num)} SUBSET C``,
  RW_TAC std_ss [] THEN ONCE_REWRITE_TAC [GSYM UN_UN_finite_eq] THEN
  FULL_SIMP_TAC std_ss [SUBSET_DEF] THEN RW_TAC std_ss [] THEN
  FIRST_X_ASSUM MATCH_MP_TAC THEN
  FULL_SIMP_TAC std_ss [EXTENSION, GSPECIFICATION, IN_BIGUNION, IN_UNIV] THEN
  POP_ASSUM (MP_TAC o Q.SPEC `x`) THEN ASM_REWRITE_TAC [] THEN STRIP_TAC THEN
  Q.EXISTS_TAC `n` THEN Q.EXISTS_TAC `s'` THEN METIS_TAC []);

val UN_finite2_subset = prove (
  ``!A B n k.
    (!n. BIGUNION {A i | i IN {x | 0 <= x /\ x < n}} SUBSET
         BIGUNION {B i | i IN {x | 0 <= x /\ x < n + k}}) ==>
         BIGUNION {A n | n IN univ(:num)} SUBSET BIGUNION {B n | n IN univ(:num)}``,
  RW_TAC std_ss [] THEN MATCH_MP_TAC UN_finite_subset THEN
  ONCE_REWRITE_TAC [GSYM UN_UN_finite_eq] THEN
  FULL_SIMP_TAC std_ss [SUBSET_DEF, IN_BIGUNION, GSPECIFICATION, IN_UNIV] THEN
  RW_TAC std_ss [] THEN FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n`,`x`]) THEN
  Q_TAC SUFF_TAC `(?s. x IN s /\ ?i. (s = A i) /\ i < n)` THENL
  [ALL_TAC, METIS_TAC []] THEN DISCH_TAC THEN ASM_REWRITE_TAC [] THEN
  STRIP_TAC THEN Q.EXISTS_TAC `BIGUNION {B i | i < n + k}` THEN
  CONJ_TAC THENL [ALL_TAC, METIS_TAC []] THEN
  SIMP_TAC std_ss [IN_BIGUNION, GSPECIFICATION] THEN METIS_TAC []);

val UN_finite2_eq = prove (
  ``!A B k.
    (!n. BIGUNION {A i | i IN {x | 0 <= x /\ x < n}} =
         BIGUNION {B i | i IN {x | 0 <= x /\ x < n + k}}) ==>
    (BIGUNION {A n | n IN univ(:num)} = BIGUNION {B n | n IN univ(:num)})``,
  RW_TAC std_ss [] THEN MATCH_MP_TAC SUBSET_ANTISYM THEN CONJ_TAC THENL
  [MATCH_MP_TAC  UN_finite2_subset THEN REWRITE_TAC [atLeast0LessThan] THEN
   METIS_TAC [SUBSET_REFL], ALL_TAC] THEN
  FULL_SIMP_TAC std_ss [SUBSET_DEF, IN_BIGUNION, IN_UNIV, GSPECIFICATION] THEN
  RW_TAC std_ss [] THEN FIRST_X_ASSUM (MP_TAC o Q.SPEC `SUC n`) THEN
  GEN_REWR_TAC LAND_CONV [EXTENSION] THEN
  DISCH_THEN (MP_TAC o Q.SPEC `x`) THEN
  SIMP_TAC std_ss [SUBSET_DEF, IN_BIGUNION, IN_UNIV, GSPECIFICATION] THEN
  Q_TAC SUFF_TAC `?s. x IN s /\ ?i. (s = B i) /\ i < SUC n + k` THENL
  [ALL_TAC,
   Q.EXISTS_TAC `B n` THEN ASM_REWRITE_TAC [] THEN
   Q.EXISTS_TAC `n` THEN SIMP_TAC arith_ss []] THEN
  DISCH_TAC THEN ASM_REWRITE_TAC [] THEN RW_TAC std_ss [] THEN
  METIS_TAC []);

Theorem BIGUNION_disjointed : (* was: UN_disjointed_eq *)
    !A. BIGUNION {disjointed A i | i IN UNIV} = BIGUNION {A i | i IN UNIV}
Proof
  GEN_TAC THEN MATCH_MP_TAC UN_finite2_eq THEN
  Q.EXISTS_TAC `0` THEN RW_TAC arith_ss [GSPECIFICATION] THEN
  ASSUME_TAC finite_UN_disjointed_eq THEN
  FULL_SIMP_TAC arith_ss [GSPECIFICATION]
QED

(******************************************************************************)
(*  liminf and limsup [1, p.74] [2, p.76] - the set-theoretic version         *)
(******************************************************************************)

val set_ss' = arith_ss ++ PRED_SET_ss;

(* This lemma is provided by Konrad Slind *)
val lemma = Q.prove
  (`!P. ~(?N. INFINITE N /\ !n. N n ==> P n) <=> !N. N SUBSET P ==> FINITE N`,
  rw_tac set_ss' [EQ_IMP_THM, SUBSET_DEF, IN_DEF]
  >- (`FINITE P \/ ?n. P n /\ ~P n` by metis_tac []
       >> imp_res_tac SUBSET_FINITE
       >> full_simp_tac std_ss [SUBSET_DEF, IN_DEF])
  >- metis_tac[]);

(* "From this and the original assumption, you should be able to get that P is finite,
    so has a maximum element." -- Konrad Slind, Feb 17, 2019.
 *)
Theorem infinitely_often_lemma :
    !P. ~(?N. INFINITE N /\ !n:num. n IN N ==> P n) <=> ?m. !n. m <= n ==> ~(P n)
Proof
    Q.X_GEN_TAC ‘P’
 >> `!N. (!n. n IN N ==> P n) <=> !n. N n ==> P n` by PROVE_TAC [SUBSET_DEF, IN_APP]
 >> POP_ORW
 >> REWRITE_TAC [lemma]
 >> reverse EQ_TAC >> rpt STRIP_TAC
 >| [ (* goal 1 (of 2) *)
      Suff ‘FINITE P’ >- PROVE_TAC [SUBSET_FINITE_I] \\
      Know ‘P SUBSET (count m)’
      >- (REWRITE_TAC [count_def, GSYM NOT_LESS_EQUAL] \\
          ASM_SET_TAC []) \\
      DISCH_TAC \\
      MATCH_MP_TAC SUBSET_FINITE_I \\
      Q.EXISTS_TAC ‘count m’ >> art [FINITE_COUNT],
      (* goal 2 (of 2) *)
      POP_ASSUM (MP_TAC o (Q.SPEC `P`)) \\
      RW_TAC std_ss [SUBSET_REFL] \\
      Cases_on ‘P = {}’ >- rw [] \\
      MP_TAC (FINITE_is_measure_maximal |> Q.GEN ‘m’
                                        |> INST_TYPE [“:'a” |-> “:num”]
                                        |> Q.SPECL [‘I’, ‘P’]) \\
      rw [is_measure_maximal_def, IN_APP] \\
      Q.EXISTS_TAC ‘SUC x’ >> rw [] \\
      CCONTR_TAC >> fs [] \\
     ‘x < n’ by rw [] \\
     ‘n <= x’ by PROVE_TAC [] \\
      METIS_TAC [LESS_EQ_ANTISYM] ]
QED

(* This proof is provided by Konrad Slind. *)
Theorem infinity_bound_lemma :
    !N m. INFINITE N ==> ?n:num. m <= n /\ n IN N
Proof
    spose_not_then strip_assume_tac
 >> `FINITE (count m)` by metis_tac [FINITE_COUNT]
 >> `N SUBSET (count m)`
      by (rw_tac set_ss' [SUBSET_DEF]
           >> `~(m <= x)` by metis_tac []
           >> decide_tac)
 >> metis_tac [SUBSET_FINITE]
QED

(* TODO: restate this lemma by real_topologyTheory.from *)
val tail_not_empty = store_thm
  ("tail_not_empty", ``!A m:num. {A n | m <= n} <> {}``,
    RW_TAC std_ss [Once EXTENSION, NOT_IN_EMPTY, GSPECIFICATION]
 >> Q.EXISTS_TAC `(SUC m)` >> RW_TAC arith_ss []);

val tail_countable = store_thm
  ("tail_countable", ``!A m:num. countable {A n | m <= n}``,
    rpt GEN_TAC
 >> Suff `{A n | m <= n} = IMAGE A {n | m <= n}`
 >- PROVE_TAC [COUNTABLE_IMAGE_NUM]
 >> RW_TAC std_ss [EXTENSION, IN_IMAGE, GSPECIFICATION]);

val set_limsup_def = Define (* "infinitely often" *)
   `set_limsup (E :num -> 'a set) =
      BIGINTER (IMAGE (\m. BIGUNION {E n | m <= n}) UNIV)`;

val set_liminf_def = Define (* "almost always" *)
   `set_liminf (E :num -> 'a set) =
      BIGUNION (IMAGE (\m. BIGINTER {E n | m <= n}) UNIV)`;

val _ = overload_on ("limsup", ``set_limsup``);
val _ = overload_on ("liminf", ``set_liminf``);

(* alternative definition of `limsup` using `from` *)
val set_limsup_alt = store_thm
  ("set_limsup_alt",
  ``!E. set_limsup E = BIGINTER (IMAGE (\n. BIGUNION (IMAGE E (from n))) UNIV)``,
    GEN_TAC >> REWRITE_TAC [set_limsup_def]
 >> Suff `!m. BIGUNION (IMAGE E (from m)) = BIGUNION {E n | m <= n}`
 >- (Rewr' >> REWRITE_TAC [])
 >> RW_TAC std_ss [Once EXTENSION, IN_BIGUNION_IMAGE, IN_BIGUNION, GSPECIFICATION, from_def]
 >> EQ_TAC >> rpt STRIP_TAC
 >- (Q.EXISTS_TAC `E x'` >> art [] \\
     Q.EXISTS_TAC `x'` >> art [])
 >> Q.EXISTS_TAC `n` >> PROVE_TAC []);

Theorem LIMSUP_COMPL : (* was: liminf_limsup *)
    !(E :num -> 'a set). COMPL (liminf E) = limsup (COMPL o E)
Proof
    RW_TAC std_ss [set_limsup_def, set_liminf_def]
 >> SIMP_TAC std_ss [COMPL_BIGUNION_IMAGE, o_DEF]
 >> Suff `!m. COMPL (BIGINTER {E n | m <= n}) = BIGUNION {COMPL (E n) | m <= n}` >- Rewr
 >> GEN_TAC >> REWRITE_TAC [COMPL_BIGINTER]
 >> Suff `IMAGE COMPL {E n | m <= n} = {COMPL (E n) | m <= n}` >- Rewr
 >> SIMP_TAC std_ss [IMAGE_DEF, IN_COMPL, Once GSPECIFICATION]
 >> RW_TAC std_ss [Once EXTENSION, GSPECIFICATION, IN_COMPL]
 >> EQ_TAC >> rpt STRIP_TAC
 >- (fs [COMPL_COMPL] >> Q.EXISTS_TAC `n` >> art [])
 >> fs []
 >> Q.EXISTS_TAC `E n` >> art []
 >> Q.EXISTS_TAC `n` >> art []
QED

Theorem LIMSUP_DIFF : (* was: liminf_limsup_sp *)
    !sp E. (!n. E n SUBSET sp) ==> (sp DIFF (liminf E) = limsup (\n. sp DIFF (E n)))
Proof
    RW_TAC std_ss [set_limsup_def, set_liminf_def]
 >> Q.ABBREV_TAC `f = (\m. BIGINTER {E n | m <= n})`
 >> Know `!m. f m SUBSET sp`
 >- (GEN_TAC >> Q.UNABBREV_TAC `f` >> BETA_TAC \\
     RW_TAC std_ss [SUBSET_DEF, IN_BIGINTER, GSPECIFICATION] \\
     fs [SUBSET_DEF] >> LAST_X_ASSUM MATCH_MP_TAC \\
     Q.EXISTS_TAC `SUC m` \\
     POP_ASSUM (STRIP_ASSUME_TAC o (Q.SPEC `E (SUC m)`)) \\
     POP_ASSUM MATCH_MP_TAC \\
     Q.EXISTS_TAC `SUC m` >> RW_TAC arith_ss [])
 >> DISCH_THEN (REWRITE_TAC o wrap o (MATCH_MP GEN_COMPL_BIGUNION_IMAGE))
 >> Suff `!m. sp DIFF f m = BIGUNION {sp DIFF E n | m <= n}` >- Rewr
 >> GEN_TAC >> Q.UNABBREV_TAC `f` >> BETA_TAC
 >> Know `!x. x IN {E n | m <= n} ==> x SUBSET sp`
 >- (RW_TAC std_ss [GSPECIFICATION] >> art [])
 >> DISCH_THEN (REWRITE_TAC o wrap o (MATCH_MP GEN_COMPL_BIGINTER))
 >> Suff `(IMAGE (\x. sp DIFF x) {E n | m <= n}) = {sp DIFF E n | m <= n}` >- Rewr
 >> RW_TAC std_ss [Once EXTENSION, IMAGE_DEF, IN_DIFF, GSPECIFICATION]
 >> EQ_TAC >> rpt STRIP_TAC
 >- (Q.EXISTS_TAC `n` >> METIS_TAC [])
 >> Q.EXISTS_TAC `E n` >> art []
 >> Q.EXISTS_TAC `n` >> art []
QED

(* A point belongs to `limsup E` if and only if it belongs to infinitely
   many terms of the sequence E. [2, p.76]
 *)
Theorem IN_LIMSUP :
    !A x. x IN limsup A <=> ?N. INFINITE N /\ !n. n IN N ==> x IN (A n)
Proof
    rpt GEN_TAC >> EQ_TAC
 >> RW_TAC std_ss [set_limsup_def, IN_BIGINTER_IMAGE, IN_UNIV]
 >| [ (* goal 1 (of 2) *)
      Q.ABBREV_TAC `P = \n. x IN (A n)` \\
     `!n. x IN (A n) <=> P n` by PROVE_TAC [] >> POP_ORW \\
      CCONTR_TAC \\
     `?m. !n. m <= n ==> ~(P n)` by PROVE_TAC [infinitely_often_lemma] \\
      Q.UNABBREV_TAC `P` >> FULL_SIMP_TAC bool_ss [] \\
      Know `x NOTIN BIGUNION {A n | m <= n}`
      >- (SIMP_TAC std_ss [IN_BIGUNION, GSPECIFICATION] \\
          CCONTR_TAC >> FULL_SIMP_TAC bool_ss [] >> METIS_TAC []) \\
      DISCH_TAC >> METIS_TAC [],
      (* goal 2 (of 2) *)
      SIMP_TAC std_ss [IN_BIGUNION, GSPECIFICATION] \\
      IMP_RES_TAC infinity_bound_lemma \\
      POP_ASSUM (STRIP_ASSUME_TAC o (Q.SPEC `m`)) \\
      Q.EXISTS_TAC `A n` >> CONJ_TAC >- PROVE_TAC [] \\
      Q.EXISTS_TAC `n` >> art [] ]
QED

(* A point belongs to `liminf E` if and only if it belongs to all terms
   of the sequence from a certain term on. [2, p.76]
 *)
Theorem IN_LIMINF :
    !A x. x IN liminf A <=> ?m. !n. m <= n ==> x IN (A n)
Proof
    rpt GEN_TAC
 >> ASSUME_TAC (SIMP_RULE std_ss [GSYM LIMSUP_COMPL, IN_COMPL, o_DEF]
                                 (Q.SPECL [`COMPL o A`, `x`] IN_LIMSUP))
 >> `x IN liminf A <=> ~(?N. INFINITE N /\ !n. n IN N ==> x NOTIN A n)` by PROVE_TAC []
 >> fs [infinitely_often_lemma]
QED

(* This version of LIMSUP_MONO is used in large_numberTheory.SLLN_IID_diverge *)
Theorem LIMSUP_MONO_STRONGER :
    !A B. (?d. !y n. y IN A n ==> ?m. n - d <= m /\ y IN B m) ==> limsup A SUBSET limsup B
Proof
    RW_TAC std_ss [set_limsup_alt]
 >> RW_TAC std_ss [IN_BIGINTER_IMAGE, IN_BIGUNION_IMAGE, SUBSET_DEF, IN_UNIV, IN_FROM]
 >> POP_ASSUM ((Q.X_CHOOSE_THEN ‘N’ STRIP_ASSUME_TAC) o (Q.SPEC ‘d + n’))
 >> Q.PAT_X_ASSUM ‘!y n. y IN A n ==> _’ (MP_TAC o (Q.SPECL [‘x’, ‘N’]))
 >> RW_TAC std_ss []
 >> Q.EXISTS_TAC ‘m’
 >> FULL_SIMP_TAC arith_ss []
QED

Theorem LIMSUP_MONO_STRONG :
    !A B. (!y n. y IN A n ==> ?m. n <= m /\ y IN B m) ==> limsup A SUBSET limsup B
Proof
    rpt STRIP_TAC
 >> MATCH_MP_TAC LIMSUP_MONO_STRONGER
 >> Q.EXISTS_TAC ‘0’ >> rw []
QED

Theorem LIMSUP_MONO_WEAK :
    !A B. (!n. A n SUBSET B n) ==> limsup A SUBSET limsup B
Proof
    rpt STRIP_TAC
 >> MATCH_MP_TAC LIMSUP_MONO_STRONG
 >> qx_genl_tac [‘x’, ‘n’]
 >> DISCH_TAC
 >> FULL_SIMP_TAC std_ss [SUBSET_DEF]
 >> Q.EXISTS_TAC ‘n’ >> fs []
QED

(* ================================================================= *)
(*   Rational Numbers as a subset of real numbers                    *)
(* ================================================================= *)

(* cf. extrealTheory.Q_set *)
Definition real_rat_set_def :
    real_rat_set = {x:real | ?a b. (x = (&a/(&b))) /\ (0:real < &b)} UNION
                   {x:real | ?a b. (x = -(&a/(&b))) /\ (0:real < &b)}
End

Overload q_set = “real_rat_set”

Theorem q_set_def = real_rat_set_def

Theorem QSET_COUNTABLE :
    countable q_set
Proof
  RW_TAC std_ss [q_set_def] THEN
  MATCH_MP_TAC union_countable THEN CONJ_TAC THENL
  [RW_TAC std_ss [COUNTABLE_ALT] THEN
   MP_TAC NUM_2D_BIJ_NZ_INV THEN RW_TAC std_ss [] THEN
   Q.EXISTS_TAC `(\(a,b). &a/(&b)) o f` THEN RW_TAC std_ss [GSPECIFICATION] THEN
   FULL_SIMP_TAC std_ss [BIJ_DEF,INJ_DEF,SURJ_DEF,IN_UNIV] THEN
   PAT_X_ASSUM ``!x. x IN P ==> Q x y`` (MP_TAC o Q.SPEC `(&a,&b)`) THEN
   RW_TAC std_ss [] THEN
   FULL_SIMP_TAC real_ss [IN_CROSS,IN_UNIV,IN_SING,DIFF_DEF,
                          GSPECIFICATION,GSYM REAL_LT_NZ] THEN
   `?y. f y = (a,b)` by METIS_TAC [] THEN
   Q.EXISTS_TAC `y` THEN RW_TAC real_ss [], ALL_TAC] THEN
  RW_TAC std_ss [COUNTABLE_ALT] THEN
  MP_TAC NUM_2D_BIJ_NZ_INV THEN
  RW_TAC std_ss [] THEN Q.EXISTS_TAC `(\(a,b). -(&a/(&b))) o f` THEN
  RW_TAC std_ss [GSPECIFICATION] THEN
  FULL_SIMP_TAC std_ss [BIJ_DEF,INJ_DEF,SURJ_DEF,IN_UNIV] THEN
  PAT_X_ASSUM ``!x. x IN P ==> Q x y`` (MP_TAC o Q.SPEC `(&a,&b)`) THEN
  RW_TAC std_ss [] THEN
  FULL_SIMP_TAC real_ss [IN_CROSS,IN_UNIV,IN_SING,
                         DIFF_DEF,GSPECIFICATION,GSYM REAL_LT_NZ] THEN
  `?y. f y = (a,b)` by METIS_TAC [] THEN Q.EXISTS_TAC `y` THEN
  RW_TAC real_ss []
QED

Theorem countable_real_rat_set = QSET_COUNTABLE

Theorem NUM_IN_QSET :
    !n. &n IN q_set /\ -&n IN q_set
Proof
  FULL_SIMP_TAC std_ss [q_set_def, IN_UNION, GSPECIFICATION] THEN
  RW_TAC std_ss [] THENL
  [DISJ1_TAC THEN EXISTS_TAC ``n:num`` THEN EXISTS_TAC ``1:num`` THEN
   SIMP_TAC real_ss [],
   DISJ2_TAC THEN EXISTS_TAC ``n:num`` THEN EXISTS_TAC ``1:num`` THEN
   SIMP_TAC real_ss []]
QED

Theorem OPP_IN_QSET :
    !x. x IN q_set ==> -x IN q_set
Proof
  RW_TAC std_ss [q_set_def,EXTENSION,GSPECIFICATION,IN_UNION] THENL
  [DISJ2_TAC THEN Q.EXISTS_TAC `a` THEN Q.EXISTS_TAC `b` THEN
   RW_TAC real_ss [], ALL_TAC] THEN
  DISJ1_TAC THEN Q.EXISTS_TAC `a` THEN Q.EXISTS_TAC `b` THEN
  RW_TAC real_ss [REAL_NEG_NEG]
QED

Theorem INV_IN_QSET :
    !x. (x IN q_set) /\ (x <> 0) ==> 1/x IN q_set
Proof
  RW_TAC std_ss [q_set_def,EXTENSION,GSPECIFICATION,IN_UNION] THENL
  [Cases_on `0:real < &a` THENL
   [DISJ1_TAC THEN
    `(&a <> 0:real) /\ (&b <> 0:real)` by FULL_SIMP_TAC real_ss [REAL_POS_NZ,GSYM REAL_LT_NZ] THEN
    Q.EXISTS_TAC `b` THEN Q.EXISTS_TAC `a` THEN FULL_SIMP_TAC std_ss [] THEN
  `1:real / (&a / &b) = (1 / 1) / (&a / &b)` by RW_TAC real_ss [] THEN
    ASM_SIMP_TAC std_ss [] THEN RW_TAC real_ss [div_rat], ALL_TAC] THEN
    DISJ2_TAC THEN
    `&b <> 0:real` by METIS_TAC [REAL_LT_IMP_NE] THEN
    FULL_SIMP_TAC std_ss [] THEN
    `&a <> 0:real` by METIS_TAC [real_div,REAL_ENTIRE] THEN
    FULL_SIMP_TAC real_ss [], ALL_TAC] THEN
  Cases_on `0:real < &a` THENL
  [DISJ2_TAC THEN
   `(&a <> 0:real) /\ (&b <> 0:real)` by
    FULL_SIMP_TAC real_ss [REAL_POS_NZ,GSYM REAL_LT_NZ] THEN
   `&a / &b <> 0:real` by FULL_SIMP_TAC real_ss [REAL_NEG_EQ0] THEN
   Q.EXISTS_TAC `b` THEN Q.EXISTS_TAC `a` THEN FULL_SIMP_TAC std_ss [neg_rat] THEN
   RW_TAC std_ss [real_div, REAL_INV_MUL, REAL_INV_NZ] THEN
   `inv (&b) <> 0:real` by
    FULL_SIMP_TAC real_ss [REAL_POS_NZ,REAL_INV_EQ_0,REAL_POS_NZ] THEN
   RW_TAC real_ss [GSYM REAL_NEG_INV,REAL_NEG_EQ0,REAL_EQ_NEG,REAL_ENTIRE] THEN
   RW_TAC real_ss [REAL_INV_MUL,REAL_INV_INV,REAL_MUL_COMM], ALL_TAC] THEN
  DISJ2_TAC THEN `&b <> 0:real` by METIS_TAC [REAL_LT_IMP_NE] THEN
  `&a <> 0:real` by METIS_TAC [real_div,REAL_ENTIRE,REAL_NEG_EQ0] THEN
  FULL_SIMP_TAC real_ss []
QED

Theorem ADD_IN_QSET :
    !x y. (x IN q_set) /\ (y IN q_set) ==> (x+y IN q_set)
Proof
  RW_TAC std_ss [q_set_def,EXTENSION,GSPECIFICATION,IN_UNION] THENL
  [DISJ1_TAC THEN
   `(&b <> 0:real) /\ (&b' <> 0:real)` by
    FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE] THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL,mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   Q.EXISTS_TAC `(a*b' + a'*b)` THEN Q.EXISTS_TAC `b*b'` THEN
   RW_TAC real_ss [REAL_ADD_RAT,REAL_MUL_COMM,REAL_LT_MUL],
   `&b <> 0:real /\ &b' <> 0:real` by FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE]
   THEN Cases_on `&a*(&b')-(&a'* (&b)) = 0:real` THENL
   [DISJ1_TAC THEN Q.EXISTS_TAC `0` THEN Q.EXISTS_TAC `1` THEN
    RW_TAC real_ss [REAL_DIV_LZERO, GSYM real_sub] THEN
    RW_TAC std_ss [REAL_SUB_RAT,REAL_DIV_LZERO,REAL_MUL_COMM], ALL_TAC] THEN
   Cases_on `0:real < &a * (&b') - (&a' * (&b))` THENL
   [DISJ1_TAC THEN Q.EXISTS_TAC `(a * b' - a' * b)` THEN
    Q.EXISTS_TAC `b * b'` THEN `0:real < &(b * b')` by
                               METIS_TAC [REAL_LT_MUL,mult_ints] THEN
    `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
    RW_TAC std_ss [REAL_SUB_RAT,REAL_MUL_COMM,REAL_LT_MUL,
                   GSYM real_sub,GSYM mult_ints] THEN
    `&a' * &b < &a * (&b'):real` by FULL_SIMP_TAC real_ss [REAL_SUB_LT] THEN
    `a' * b < a * b'` by FULL_SIMP_TAC real_ss [] THEN
    `a' * b <> a * b'` by FULL_SIMP_TAC real_ss [] THEN
    FULL_SIMP_TAC real_ss [REAL_SUB],
    ALL_TAC] THEN
   DISJ2_TAC THEN Q.EXISTS_TAC `(a' * b - a * b')` THEN Q.EXISTS_TAC `b * b'` THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL, mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   `&a * &b' - &a' * &b < 0:real` by
    (FULL_SIMP_TAC real_ss [GSYM real_lte,REAL_LE_LT] THEN
    FULL_SIMP_TAC real_ss []) THEN
   `&a * &b' < &a' * (&b):real` by FULL_SIMP_TAC real_ss [REAL_LT_SUB_RADD] THEN
   `a' * b <> a * b'` by FULL_SIMP_TAC real_ss [] THEN
   RW_TAC std_ss [REAL_SUB_RAT,REAL_MUL_COMM,REAL_LT_MUL,GSYM real_sub] THEN
   RW_TAC std_ss [GSYM mult_ints] THEN
   FULL_SIMP_TAC real_ss [REAL_NEG_SUB,REAL_SUB,neg_rat],
   `&b <> 0:real /\ &b' <> 0:real` by
    FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE] THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL,mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   Cases_on `&a * (&b')-(&a' * (&b)) = 0:real` THENL
   [DISJ1_TAC THEN Q.EXISTS_TAC `0` THEN Q.EXISTS_TAC `1` THEN
    RW_TAC real_ss [REAL_DIV_LZERO] THEN ONCE_REWRITE_TAC [GSYM REAL_NEG_EQ0] THEN
    RW_TAC std_ss [REAL_NEG_ADD,REAL_NEG_NEG] THEN
    RW_TAC std_ss [REAL_SUB_RAT,REAL_MUL_COMM,REAL_LT_MUL,
                   GSYM real_sub,REAL_DIV_LZERO,REAL_SUB_0],
    ALL_TAC] THEN
   Cases_on `0:real < &a * (&b') - (&a' * (&b))` THENL
   [DISJ2_TAC THEN Q.EXISTS_TAC `(a * b' - a' * b)` THEN Q.EXISTS_TAC `b * b'` THEN
    RW_TAC real_ss [REAL_DIV_LZERO] THEN
    RW_TAC std_ss [REAL_ADD_COMM,GSYM real_sub] THEN
    RW_TAC std_ss [REAL_SUB_RAT,REAL_MUL_COMM,REAL_LT_MUL,
                   GSYM real_sub,GSYM mult_ints] THEN
    `&a' * &b < &a * (&b'):real` by FULL_SIMP_TAC real_ss [REAL_SUB_LT] THEN
    `a' * b < a * b'` by FULL_SIMP_TAC real_ss [] THEN
    `a' * b <> a * b'` by FULL_SIMP_TAC real_ss [] THEN
    FULL_SIMP_TAC real_ss [REAL_SUB,neg_rat], ALL_TAC] THEN
   DISJ1_TAC THEN Q.EXISTS_TAC `(a' * b - a * b')` THEN Q.EXISTS_TAC `b * b'` THEN
   RW_TAC std_ss [REAL_ADD_COMM,GSYM real_sub] THEN
   `&a * &b' - &a' * &b < 0:real` by
    (FULL_SIMP_TAC real_ss [GSYM real_lte,REAL_LE_LT] THEN
    FULL_SIMP_TAC real_ss []) THEN
   `&a * &b' < &a' * (&b):real` by FULL_SIMP_TAC real_ss [REAL_LT_SUB_RADD] THEN
   `a' * b <> a * b'` by FULL_SIMP_TAC real_ss [] THEN
   RW_TAC std_ss [REAL_ADD_COMM,GSYM real_sub,REAL_SUB_RAT,
                  REAL_MUL_COMM,REAL_LT_MUL,GSYM mult_ints] THEN
   FULL_SIMP_TAC real_ss [REAL_NEG_SUB,REAL_SUB,neg_rat],
   DISJ2_TAC THEN
   `&b <> 0:real /\ &b' <> 0:real` by FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE] THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL,mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   Q.EXISTS_TAC `(a * b' + a' * b)` THEN Q.EXISTS_TAC `b*b'` THEN
   REWRITE_TAC [GSYM mult_ints,GSYM add_ints] THEN
   RW_TAC std_ss [REAL_SUB_LNEG,GSYM real_sub,REAL_EQ_NEG] THEN
   RW_TAC std_ss [REAL_ADD_RAT,REAL_MUL_COMM,REAL_LT_MUL]]
QED

Theorem SUB_IN_QSET :
    !x y. (x IN q_set) /\ (y IN q_set) ==> (x - y IN q_set)
Proof
  RW_TAC std_ss [real_sub] THEN METIS_TAC [OPP_IN_QSET,ADD_IN_QSET]
QED

Theorem MUL_IN_QSET :
    !x y. (x IN q_set) /\ (y IN q_set) ==> (x * y IN q_set)
Proof
  RW_TAC std_ss [q_set_def,EXTENSION,GSPECIFICATION,IN_UNION] THENL
  [DISJ1_TAC THEN
   `&b <> 0:real /\ &b' <> 0:real` by FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE] THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL,mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   Q.EXISTS_TAC `a * a'` THEN Q.EXISTS_TAC `b * b'` THEN
   FULL_SIMP_TAC real_ss [mult_rat,REAL_LT_REFL,ZERO_LESS_MULT],
   DISJ2_TAC THEN
   `&b <> 0:real /\ &b' <> 0:real` by FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE] THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL,mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   Q.EXISTS_TAC `a*a'` THEN Q.EXISTS_TAC `b*b'` THEN
   FULL_SIMP_TAC real_ss [mult_rat,REAL_LT_REFL,ZERO_LESS_MULT],
   DISJ2_TAC THEN
   `&b <> 0:real /\ &b' <> 0:real` by FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE] THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL,mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   Q.EXISTS_TAC `a*a'` THEN Q.EXISTS_TAC `b*b'` THEN
   FULL_SIMP_TAC real_ss [mult_rat,REAL_LT_REFL,ZERO_LESS_MULT],
   DISJ1_TAC THEN
   `&b <> 0:real /\ &b' <> 0:real` by FULL_SIMP_TAC real_ss [REAL_LT_IMP_NE] THEN
   `0:real < &(b * b')` by METIS_TAC [REAL_LT_MUL,mult_ints] THEN
   `&(b * b') <> 0:real` by RW_TAC std_ss [REAL_LT_IMP_NE] THEN
   Q.EXISTS_TAC `a*a'` THEN Q.EXISTS_TAC `b*b'` THEN
   FULL_SIMP_TAC real_ss [mult_rat,REAL_LT_REFL,ZERO_LESS_MULT]]
QED

Theorem DIV_IN_QSET :
    !x y. (x IN q_set) /\ (y IN q_set) /\ (y <> 0) ==> (x / y IN q_set)
Proof
  RW_TAC std_ss [] THEN
  `(inv y) IN q_set` by METIS_TAC [INV_IN_QSET, REAL_INV_1OVER, INV_IN_QSET] THEN
  METIS_TAC [MUL_IN_QSET, real_div]
QED

Theorem CLG_UBOUND = NUM_CEILING_UPPER_BOUND

Theorem Q_DENSE_IN_REAL_LEMMA :
    !x y. (0 <= x) /\ (x < y) ==> ?r. (r IN q_set) /\ (x < r) /\ (r < y)
Proof
  RW_TAC std_ss [] THEN Cases_on `1:real < y - x` THENL
  [Q.EXISTS_TAC `&(clg y) - 1:real` THEN CONJ_TAC THENL
   [METIS_TAC [SUB_IN_QSET,NUM_IN_QSET], ALL_TAC] THEN
   RW_TAC std_ss [] THENL
   [METIS_TAC [REAL_LT_SUB_LADD,REAL_LT_ADD_SUB,REAL_ADD_COMM,
               REAL_LTE_TRANS,LE_NUM_CEILING], ALL_TAC] THEN
    METIS_TAC [REAL_LT_SUB_RADD,CLG_UBOUND,REAL_LET_TRANS,
               REAL_LT_IMP_LE], ALL_TAC] THEN
  `0 < y - x:real` by RW_TAC real_ss [REAL_SUB_LT] THEN
  (MP_TAC o Q.SPEC `1`) (((UNDISCH o Q.SPEC `y - x`) REAL_ARCH)) THEN
  RW_TAC real_ss [] THEN
  Q_TAC SUFF_TAC `?z. z IN q_set /\ &n * x < z /\ z < &n * y` THENL
  [RW_TAC real_ss [] THEN
   `0 < n` by ( RW_TAC real_ss [] THEN SPOSE_NOT_THEN ASSUME_TAC THEN
   `n = 0` by RW_TAC real_ss [] THEN FULL_SIMP_TAC real_ss []) THEN
   `0 < (&n):real` by RW_TAC real_ss [lt_int] THEN Q.EXISTS_TAC `z / (&n)` THEN
   RW_TAC real_ss [DIV_IN_QSET,NUM_IN_QSET] THENL
   [FULL_SIMP_TAC real_ss [REAL_LT_RDIV_EQ] THEN METIS_TAC [REAL_MUL_SYM],
    ALL_TAC] THEN
   FULL_SIMP_TAC real_ss [REAL_LT_RDIV_EQ,REAL_MUL_COMM,REAL_LT_IMP_NE] THEN
   FULL_SIMP_TAC real_ss [REAL_LT_LDIV_EQ,REAL_MUL_COMM,REAL_LT_IMP_NE],
   ALL_TAC] THEN
  `1 < &n * y - &n * x` by FULL_SIMP_TAC real_ss [REAL_SUB_LDISTRIB] THEN
  Q.EXISTS_TAC `&(clg (&n * y)) - 1` THEN CONJ_TAC THENL
  [METIS_TAC [SUB_IN_QSET,NUM_IN_QSET], ALL_TAC] THEN RW_TAC std_ss [] THENL
  [METIS_TAC [REAL_LT_SUB_LADD,REAL_LT_ADD_SUB,REAL_ADD_COMM,
              REAL_LTE_TRANS,LE_NUM_CEILING], ALL_TAC] THEN
  `0:real <= &n` by RW_TAC real_ss [] THEN
  `0:real <= &n * y` by METIS_TAC [REAL_LE_MUL,REAL_LET_TRANS,REAL_LT_IMP_LE] THEN
  METIS_TAC [REAL_LT_SUB_RADD,CLG_UBOUND,REAL_LET_TRANS,REAL_LT_IMP_LE]
QED

Theorem Q_DENSE_IN_REAL :
    !x y. (x < y) ==> ?r. (r IN q_set) /\ (x < r) /\ (r < y)
Proof
  RW_TAC std_ss [] THEN Cases_on `0 <= x` THENL
  [RW_TAC std_ss [Q_DENSE_IN_REAL_LEMMA], ALL_TAC] THEN
  FULL_SIMP_TAC std_ss [REAL_NOT_LE] THEN
  `-x <= &(clg (-x))` by RW_TAC real_ss [LE_NUM_CEILING] THEN
  `0:real <= x + &clg (-x)` by METIS_TAC [REAL_LE_LNEG] THEN
  `x + &(clg (-x)) < y + &(clg (-x))` by METIS_TAC [REAL_LT_RADD] THEN
  Q_TAC SUFF_TAC `?z. (z IN q_set) /\ (x + &clg (-x) < z) /\
                      (z < y + &clg (-x))` THENL
  [RW_TAC std_ss [] THEN Q.EXISTS_TAC `z - &clg (-x)` THEN
   CONJ_TAC THENL [METIS_TAC [SUB_IN_QSET,NUM_IN_QSET], ALL_TAC] THEN
   RW_TAC std_ss [GSYM REAL_LT_ADD_SUB,REAL_LT_SUB_RADD], ALL_TAC] THEN
  RW_TAC std_ss [Q_DENSE_IN_REAL_LEMMA]
QED

Theorem REAL_RAT_DENSE = Q_DENSE_IN_REAL

val _ = export_theory ();

(* References:

  [1] Schilling, R.L.: Measures, Integrals and Martingales. Cambridge University Press (2005).
  [2] Chung, K.L.: A Course in Probability Theory, Third Edition. Academic Press (2001).
 *)

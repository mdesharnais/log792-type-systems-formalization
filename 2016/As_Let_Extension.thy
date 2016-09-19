(*<*)
theory As_Let_Extension
imports
   Main
  "~~/src/HOL/Eisbach/Eisbach"
  "~~/src/HOL/Eisbach/Eisbach_Tools"
  "$AFP/List-Index/List_Index" 
begin
(*>*)

section{* Ascription and Let Binding  *}

text{*
  This section will present the extended lambda calculus with ascription and let binding, and some examples
*}


datatype ltype =
  Bool |
  T (num:nat) |
  Unit |
  Fun (domain: ltype) (codomain: ltype) (infixr "\<rightarrow>" 225)


datatype lterm =
  LTrue |
  LFalse |
  LIf (bool_expr: lterm) (then_expr: lterm) (else_expr: lterm) |
  LVar nat |
  LAbs (arg_type: ltype) (body: lterm) |
  LApp lterm lterm |
  unit |
  Seq (fp: lterm) (sp: lterm) ("(_;;_)" [100,50] 200) |
  AS lterm ltype ("_/ as/ _" [100,150] 200) |
  LetBinder nat lterm lterm ("Let/ var/ (_)/ :=/ (_)/ in/ (_)" [100,120,150] 250)  

primrec shift_L :: "int \<Rightarrow> nat \<Rightarrow> lterm \<Rightarrow> lterm" where
  "shift_L d c LTrue = LTrue" |
  "shift_L d c LFalse = LFalse" |
  "shift_L d c (LIf t1 t2 t3) = LIf (shift_L d c t1) (shift_L d c t2) (shift_L d c t3)" |
  "shift_L d c (LVar k) = LVar (if k < c then k else nat (int k + d))" |
  "shift_L d c (LAbs T' t) = LAbs T' (shift_L d (Suc c) t)" |
  "shift_L d c (LApp t1 t2) = LApp (shift_L d c t1) (shift_L d c t2)" |
  "shift_L d c unit = unit" |
  "shift_L d c (Seq t1 t2) = Seq (shift_L d c t1) (shift_L d c t2)" |
  "shift_L d c (t as A) = (shift_L d c t) as A" |
  "shift_L d c (Let var x := t in t1) = 
    (if x\<ge> c then Let var (nat (int x + d)) := (shift_L d c t) in (shift_L d c t1)
     else  Let var x := (shift_L d c t) in (shift_L d c t1)
     )"

primrec subst_L :: "nat \<Rightarrow> lterm \<Rightarrow> lterm \<Rightarrow> lterm" where
  "subst_L j s LTrue = LTrue" |
  "subst_L j s LFalse = LFalse" |
  "subst_L j s (LIf t1 t2 t3) = LIf (subst_L j s t1) (subst_L j s t2) (subst_L j s t3)" |
  "subst_L j s (LVar k) = (if k = j then s else LVar k)" |
  "subst_L j s (LAbs T' t) = LAbs T' (subst_L (Suc j) (shift_L 1 0 s) t)" |
  "subst_L j s (LApp t1 t2) = LApp (subst_L j s t1) (subst_L j s t2)" |
  "subst_L j s unit = unit" |
  "subst_L j s (Seq t1 t2) = Seq (subst_L j s t1) (subst_L j s t2)" |
  "subst_L j s (t as A) = (subst_L j s t) as A" |
  "subst_L j s (Let var x := t in t1) = 
  (if j=x then Let var x := subst_L j s t in t1
    else  (Let var x := (subst_L j s t) in (subst_L j s t1))) "
  

inductive is_value_L :: "lterm \<Rightarrow> bool" where
  "is_value_L LTrue" |
  "is_value_L LFalse" |
  "is_value_L (LAbs T' t)" |
  "is_value_L unit"
  
primrec FV :: "lterm \<Rightarrow> nat set" where
  "FV LTrue = {}" |
  "FV LFalse = {}" |
  "FV (LIf t1 t2 t3) = FV t1 \<union> FV t2 \<union> FV t3" |
  "FV (LVar x) = {x}" |
  "FV (LAbs T1 t) = image (\<lambda>x. x - 1) (FV t - {0})" |
  "FV (LApp t1 t2) = FV t1 \<union> FV t2" |
  "FV unit = {}" |
  "FV (Seq t1 t2) = FV t1 \<union> FV t2" |
  "FV (t as A) = FV t" |
  "FV (Let var x:= t in t1) = 
    (if x \<in> FV t1 then (FV t1 - {x}) \<union> FV t else FV t1)"


inductive eval1_L :: "lterm \<Rightarrow> lterm \<Rightarrow> bool" where
  -- "Rules relating to the evaluation of Booleans"
  eval1_LIf_LTrue:
    "eval1_L (LIf LTrue t2 t3) t2" |
  eval1_LIf_LFalse:
    "eval1_L (LIf LFalse t2 t3) t3" |
  eval1_LIf:
    "eval1_L t1 t1' \<Longrightarrow> eval1_L (LIf t1 t2 t3) (LIf t1' t2 t3)" |

  -- "Rules relating to the evaluation of function application"
  eval1_LApp1:
    "eval1_L t1 t1' \<Longrightarrow> eval1_L (LApp t1 t2) (LApp t1' t2)" |
  eval1_LApp2:
    "is_value_L v1 \<Longrightarrow> eval1_L t2 t2' \<Longrightarrow> eval1_L (LApp v1 t2) (LApp v1 t2')" |
  eval1_LApp_LAbs:
    "is_value_L v2 \<Longrightarrow> eval1_L (LApp (LAbs T' t12) v2)
      (shift_L (-1) 0 (subst_L 0 (shift_L 1 0 v2) t12))" |
  
 -- "Rules relating to evaluation of sequence"
  
  eval1_L_Seq:
    "eval1_L t1 t1' \<Longrightarrow> eval1_L (Seq t1 t2) (Seq t1' t2)" |
  eval1_L_Seq_Next:
    "eval1_L (Seq unit t2) t2" |
  
 -- "Rules relating to evaluation of ascription"
  eval1_L_Ascribe:
    "is_value_L v \<Longrightarrow> eval1_L (v as A) v" |
  eval1_L_Ascribe1:
    "eval1_L t1 t1' \<Longrightarrow> eval1_L (t1 as A) (t1' as A)" |
 -- "Rules relating to evaluation of letbinder"
  eval1_L_LetV:
    "is_value_L v1 \<Longrightarrow> eval1_L (Let var x := v1 in t2) (subst_L x v1 t2)" |
  eval1_L_Let:
    "eval1_L t1 t1' \<Longrightarrow> eval1_L (Let var x := t1 in t2) (Let var x := t1' in t2)"

type_synonym lcontext = "ltype list"


notation Nil ("\<emptyset>")
abbreviation cons :: "lcontext \<Rightarrow> ltype \<Rightarrow> lcontext" (infixl "|,|" 200) where
  "cons \<Gamma> T' \<equiv> T' # \<Gamma>"
abbreviation elem' :: "(nat \<times> ltype) \<Rightarrow> lcontext \<Rightarrow> bool" (infix "|\<in>|" 200) where
  "elem' p \<Gamma> \<equiv> fst p < length \<Gamma> \<and> snd p = nth \<Gamma> (fst p)"

text{*  For the typing rule of letbinder, we require to replace the type 
        of the variable by the expected type 
    *}
fun replace ::"nat \<Rightarrow> 'a \<Rightarrow> 'a list \<Rightarrow> 'a list" where
"replace n x xs = 
  (if length xs \<le> n then xs 
    else (take n xs) @ [x] @ (drop (Suc n) xs))"

lemma replace_inv_length[simp]:
  "length (replace n x S) = length S"  
by(induction S arbitrary: x n, auto)



inductive has_type_L :: "lcontext \<Rightarrow> lterm \<Rightarrow> ltype \<Rightarrow> bool" ("((_)/ \<turnstile> (_)/ |:| (_))" [150, 150, 150] 150) where
  -- "Rules relating to the type of Booleans"
  has_type_LTrue:
    "\<Gamma> \<turnstile> LTrue |:| Bool" |
  has_type_LFalse:
    "\<Gamma> \<turnstile> LFalse |:| Bool" |
  has_type_LIf:
    "\<Gamma> \<turnstile> t1 |:| Bool \<Longrightarrow> \<Gamma> \<turnstile> t2 |:| T' \<Longrightarrow> \<Gamma> \<turnstile> t3 |:| T' \<Longrightarrow> \<Gamma> \<turnstile> (LIf t1 t2 t3) |:| T'" |

  -- \<open>Rules relating to the type of the constructs of the $\lambda$-calculus\<close>
  has_type_LVar:
    "(x, T') |\<in>| \<Gamma> \<Longrightarrow> \<Gamma> \<turnstile> (LVar x) |:| (T')" |
  has_type_LAbs:
    "(\<Gamma> |,| T1) \<turnstile> t2 |:| T2 \<Longrightarrow> \<Gamma> \<turnstile> (LAbs T1 t2) |:| (T1 \<rightarrow> T2)" |
  has_type_LApp:
    "\<Gamma> \<turnstile> t1 |:| (T11 \<rightarrow> T12) \<Longrightarrow> \<Gamma> \<turnstile> t2 |:| T11 \<Longrightarrow> \<Gamma> \<turnstile> (LApp t1 t2) |:| T12" |  
  has_type_LUnit:
    "\<Gamma> \<turnstile> unit |:| Unit " |  
  has_type_LSeq:
    "\<Gamma> \<turnstile> t1 |:| Unit \<Longrightarrow> \<Gamma> \<turnstile> t2 |:| A \<Longrightarrow> \<Gamma> \<turnstile> (Seq t1 t2) |:| A" |
  has_type_LAscribe:
    "\<Gamma> \<turnstile> t1 |:| A \<Longrightarrow> \<Gamma> \<turnstile> t1 as A |:| A" |
  has_type_Let:
    "\<Gamma> \<turnstile> t1 |:| A \<Longrightarrow> (replace x A \<Gamma>) \<turnstile> t2 |:| B \<Longrightarrow> \<Gamma> \<turnstile> Let var x := t1 in t2 |:| B"
  
inductive_cases has_type_LetE : "\<Gamma> \<turnstile> Let var x := t1 in t2 |:| B"

lemma inversion:
  "\<Gamma> \<turnstile> LTrue |:| R \<Longrightarrow> R = Bool"
  "\<Gamma> \<turnstile> LFalse |:| R \<Longrightarrow> R = Bool"
  "\<Gamma> \<turnstile> LIf t1 t2 t3 |:| R \<Longrightarrow> \<Gamma> \<turnstile> t1 |:| Bool \<and> \<Gamma> \<turnstile> t2 |:| R \<and> \<Gamma> \<turnstile> t3 |:| R"
  "\<Gamma> \<turnstile> LVar x |:| R \<Longrightarrow> (x, R) |\<in>| \<Gamma>"
  "\<Gamma> \<turnstile> LAbs T1 t2 |:| R \<Longrightarrow> \<exists>R2. R = T1 \<rightarrow> R2 \<and> \<Gamma> |,| T1 \<turnstile> t2 |:| R2"
  "\<Gamma> \<turnstile> LApp t1 t2 |:| R \<Longrightarrow> \<exists>T11. \<Gamma> \<turnstile> t1 |:| T11 \<rightarrow> R \<and> \<Gamma> \<turnstile> t2 |:| T11"
  "\<Gamma> \<turnstile> unit |:| R \<Longrightarrow> R = Unit"
  "\<Gamma> \<turnstile> Seq t1 t2 |:| R \<Longrightarrow> \<exists>A. R = A \<and> \<Gamma> \<turnstile> t2 |:| A \<and> \<Gamma> \<turnstile> t1 |:| Unit"
  "\<Gamma> \<turnstile> t as A |:| R \<Longrightarrow> R = A"
  "\<Gamma> \<turnstile> Let var x := t in t1 |:| R \<Longrightarrow> \<exists>A B. R = B \<and> \<Gamma> \<turnstile> t |:| A \<and> (replace x A \<Gamma>) \<turnstile> t1 |:| B"
proof (auto elim: has_type_L.cases)
  assume H:"\<Gamma> \<turnstile> Let var x := t in t1 |:| R"
  show "\<exists>A. (length \<Gamma> \<le> x \<longrightarrow> \<Gamma> \<turnstile> t |:| A \<and> \<Gamma> \<turnstile> t1 |:| R) \<and> (\<not> length \<Gamma> \<le> x \<longrightarrow> \<Gamma> \<turnstile> t |:| A \<and> (take x \<Gamma> @ drop (Suc x) \<Gamma> |,| A) \<turnstile> t1 |:| R)"
    using H has_type_LetE
    by (cases "x\<ge> length \<Gamma>", fastforce+)
qed

lemma canonical_forms:
  "is_value_L v \<Longrightarrow> \<Gamma> \<turnstile> v |:| Bool \<Longrightarrow> v = LTrue \<or> v = LFalse"
  "is_value_L v \<Longrightarrow> \<Gamma> \<turnstile> v |:| T1 \<rightarrow> T2 \<Longrightarrow> \<exists>t. v = LAbs T1 t"
  "is_value_L v \<Longrightarrow> \<Gamma> \<turnstile> v |:| Unit \<Longrightarrow> v = unit"
by (auto elim: has_type_L.cases is_value_L.cases)

lemma[simp]: "nat (int x + 1) = Suc x" by simp

lemma rep_ins:
  "n\<le>n1 \<Longrightarrow> n\<le> length W \<Longrightarrow> insert_nth n S (replace n1 A W) = replace (Suc n1) A (insert_nth n S W)" (is "?P\<Longrightarrow> ?R \<Longrightarrow> ?Q")
proof -
  assume H: "?R" "?P"
  have 1:"n1\<ge> length W \<Longrightarrow> ?Q"
    by (simp add: min_def)
  have "n1< length W \<Longrightarrow> ?Q"
    proof -
      assume H1: "n1<length W"
      have "(Suc (Suc n1) - n) = Suc (Suc n1 - n)"
            using H
            by fastforce
      with H show ?thesis
        by (simp add: H1 min_def, auto)(simp add: H Suc_diff_le take_drop)
    qed
  with 1 show "?Q" by linarith
qed

lemma rep_ins2:
  "n<n1 \<Longrightarrow> n1\<le> length W \<Longrightarrow> insert_nth n1 S (replace n A W) = replace n A (insert_nth n1 S W)" (is "?P\<Longrightarrow> ?R \<Longrightarrow> ?Q")
proof -
  assume H: "?R" "?P"
  from H show "?Q"
    proof (simp add: min_def, auto)
      have "Suc n \<le> n1"
        by (metis (no_types) H(2) Suc_leI)
      then show "take (n1 - n) (A # drop (Suc n) W) @ S # drop (n1 - n) (A # drop (Suc n) W) = A # drop (Suc n) (take n1 W) @ S # drop n1 W"
        by (simp add: drop_Cons' drop_take take_Cons')
    qed
qed      
    
  
lemma weakening:
  "\<Gamma> \<turnstile> t |:| A \<Longrightarrow> n \<le> length \<Gamma> \<Longrightarrow> insert_nth n S \<Gamma> \<turnstile> shift_L 1 n t |:| A"
proof (induction \<Gamma> t A arbitrary: n rule: has_type_L.induct)
  case (has_type_LAbs \<Gamma> T1 t2 T2)
    from has_type_LAbs.prems has_type_LAbs.hyps
      has_type_LAbs.IH[where n="Suc n"] show ?case
      by (auto intro: has_type_L.intros(5))
next
  case (has_type_Let \<Gamma> t A x t1 B)
    show ?case 
      proof (cases "x\<ge> n")
        assume H:"x\<ge>n"
        have 1:"insert_nth n S \<Gamma> \<turnstile> shift_L 1 n t |:| A"
          using has_type_Let(3)[OF has_type_Let(5)]
          by blast
   
        have "(replace (Suc x) A (insert_nth n S \<Gamma>)) \<turnstile> shift_L 1 n t1 |:| B"
          using has_type_Let(4,5) H 
                rep_ins[of n x \<Gamma> S A,OF H has_type_Let(5)]
                replace_inv_length[of x A \<Gamma>]
          by metis
        with 1 show "insert_nth n S \<Gamma> \<turnstile> shift_L 1 n (Let var x := t in t1) |:| B"
          using "has_type_L.intros"(10) H
          by auto
      next
        assume H: "\<not> n \<le> x"
        have a:"replace x A (take n \<Gamma> @ drop n \<Gamma> |,| S) \<turnstile> shift_L 1 n t1 |:| B"
          using has_type_Let(4)[of n] has_type_Let(5) H
                rep_ins2[of x n \<Gamma> S A]
                replace_inv_length[of n A \<Gamma>]
          by simp
        show "insert_nth n S \<Gamma> \<turnstile> shift_L 1 n (Let var x := t in t1) |:| B"
          using has_type_Let(3,5) 
          by (simp add: H, auto intro: a  "has_type_L.intros"(10) )
      qed    
qed (auto simp: nth_append min_def intro: has_type_L.intros)

subsection{* Ascription*}

(*Exercise 11.4.1*)
text{* Instead of adding As as instruction of our lambda calculus, we can use the following derived form*}

abbreviation AS_D :: "lterm \<Rightarrow> ltype \<Rightarrow> lterm" (infix "asE" 200) where
"t asE A \<equiv> LApp (LAbs A (LVar 0)) t"  

lemma eval1_L_asE:
  "eval1_L t1 t2 \<Longrightarrow> eval1_L (t1 asE A) (t2 asE A)"
by (auto intro: eval1_LApp2 "is_value_L.intros"(3))


lemma shift_shift_invert: "a>0 \<Longrightarrow> shift_L (-a) b (shift_L a b t) = t"
proof(induction t arbitrary: a b)
  case LetBinder
    thus ?case sorry
qed auto

lemma eval1_L_asE1:
  "is_value_L t1 \<Longrightarrow> eval1_L (t1 asE A) t1"
using eval1_LApp_LAbs[of t1 A "LVar 0"] shift_shift_invert[of 1 0 t1]
by auto

(*TODO proof same as for derived form sequence*)


end
module FoldTheorems
import Data.Vect
%default total
%access export
|||A proof that given three element, f associates over them.
Associates: (f : t -> t -> t) -> Type 
Associates {t} f = (t1:t) -> (t2:t) -> (t3:t) -> (f ( f t1 t2) t3 = f t1 (f t2 t3))

|||Lifts to a proof that partial application of f associates. 
AssociatesExtend : Associates f -> (a:t) -> (x:t) -> ((\e => f (f a x) e) = (\e => f a (f x e)))
--Idris does not know about "extentionality" of functions. So we use must use beieve_me.
AssociatesExtend _ = believe_me () 

|||A proof for that all x, f x = x
IdenQ : (f : t -> t) -> Type
IdenQ {t} f = (tn: t) -> (f tn = tn)

|||Lifts to a proof that f is the identity.
IdenExtend : IdenQ f -> (f = Basics.id)
--Idris does not know about "extentionality" of functions. So we must use believe_me.
IdenExtend _ = believe_me ()

|||Given an associate folding function, this proves that 
|||we can pull of the first element in the obvious way.
FoldAssocCons: Associates f ->
               (a:t) -> 
               (as:Vect n t) -> 
               f a (foldr f s as) = foldr f s (a :: as)  
FoldAssocCons _ _ [] = Refl
FoldAssocCons {f} {s} prf a (x :: xs) =
  let foldxs = foldr f s xs in 
  let foldxxs = foldr f s (x::xs) in 
  let l1 = prf a x foldxs in
  let rec = FoldAssocCons {f=f}{s=s} prf x xs in
  let l2 : (f a foldxxs = _ ) = rewrite sym rec in sym l1 in
  let rec2 = FoldAssocCons {f=f} {s=s} prf (f a x) xs in
  let l3 : ( f a foldxxs = foldr f s ((f a x) :: xs)) = rewrite sym rec2 in l2 in
  -- I know if is associative
  let fassoc : ((\x1 => f (f a x) x1) = (\x1 => f a (f x x1))) = AssociatesExtend prf a x in
  let l4 : ( _ = foldr f s (a :: x :: xs)) = rewrite sym fassoc in Refl in
    rewrite sym l4 in l3

|||Given an associative function, folding that function
|||distributes over concatonation.
FoldAssocConcat : Associates f ->
                  IdenQ (f s) -> 
                  (as : Vect n t) ->
                  (bs : Vect m t) ->
                  f (foldr f s as) (foldr f s bs) = foldr f s (as ++ bs) 
FoldAssocConcat {f} {s} prf idprf [] bs = 
  rewrite idprf (foldr f s bs) in Refl
FoldAssocConcat {f} {s} prf idprf (a :: as) bs = 
  let foldas = (foldr f s as) in
  let foldaas = (foldr f s (a::as)) in
  let foldbs = (foldr f s bs) in
  let l1 = FoldAssocCons {s=s} {f=f} prf a as in
  let l2 = prf a foldas foldbs in
  let t3 : (f foldaas foldbs = f a (f foldas foldbs)) = (rewrite sym l1 in l2) in
  let rec = FoldAssocConcat {f=f} {s=s} prf idprf as bs in
  let t4 : (f foldaas foldbs = f a (foldr f s (as ++ bs))) = rewrite sym rec in t3 in
  let l5 = FoldAssocCons {s=s} {f=f} prf a (as ++ bs) in
  let t5 : (f foldaas foldbs = foldr f s (a :: (as ++ bs))) = rewrite sym l5 in t4 in
    t5 

SumAssociates : (as : Vect n Nat) -> (bs: Vect m Nat) -> (sum as + sum bs = sum (as ++ bs))
SumAssociates as bs = 
  let assoc = \a,b,c => sym $ plusAssociative a b c in
      FoldAssocConcat {f=\a,b => plus a b}{s=Z} assoc plusZeroLeftNeutral as bs

MapAppendDistributes : (f: t->u) -> (as : Vect n t) -> (bs : Vect m t) -> (map f as) ++ (map f bs) = map f (as ++ bs)
MapAppendDistributes f [] bs = Refl
MapAppendDistributes f (x :: xs) bs = 
  let induct = MapAppendDistributes f xs bs in
    rewrite induct in Refl 


NotElemLemma1 : Elem inList as -> Not $ Elem outList as -> (inList = outList) -> Void
NotElemLemma1 isIn isOut contra = isOut $ rewrite sym contra in isIn 

minElem : (ord : t -> t -> Ordering) -> Vect (S k) t -> t
minElem ord (x :: []) = x
minElem ord (x :: y :: xs) = 
  let next = minElem ord (y :: xs) in
      case ord x next of 
           LT => x
           GT => next
           EQ => x













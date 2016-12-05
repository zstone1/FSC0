module CoinProblem
import Data.Vect
import FoldTheorems



record CurrencyConstraints (d : Vect k Nat) where
  constructor ValidateCurrency
  hasOne : Elem 1 d

Currency : {k:Nat} -> Type
Currency {k}= (d : Vect k Nat ** CurrencyConstraints {k=k} d) 

MkCurrency : (d : Vect k Nat) -> {auto q : Elem 1 d} -> Currency {k=k}
MkCurrency d {q} = (d ** ValidateCurrency q)

getDenoms : Currency {k=k} -> Vect k Nat
getDenoms x = fst x

getConstraints : (cur : Currency {k=k}) -> CurrencyConstraints (getDenoms cur)
getConstraints = snd

record CoinConstraints (n:Nat) (cur:Currency {k=k}) where
  constructor ValidateCoin
  isDenom : Elem n (getDenoms cur) 

Coin : Currency -> Type
Coin cur = (n : Nat ** CoinConstraints n cur)

getVal : Coin d -> Nat
getVal = fst

MkCoin : (n:Nat) -> (cur : Currency) -> {auto q : Elem n (getDenoms cur)} -> Coin cur
MkCoin {q} n cur = (n ** ValidateCoin q)

cSum : Vect n (Coin d) -> Nat
cSum coins = sum (map getVal coins) 

|||Proof that cSum distributes like sum.
CSumDistr : (as : Vect n (Coin d)) -> (bs : Vect m (Coin d)) -> cSum as + cSum bs = cSum (as ++ bs)
CSumDistr as bs = 
    let as' = map getVal as in
    let bs' = map getVal bs in
    let asbs' = map getVal (as ++ bs) in 
    let l1 : (sum as' + sum bs' = sum (as' ++ bs')) = SumAssociates as' bs' in
    let p2 : (as' ++ bs' = asbs') = MapAppendDistributes getVal as bs in
    let l4 : (sum as' + sum bs' = sum (asbs')) = rewrite sym p2 in l1 in
        l4

record ChangeConstraints (cur : Currency{k=k}) (amt :Nat) (a: Vect n (Coin cur)) where
  constructor ValidateChange
  amtCheck : amt = cSum a

data Change : (cur : Currency) -> (amt: Nat) -> Type where
  MkChange : (n:Nat) -> (a : Vect n (Coin cur)) -> ChangeConstraints cur amt a -> Change cur amt

implementation Show (Change cur amt) where
  show (MkChange n a _) = (show n) ++ " coins totaling " ++(show (cSum a)) ++". " 
      ++ (show (map getVal a))

|||Given change for n and change for m, I can combine and make change for n+m
MergeChange : (c1 : Change cur n) -> (c2 : Change cur m) -> Change cur (n + m)
MergeChange (MkChange {amt = amt1} _ a1 const1) (MkChange {amt = amt2} _ a2 const2) = 
  let (amt1Check, amt2Check) = (amtCheck const1, amtCheck const2) in
  let sumCheckA : (amt1 + amt2 = cSum a1 + cSum a2) = 
    rewrite amt1Check in
    rewrite amt2Check in Refl in
  let sumCheckB : (amt1 + amt2 = cSum (a1 ++ a2)) = rewrite sym $ CSumDistr a1 a2 in sumCheckA in
    MkChange _ (a1 ++ a2) (ValidateChange sumCheckB) 

|||Does the obvious then when the amount of change is a value for a coin.
total
GiveChangeElem : (cur : Currency) -> (amt : Nat) -> (Elem amt (getDenoms cur)) -> Change cur amt
GiveChangeElem cur amt prf = 
  let c = MkCoin amt cur in 
    MkChange _ [c] (ValidateChange (rewrite plusZeroRightNeutral amt in Refl))

fewestCoins : Change cur amt -> Change cur amt -> Ordering 
fewestCoins (MkChange n1 _ _) (MkChange n2 _ _) = compare n1 n2

candDenom : Currency -> Nat -> Type
candDenom cur amt = (n:Nat ** (LT 0 n, LT n amt, Elem n (getDenoms cur))) 

filterCandidates : (cur : Currency) -> 
                   (amt : Nat) -> 
                   {auto q :(LTE 2 amt)} -> 
                   (p:Nat ** Vect (S p) (candDenom cur amt))

minusPlusCancel : (k : Nat) -> (n : Nat) -> {auto q: LTE n k} ->(k = (n +(k - n)))
minusPlusCancel k Z = rewrite minusZeroRight k in Refl
minusPlusCancel Z (S j) {q} = absurd q
minusPlusCancel (S k) (S j) {q} = cong $ minusPlusCancel k j {q = fromLteSucc q}


GiveChange : (cur : Currency) -> (amt: Nat) -> Change cur amt
GiveChange cur amt with (isElem amt (getDenoms cur))
  | Yes prf = GiveChangeElem cur amt prf 
  | No contr = let (_ ** allVals) = AllChangeValues amt contr in minElem fewestCoins allVals where
       AllChangeValues : (n :Nat) -> (Not $ Elem n (getDenoms cur)) -> (p:Nat ** Vect (S p) (Change cur n))
       AllChangeValues Z _ = (_ ** [GiveChange cur Z])
       AllChangeValues (S Z) notDenom = absurd $ notDenom $ hasOne $ getConstraints cur
       AllChangeValues (S(S(k))) _ = let (l ** cands) = filterCandidates cur (S(S(k))) in
                                         (l ** map handleDenom cands) where
         handleDenom : (candDenom cur (S(S(k)))) -> Change cur (S(S(k)))
         handleDenom (n ** (ZLtn, nLtSsk, nInCur)) = 
            let c1 = GiveChange cur n in
            let nLteSsk = lteSuccLeft nLtSsk in
            let c2 = GiveChange cur (S(S(k)) - n) in
            let prf : (S(S(k)) = n + (S(S(k)) - n)) = minusPlusCancel (S(S(k))) n in 
              rewrite prf in MergeChange c1 c2 
        
  
USCurrency : Currency {k=4}
USCurrency = MkCurrency [1,5,10,25]

Foo : Nat -> String 
Foo e= show $ (GiveChange USCurrency e)
 


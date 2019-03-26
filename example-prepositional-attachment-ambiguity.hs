module Example.PrepositionalAttachmentAmbiguity(tests) where

-- Prepositional phrase attachment ambiguity example. See:
-- https://allthingslinguistic.com/post/52411342274/how-many-meanings-can-you-get-for-the-sentence-i

import Prelude hiding (fail,exp,seq,lex)
import Testing
import Earley
import Data.List

data Tree = Word String | Phrase [Tree] deriving (Eq)

instance Show Tree where
  show (Word s) = s
  show (Phrase ts) = "(" ++ intercalate " " (map show ts) ++ ")"

lang :: Lang String (Gram String Tree)
lang = do

  pro  <- lex"PRO" ["I"]
  det  <- lex"D" ["the","a"]
  verb <- lex"V" ["saw"]
  noun <- lex"N" ["man","telescope","hill"]    
  prep <- lex"P" ["on","with"]    
  
  (s',s)   <- declare"S"
  (np',np) <- declare"NP"
  (vp',vp) <- declare"VP"
  (pp',pp) <- declare"PP"

  np' --> seq [pro]
  np' --> seq [det,noun]
  vp' --> seq [verb,np]
  vp' --> seq [verb,np,pp]
  pp' --> seq [prep,np]
  np' --> seq [np,pp]
  s'  --> seq [np,vp]
  
  return s

lex :: String -> [String] -> Lang String (Gram String Tree)
lex name ws = do
  share name $
    alts (map (\w -> do
                  w' <- token
                  if w==w' then return (Word w) else fail
              ) ws)

seq :: [Gram t Tree] -> Gram t Tree
seq = fmap Phrase . sequence

(-->) :: NT t a -> Gram t a -> Lang t ()
(-->) = produce


test :: IO Bool
test =
  run "I saw the man on the hill with a telescope"
  [
    "((I) (saw ((the man) (on ((the hill) (with (a telescope)))))))",
    "((I) (saw (the man) (on ((the hill) (with (a telescope))))))",
    "((I) (saw (((the man) (on (the hill))) (with (a telescope)))))",
    "((I) (saw ((the man) (on (the hill))) (with (a telescope))))"
  ]
  where
    tag = "telescope"
    run :: String -> [String] -> IO Bool
    run str xs =
      check f tag input (Right xs)
      where
        input  = Prelude.words str
        f = fmap (map show) . outcome . parseAmb lang



tests :: [IO Bool]
tests =  [test]

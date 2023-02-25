module Example.PrepositionalAttachmentAmbiguity (tests) where

-- Prepositional phrase attachment ambiguity example. See:
-- https://allthingslinguistic.com/post/52411342274/how-many-meanings-can-you-get-for-the-sentence-i

import Data.List
import EarleyM
import Testing
import Prelude hiding (exp, fail, lex, seq)

data Tree = Word String | Phrase [Tree] deriving (Eq)

instance Show Tree where
    show (Word s) = s
    show (Phrase ts) = "(" ++ unwords (map show ts) ++ ")"

lang :: Lang String (Gram Tree)
lang = do
    pro <- lex ["I"]
    det <- lex ["the", "a"]
    verb <- lex ["saw"]
    noun <- lex ["man", "telescope", "hill"]
    prep <- lex ["on", "with"]

    (s', s) <- declare "S"
    (np', np) <- declare "NP"
    (vp', vp) <- declare "VP"
    (pp', pp) <- declare "PP"

    np' --> seq [pro]
    np' --> seq [det, noun]
    vp' --> seq [verb, np]
    vp' --> seq [verb, np, pp]
    pp' --> seq [prep, np]
    np' --> seq [np, pp]
    s' --> seq [np, vp]

    return s

lex :: [String] -> Lang String (Gram Tree)
lex ws = do
    token <- getToken
    return $
        alts
            ( map
                ( \w -> do
                    w' <- token
                    if w == w' then return (Word w) else fail
                )
                ws
            )

seq :: [Gram Tree] -> Gram Tree
seq = fmap Phrase . sequence

test :: IO Bool
test =
    run
        "I saw the man on the hill with a telescope"
        [ "((I) (saw ((the man) (on ((the hill) (with (a telescope)))))))"
        , "((I) (saw (the man) (on ((the hill) (with (a telescope))))))"
        , "((I) (saw (((the man) (on (the hill))) (with (a telescope)))))"
        , "((I) (saw ((the man) (on (the hill))) (with (a telescope))))"
        ]
  where
    tag = "telescope"
    run :: String -> [String] -> IO Bool
    run str xs =
        check f tag input (Right xs)
      where
        input = Prelude.words str
        f = fmap (map show) . outcome . parseAmb lang

tests :: [IO Bool]
tests = [test]

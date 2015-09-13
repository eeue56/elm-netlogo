module Maths where

import Utils exposing (alwaysOkInt)
import Stack exposing (pushToStack)
import Model exposing (..)
import Debug exposing (log)

add : Argument -> Model -> Model
add numbers model =
  let 
    sum = List.sum <| List.map (alwaysOkInt) numbers
  in 
    pushToStack [toString sum] model

subtract : Argument -> Model -> Model
subtract numbers model =
  let 
    numbers' = List.map (alwaysOkInt) numbers
    first = List.take 1 numbers'
    others = List.map (\x -> -x) <| List.drop 1 numbers'
    sum = 
        List.sum <| first ++ others 
  in 
    pushToStack [toString sum] model

multiply : Argument -> Model -> Model
multiply numbers model =
  let 
    sum = List.product <| List.map (toFloat << alwaysOkInt) numbers
  in 
    pushToStack [toString sum] model
    
{-|
TODO: clean up and watch for unguarded case..of
-}
divide : Argument -> Model -> Model
divide numbers model =
  let 
    numbers' = List.map (toFloat << alwaysOkInt) numbers
    first : Float
    first = case List.head numbers' of Just v -> v
    sum = List.foldl (/) first <| List.drop 1 numbers'
  in 
    pushToStack [toString sum] model
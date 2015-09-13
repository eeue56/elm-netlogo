module Parser where

import Matrix
import Array
import Dict
import String
import Debug exposing (log)

import Model exposing (..)

{-|
TODO: seperate runtimeErrors from compiletime errors
-}
runtimeError : Argument -> Model -> Model
runtimeError = compileError

{-|
add a compile error to the model
-}
compileError : Argument -> Model -> Model
compileError messages model =
  { model | errorMessage <- String.join "\n" <| (model.errorMessage) :: messages }


levenshtein : String -> String -> Int
levenshtein s1' s2' =
  let
    unsafeGet i j m = case Matrix.get i j m of Just v -> v
    unsafeConcatV r m = case Matrix.concatVertical r m of Just v -> v
    unsafeConcatH c m = case Matrix.concatHorizontal c m of Just v -> v
    unsafeFromList xs = case Matrix.fromList xs of Just v -> v
    s1 = Array.fromList <| String.toList s1'
    s2 = Array.fromList <| String.toList s2'
    l1 = Array.length s1
    l2 = Array.length s2
    cost i j = if Array.get (i-1) s1 == Array.get (j-1) s2 then 0 else 1
    levInversion i j m = if i > 1 && 
                       j > 1 && 
                       Array.get (i-1) s1 == Array.get (j-2) s2 &&
                       Array.get (j-2) s1 == Array.get (j-1) s2
                    then min (levStep i j m) (unsafeGet (i-2) (j-2) m + 1)
                    else levStep i j m

    levStep : Int -> Int -> Matrix.Matrix Int -> Int
    levStep i j m = case List.minimum [ unsafeGet (i-1) j m + 1
                                      , unsafeGet i (j-1) m + 1
                                      , unsafeGet (i-1) (j-1) m + (cost i j) ]
                    of Just v -> v

    init : Matrix.Matrix Int
    init = unsafeConcatH
            (unsafeFromList <| List.map (\x->[x]) [0..l2]) <|
            unsafeConcatV
                (unsafeFromList [[1..l1]])
                (Matrix.repeat l1 l2 0)

    step : Int -> Matrix.Matrix Int -> Matrix.Matrix Int
    step i acc = List.foldl (\j m -> Matrix.set i j (levInversion i j m) m) acc [1..l2]
  in
    unsafeGet l1 l2 (List.foldl step init [1..l1])

{-|
add a command not found error to the error log
-}
commandNotFound : CommandLibrary -> String -> Command
commandNotFound dict command  =
  let
    helpWarning = 
      if (List.length <| String.split " " command) > 2 then "\nMaybe you forgot a $?"
      else "\nMaybe you meant: \n" ++ (String.join "\n" 
                                        <| List.map fst
                                        <| List.sortBy (snd) 
                                        <| List.filter (\(_,d) -> d < 3) 
                                        <| List.map (\x -> (x,levenshtein command x)) (Dict.keys dict))
  in
    CompileError ["command not found: " ++ command ++ helpWarning]

{-|
takes text, tries to extract command and args, then return them
-}
findCommand : String -> CommandLibrary -> Command
findCommand text dict =
  let
    commandNotFound' = commandNotFound dict
    trimText = String.trim text
    hasArgs = String.contains "$" trimText
    args = if not hasArgs then [] else
      case List.tail <| String.split "$" trimText of 
        Just v -> case List.head v of 
          Just x -> String.split "," x
          Nothing -> []
        Nothing -> []
  in
    if not hasArgs 
      then 
        case Dict.get trimText dict of
          Just v -> v []
          Nothing -> commandNotFound' trimText
      else
        case List.head <| String.split "$" trimText of
          Just v -> case Dict.get (String.trim v) dict of
            Just command -> command <| List.map (String.trim) args 
            Nothing -> commandNotFound' v
          Nothing -> CompileError ["something up with this line: " ++ trimText]

{-|
returns true if the line starts with the @ symbol
-}
consumesWholeStack : String -> Bool
consumesWholeStack line =
  String.startsWith "@" line

{-|
the amount of stack operations
-}
stackOpCount : String -> Bool -> String -> Model -> Int
stackOpCount op consumesWhole line model =
  if consumesWhole then List.length model.stack
  else List.length <| (String.indexes op line) 


stackPopCount = stackOpCount "#" 
stackUseCount = stackOpCount ">"

{-|
remove stack operations from the front of the line
-}
stripStackOperations : Bool -> String -> Int -> String
stripStackOperations consumesWhole line amount =
  if consumesWhole then String.dropLeft 2 line
  else String.dropLeft amount line 


parseStacking : String -> Model -> Bool -> Int -> Int -> (Command, Int)
parseStacking line model isAll amountOfOps ops =
  let
    tail = stripStackOperations isAll line amountOfOps
    args = 
          if (List.length model.stack) - amountOfOps < 0 then Nothing
          else Just <| log "erm" <| String.join "," <| List.take amountOfOps model.stack
    joiner = if String.contains "$" tail then ", " else " $ "
  in
    case args of 
      Just v -> 
        (findCommand (log "commands" <| String.join "" [tail, joiner, v] ) model.commands, ops)
      Nothing -> 
        log "Nothing at head!" (CompileError ["Not enough items on stack with: " ++ line], 0)

{-|
  take a line, get the stack items, find the command and send the stack items as arguments
-}        
parseStackPop : String -> Model -> (Command, Int)
parseStackPop line model =
  let
    isAll = consumesWholeStack <| String.dropLeft 1 line
    amount = stackPopCount isAll line model
  in
    parseStacking line model isAll amount amount

{-|
  take a line, get the stack items, find the command and send the stack items as arguments
-}   
parseStackUse : String -> Model -> (Command, Int)
parseStackUse line model =
  let
    isAll = consumesWholeStack <| String.dropLeft 1 line
    amount = stackUseCount isAll line model
  in
    parseStacking line model isAll amount 0

isStackOp : String -> Bool
isStackOp line =
  String.startsWith "#" line || String.startsWith ">" line

isComment : String -> Bool
isComment line =
  String.startsWith ";" line

parse : String -> Model -> (Command, Int)
parse line model =
  if isComment line then (Still, 0)
  else
    if not <| isStackOp line then (findCommand line model.commands, 0)
    else 
      (if String.startsWith "#" line then parseStackPop line model
       else parseStackUse line model)
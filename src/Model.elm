module Model where

import Matrix exposing (Matrix)
import Color exposing (Color)
import Dict

type alias Argument = List String

type Action = Reset
  | Enter
  | UpdateText String
  | Noop

type Command = Clear 
  | Eval Argument
  | Filter Argument
  | ApplyLeft Argument
  | ApplyRight Argument
  | ReduceRight Argument
  | ReduceLeft Argument

  | SetPcolor Argument
  | SetPcolorOf Argument 
  | PcolorOf Argument
  | PxcorOf Argument
  | PycorOf Argument
  | PxycorOf Argument

  | LogPatch Argument

  | PatchAt Argument
  | NeighboursOf Argument

  | UseStack Argument
  | DropStack Argument
  | EmptyStack
  | PopOffStack Argument
  | PushToStack Argument
  | ReversePushToStack Argument
  | RepeatTopOfStack Argument
  | BringToTopOfStack Argument
  | SwapTopOfStack

  | Add Argument
  | Subtract Argument
  | Multiply Argument
  | Divide Argument
  | Increment Argument
  | Decrement Argument

  | Equals Argument
  | NotEquals Argument
  | LessThan Argument
  | LessThanOrEquals Argument
  | MoreThan Argument
  | MoreThanOrEquals Argument
  | TrueTest Argument
  | FalseTest Argument

  | CompileError Argument
  | Still
  | Failed

type alias CommandLibrary = Dict.Dict String (Argument -> Command)

type alias Patch = {
  pcolor: Color,
  pxcor : Int,
  pycor : Int
}

type alias CommandPanel = (String, Command)

type alias Model = {
  enteredText : String,

  errorMessage : String,

  patches : Matrix Patch,
  commands : CommandLibrary,
  
  width : Int,
  height : Int,

  stack : List String,
  stackName : String,
  stackShelf : Dict.Dict String (List String),


  patchSize : Float }

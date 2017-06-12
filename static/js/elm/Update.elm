module Update exposing (..)

import Time exposing (Time)

--

import Model exposing (SizedLyricBook)


type Msg
    = AtTime ModelMsg
    | WithTime ModelMsg Time
    | TogglePlayback
    | SetPlayhead Float
    | ScrubberDrag Bool


type ModelMsg
    = SetLyricSizes (Maybe SizedLyricBook)
    | PlayState Bool
    | SyncPlayhead Time Time
    | Animate (Maybe Time)
    | NoOp

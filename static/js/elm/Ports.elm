port module Ports exposing (..)

import Lyrics.Model exposing (LyricPage)
import Player.Model exposing (PlayState, SizedLyricPage)


-- Incoming


port loadedFonts : (Bool -> msg) -> Sub msg


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Maybe SizedLyricPage -> msg) -> Sub msg


port playhead : (Float -> msg) -> Sub msg



-- Outgoing


port jsLoadFonts : List { name : String, path : String } -> Cmd msg


port jsGetSizes : { lyrics : LyricPage, scratchId : String, fontName : String } -> Cmd msg


port jsSetPlayback : Bool -> Cmd msg


port jsSeekTo : Float -> Cmd msg

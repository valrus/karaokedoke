port module Ports exposing (..)

import Lyrics.Model exposing (LyricPage)
import Model exposing (SizedLyricPage)


-- Incoming


port loadedFonts : (Bool -> msg) -> Sub msg


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Maybe SizedLyricPage -> msg) -> Sub msg


port playhead : (( Float, Float ) -> msg) -> Sub msg


-- Outgoing


port loadFonts : List { name : String, path : String } -> Cmd msg


port getSizes : { lyrics : LyricPage, scratchId : String, fontName : String } -> Cmd msg


port togglePlayback : Bool -> Cmd msg


port seekTo : Float -> Cmd msg

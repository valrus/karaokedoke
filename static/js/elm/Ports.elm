port module Ports exposing (..)

import Lyrics.Model exposing (LyricBook)
import Model exposing (SizedLyricBook)


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Maybe SizedLyricBook -> msg) -> Sub msg


port playhead : (( Float, Float ) -> msg) -> Sub msg


port getSizes : { lyrics : LyricBook, fontPath : String, fontName : String } -> Cmd msg


port togglePlayback : Bool -> Cmd msg


port seekTo : Float -> Cmd msg

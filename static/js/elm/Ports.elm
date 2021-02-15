port module Ports exposing (..)

import Json.Decode
import Lyrics.Model exposing (LyricPage, SizedLyricPage)


-- Incoming


port loadedFonts : (Bool -> msg) -> Sub msg


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Json.Decode.Value -> msg) -> Sub msg


port playhead : (Float -> msg) -> Sub msg


port processingEvent : (Json.Decode.Value -> msg) -> Sub msg



-- Outgoing


port jsLoadFonts : List { name : String, path : String } -> Cmd msg


port jsGetSizes : { lyrics : LyricPage, scratchId : String, fontName : String } -> Cmd msg


port jsSetPlayback : Bool -> Cmd msg


port jsSeekTo : Float -> Cmd msg


port jsDestroyWaveform : () -> Cmd msg

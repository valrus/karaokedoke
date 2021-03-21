port module Player.Ports exposing (..)

import Json.Decode
import Lyrics.Model exposing (LyricPage)


port loadedFonts : (Bool -> msg) -> Sub msg


port gotSizes : (Json.Decode.Value -> msg) -> Sub msg


port jsPlayerInitWaveform : { containerId : String, songUrl : String } -> Cmd msg


port jsLoadFonts : List { name : String, path : String } -> Cmd msg


port jsGetSizes : { lyrics : LyricPage, scratchId : String, fontName : String } -> Cmd msg

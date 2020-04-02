port module Ports exposing (..)

import Json.Decode
import Lyrics.Model exposing (LyricPage, SizedLyricPage)



-- From wavesurfer docs:
-- id - string - random - The id of the region.
-- start - float - 0 - The start position of the region (in seconds).
-- end - float - 0 - The end position of the region (in seconds).
-- loop - boolean - false - Whether to loop the region when played back.
-- drag - boolean - true - Allow/dissallow dragging the region.
-- resize - boolean - true - Allow/dissallow resizing the region.
-- color - string - "rgba(0, 0, 0, 0.1)" - HTML color code.


type alias WaveformRegion =
    { start : Float
    , end : Float
    }



-- Incoming


port gotWaveform : (Json.Decode.Value -> msg) -> Sub msg


port loadedFonts : (Bool -> msg) -> Sub msg


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Maybe SizedLyricPage -> msg) -> Sub msg


port playhead : (Float -> msg) -> Sub msg


port processingEvent : (Json.Decode.Value -> msg) -> Sub msg



-- Outgoing


port jsEditorInitWaveform : { containerId : String, songUrl : String } -> Cmd msg


port jsEditorDestroyWaveform : () -> Cmd msg


port jsEditorCreateRegions : List WaveformRegion -> Cmd msg


port jsLoadFonts : List { name : String, path : String } -> Cmd msg


port jsGetSizes : { lyrics : LyricPage, scratchId : String, fontName : String } -> Cmd msg


port jsSetPlayback : Bool -> Cmd msg


port jsSeekTo : Float -> Cmd msg

port module Ports exposing (..)

import Json.Decode


-- Incoming


port playState : (Bool -> msg) -> Sub msg


port playhead : (Float -> msg) -> Sub msg


port processingEvent : (Json.Decode.Value -> msg) -> Sub msg



-- Outgoing


port jsSetPlayback : Bool -> Cmd msg


port jsSeekTo : Float -> Cmd msg


port jsDestroyWaveform : () -> Cmd msg

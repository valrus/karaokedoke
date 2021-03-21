port module Scrubber.Ports exposing (..)

import Json.Decode


port gotWaveformLength : (Json.Decode.Value -> msg) -> Sub msg


port movedPlayhead : (Json.Decode.Value -> msg) -> Sub msg


port changedPlaystate : (Json.Decode.Value -> msg) -> Sub msg


port jsPlayPause : Bool -> Cmd msg

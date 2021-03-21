module Scrubber.Helpers exposing (..)


import Helpers exposing (Milliseconds, seconds)
import Json.Decode as D
import RemoteData exposing (RemoteData(..))


type alias WaveformLengthResult =
    RemoteData String Milliseconds


makeWaveformResult : Maybe Float -> Maybe String -> WaveformLengthResult
makeWaveformResult waveformLength errorMsg =
    case ( waveformLength, errorMsg ) of
        ( Just length, _ ) ->
            Success (seconds length)

        ( _, Just error) ->
            Failure error

        _ ->
            Failure "Totally unrecognizable result from waveform initialization???"


waveformInitResultDecoder : D.Decoder WaveformLengthResult
waveformInitResultDecoder =
    D.map2 makeWaveformResult
        (D.at [ "length" ] (D.nullable D.float))
        (D.at [ "error" ] (D.nullable D.string))

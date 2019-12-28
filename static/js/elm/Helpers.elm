module Helpers exposing (..)

--

import Debug
import Json.Decode as Decode
import Time exposing (Posix, posixToMillis)


type alias Milliseconds
    = Float


type alias Seconds
    = Float


type alias Proportion
    = Float


inSeconds : Milliseconds -> Seconds
inSeconds msec =
    msec / 1000


seconds : Seconds -> Milliseconds
seconds sec =
    sec * 1000


traceDecoder : String -> Decode.Decoder msg -> Decode.Decoder msg
traceDecoder message decoder =
    Decode.value
        |> Decode.andThen
            (\value ->
                case Decode.decodeValue decoder value of
                    Ok decoded ->
                        Decode.succeed <| Debug.log message <| decoded

                    Err err ->
                        Decode.fail <| Debug.log message <| (Decode.errorToString err)
            )

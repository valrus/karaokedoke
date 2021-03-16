module Helpers exposing (..)

--

import Debug
import Http exposing (Error(..))
import Json.Decode as Decode


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


errorToString : Http.Error -> String
errorToString error =
    case error of
        BadUrl url ->
            "The URL " ++ url ++ " was invalid"
        Timeout ->
            "Unable to reach the server, try again"
        NetworkError ->
            "Unable to reach the server, check your network connection"
        BadStatus 500 ->
            "The server had a problem, try again later"
        BadStatus 400 ->
            "Verify your information and try again"
        BadStatus _ ->
            "Unknown error"
        BadBody errorMessage ->
            errorMessage

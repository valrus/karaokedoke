module Helpers exposing (..)

import Json.Decode as Decode
import Time exposing (Time)

--

import Lyrics.Model exposing (Lyric)


lyricBefore : Time -> Maybe Lyric -> Bool
lyricBefore t token =
    case token of
        Nothing ->
            False

        Just tok ->
            tok.time < t


traceDecoder : String -> Decode.Decoder msg -> Decode.Decoder msg
traceDecoder message decoder =
    Decode.value |> Decode.andThen (\value ->
        case Decode.decodeValue decoder value of
            Ok decoded ->
                Decode.succeed <| Debug.log message <| decoded
            Err err ->
                Decode.fail <| Debug.log message <| err)
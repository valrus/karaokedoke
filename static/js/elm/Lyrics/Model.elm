module Lyrics.Model exposing (..)

import Debug exposing (log)
import Helpers exposing (Milliseconds)
import Json.Decode as Decode
import Json.Decode.Extra


type alias Timespan t =
    { t | begin : Milliseconds, end : Milliseconds }


type alias Lyric =
    { id : String, token : String, begin : Milliseconds, end : Milliseconds }


type alias LyricLine =
    { id : String, tokens : List Lyric, begin : Milliseconds, end : Milliseconds }


type alias LyricPage =
    { id : String, lines : List LyricLine, begin : Milliseconds, end : Milliseconds }


type alias LyricBook =
    List (Timespan LyricPage)


type alias Position =
    { x : Float
    , y : Float
    }


type alias Height =
    { min : Float
    , max : Float
    }


type alias Size =
    { height : Float
    , width : Float
    }


type alias SizedLyricLine =
    { content : LyricLine
    , width : Float
    , y : Height
    }


type alias SizedLyricPage =
    { content : List SizedLyricLine
    , size : Size
    }


type alias SizedLyricBook =
    List SizedLyricPage


pageTokenList : LyricPage -> List (List Lyric)
pageTokenList page =
    List.map .tokens page.lines


lyricBefore : Milliseconds -> Maybe Lyric -> Bool
lyricBefore t maybeLyric =
    case maybeLyric of
        Nothing ->
            False

        Just lyric ->
            lyric.begin < t


-- Does this page _start_ before the given time?
pageIsBefore : Milliseconds -> LyricPage -> Bool
pageIsBefore t page =
    List.head page.lines
        |> Maybe.andThen (Just << .tokens)
        |> Maybe.andThen List.head
        |> lyricBefore t


pageAtTime : Milliseconds -> LyricBook -> Maybe LyricPage
pageAtTime time book =
    List.head <| List.filter (not << pageIsBefore time) book


-- {
--   "$id": "https://example.com/arrays.schema.json",
--   "$schema": "http://json-schema.org/draft-07/schema#",
--   "description": "Song lyrics annotated with their position in a song.",
--   "type": "object",
--   "properties": {
--     "fragments": {
--       "type": "array",
--       "items": { "$ref": "#/definitions/fragment" }
--     },
--   },
--   "definitions": {
--     "fragment": {
--       "type": "object",
--       "required": [ "begin", "children", "end", "id", "language", "lines" ],
--       "properties": {
--         "begin": {"type": "string", "description": "The time when this fragment starts, in seconds."},
--         "children": {"type": "array", "items": { "$ref": "#/definitions/fragment" }},
--         "end": {"type": "string", "description": "The time when this fragment ends, in seconds."},
--         "id": {"type": "string"},
--         "language": {"type": "string"},
--         "lines": {"type: "array", "items": {"type": "string"}}
--       }
--     }
--   }
-- }


makeLyricPage : String -> Milliseconds -> Milliseconds -> List LyricLine -> LyricPage
makeLyricPage id begin end lines =
    { id = id, begin = begin, end = end, lines = lines }


makeLyricLine : String -> Milliseconds -> Milliseconds -> List Lyric -> LyricLine
makeLyricLine id begin end tokens =
    { id = id, begin = begin, end = end, tokens = tokens }


makeLyric : String -> Milliseconds -> Milliseconds -> String -> Lyric
makeLyric id begin end token =
    { id = id, begin = begin, end = end, token = token }


lyricCollectionDecoder : (String -> Milliseconds -> Milliseconds -> a -> b) -> String -> Decode.Decoder a -> Decode.Decoder b
lyricCollectionDecoder collectionConstructor subCollectionFieldName subCollectionDecoder =
    Decode.map4 collectionConstructor
        (Decode.field "id" <| Decode.string)
        (Decode.field "begin" <| secondsStringAsMillisecondsDecoder)
        (Decode.field "end" <| secondsStringAsMillisecondsDecoder)
        (Decode.field subCollectionFieldName <| subCollectionDecoder)


lyricDecoder : Decode.Decoder Lyric
lyricDecoder =
    lyricCollectionDecoder makeLyric "lines" (Decode.list Decode.string |> Decode.map (String.join " "))


lyricLineDecoder : Decode.Decoder LyricLine
lyricLineDecoder =
    lyricCollectionDecoder makeLyricLine "children" (Decode.list lyricDecoder)


lyricPageDecoder : Decode.Decoder LyricPage
lyricPageDecoder =
    lyricCollectionDecoder makeLyricPage "children" (Decode.list lyricLineDecoder)


lyricBookDecoder : Decode.Decoder LyricBook
lyricBookDecoder =
    Decode.field "fragments" <| Decode.list lyricPageDecoder


secondsStringAsMillisecondsDecoder : Decode.Decoder Milliseconds
secondsStringAsMillisecondsDecoder =
    Decode.string |> Decode.andThen (stringToMilliseconds >> Json.Decode.Extra.fromResult)


stringToMilliseconds : String -> Result String Milliseconds
stringToMilliseconds =
    String.toFloat >> Result.fromMaybe "couldn't convert to milliseconds" >> Result.map ((*) 1000)

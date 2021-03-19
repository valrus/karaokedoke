module Lyrics.Decode exposing (lyricBookDecoder, sizedLyricPageDecoder)

import Helpers exposing (Milliseconds)
import Json.Decode as Decode
import Json.Decode.Extra
import Lyrics.Model exposing (..)

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


lyricCollectionDecoder : (String -> Milliseconds -> Milliseconds -> a -> b) -> String -> Decode.Decoder a -> Decode.Decoder b
lyricCollectionDecoder collectionConstructor subCollectionFieldName subCollectionDecoder =
    Decode.map4 collectionConstructor
        (Decode.field "id" <| Decode.string)
        (Decode.field "begin" <| Decode.oneOf [ secondsStringAsMillisecondsDecoder, Decode.float ])
        (Decode.field "end" <| Decode.oneOf [ secondsStringAsMillisecondsDecoder, Decode.float ])
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


sizedLyricPageDecoder : Decode.Decoder SizedLyricPage
sizedLyricPageDecoder =
    Decode.map2 SizedLyricPage
        (Decode.field "content" <| Decode.list sizedLyricLineDecoder)
        (Decode.field "size" sizeDecoder)


sizeDecoder : Decode.Decoder Size
sizeDecoder =
    Decode.map2 Size
        (Decode.field "height" Decode.float)
        (Decode.field "width" Decode.float)


processedLyricLineDecoder : Decode.Decoder LyricLine
processedLyricLineDecoder =
    Decode.map4 LyricLine
        (Decode.field "id" Decode.string)
        (Decode.field "tokens" <| Decode.list <| lyricCollectionDecoder makeLyric "text" Decode.string)
        (Decode.field "begin" <| Decode.float)
        (Decode.field "end" <| Decode.float)


sizedLyricLineDecoder : Decode.Decoder SizedLyricLine
sizedLyricLineDecoder =
    Decode.map3 SizedLyricLine
        (Decode.field "content" <| processedLyricLineDecoder)
        (Decode.field "width" Decode.float)
        (Decode.field "yRange" rangeDecoder)


rangeDecoder : Decode.Decoder Range
rangeDecoder =
    Decode.map2 Range
        (Decode.field "min" Decode.float)
        (Decode.field "max" Decode.float)

module Lyrics.Model exposing (..)

import Helpers exposing (Milliseconds)


type alias Lyric =
    { text : String
    , time : Milliseconds
    }


type alias LyricLine =
    List Lyric


type alias LyricPage =
    List LyricLine


type alias LyricBook =
    List LyricPage


lyricBefore : Milliseconds -> Maybe Lyric -> Bool
lyricBefore t token =
    case token of
        Nothing ->
            False

        Just tok ->
            tok.time < t

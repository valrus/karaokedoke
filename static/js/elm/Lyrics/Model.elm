module Lyrics.Model exposing (..)

import Time exposing (Time)


type alias Lyric =
    { text : String
    , time : Time
    }


type alias LyricLine =
    List Lyric


type alias LyricPage =
    List LyricLine


type alias LyricBook =
    List LyricPage
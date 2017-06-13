module Helpers exposing (..)

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

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


type alias Sized t =
    { content : t
    , size : Size
    }


type alias WithDims t =
    { content : t
    , width : Float
    , y : Height
    }


type alias Located t =
    { content : t
    , size : Size
    , pos : Position
    }


type alias SizedLyricPage =
    Sized (List (WithDims LyricLine))


type alias SizedLyricBook =
    List SizedLyricPage


lyricBefore : Milliseconds -> Maybe Lyric -> Bool
lyricBefore t token =
    case token of
        Nothing ->
            False

        Just tok ->
            tok.time < t

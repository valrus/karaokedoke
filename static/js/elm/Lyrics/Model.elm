module Lyrics.Model exposing (..)

import Debug exposing (log)
import Helpers exposing (Milliseconds)


type alias LyricId =
    String


type alias Lyric =
    { id : LyricId, text : String, begin : Milliseconds, end : Milliseconds }


type alias LyricLine =
    { id : LyricId, tokens : List Lyric, begin : Milliseconds, end : Milliseconds }


type alias LyricPage =
    { id : LyricId, lines : List LyricLine, begin : Milliseconds, end : Milliseconds }


type alias LyricBook =
    List LyricPage


type alias Position =
    { x : Float
    , y : Float
    }


type alias Range =
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
    , yRange : Range
    }


type alias SizedLyricPage =
    { content : List SizedLyricLine
    , size : Size
    }


type alias SizedLyricBook =
    List SizedLyricPage


type ExpectedTimeUnit
    = Seconds
    | Milliseconds


pageTokenList : LyricPage -> List (List Lyric)
pageTokenList page =
    List.map .tokens page.lines


pageContentsString : LyricPage -> String
pageContentsString page =
    pageTokenList page |> List.concat |> List.map .text |> String.join " "


lineContentsString : LyricLine -> String
lineContentsString line =
    List.map .text line.tokens |> String.join " "


lyricBefore : Milliseconds -> Maybe Lyric -> Bool
lyricBefore t maybeLyric =
    case maybeLyric of
        Nothing ->
            False

        Just lyric ->
            lyric.begin < t


pageAtTime : Milliseconds -> LyricBook -> Maybe LyricPage
pageAtTime time book =
    List.head <| List.filter (\page -> page.begin < time) <| List.reverse book


allLines : LyricBook -> List LyricLine
allLines lyrics =
    List.concatMap .lines lyrics



makeLyricPage : String -> Milliseconds -> Milliseconds -> List LyricLine -> LyricPage
makeLyricPage id begin end lines =
    { id = id, begin = begin, end = end, lines = lines }


makeLyricLine : String -> Milliseconds -> Milliseconds -> List Lyric -> LyricLine
makeLyricLine id begin end tokens =
    { id = id, begin = begin, end = end, tokens = tokens }


makeLyric : String -> Milliseconds -> Milliseconds -> String -> Lyric
makeLyric id begin end text =
    { id = id, begin = begin, end = end, text = text }

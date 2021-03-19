module Lyrics.Encode exposing (encodeLyricBook)

import Json.Encode as E
import Lyrics.Model exposing (..)
import Helpers exposing (inSeconds)


encodeLyricTokens : Lyric -> E.Value
encodeLyricTokens lyric =
    E.object
    [ ( "begin", E.string <| String.fromFloat <| inSeconds lyric.begin )
    , ( "children", E.list E.string [] )
    , ( "end", E.string <| String.fromFloat <| inSeconds lyric.end )
    , ( "id", E.string lyric.id )
    , ( "language", E.string "eng" )
    , ( "lines", E.list E.string [ lyric.text ] )
    ]


encodeLyricLine : LyricLine -> E.Value
encodeLyricLine line =
    E.object
    [ ( "begin", E.string <| String.fromFloat <| inSeconds line.begin )
    , ( "children", E.list encodeLyricTokens line.tokens )
    , ( "end", E.string <| String.fromFloat <| inSeconds line.end )
    , ( "id", E.string line.id )
    , ( "language", E.string "eng" )
    , ( "lines", E.string <| lineContentsString line )
    ]


encodeLyricPage : LyricPage -> E.Value
encodeLyricPage page =
    E.object
    [ ( "begin", E.string <| String.fromFloat <| inSeconds page.begin )
    , ( "children", E.list encodeLyricLine page.lines )
    , ( "end", E.string <| String.fromFloat <| inSeconds page.end )
    , ( "id", E.string page.id )
    , ( "language", E.string "eng" )
    , ( "lines", E.string <| pageContentsString page )
    ]

encodeLyricBook : LyricBook -> E.Value
encodeLyricBook lyrics =
    E.object [
         ( "fragments", E.list encodeLyricPage lyrics)
    ]

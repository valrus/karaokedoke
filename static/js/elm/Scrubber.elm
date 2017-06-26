module Scrubber exposing (..)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (on, onMouseDown)
import Json.Decode as Decode
import Time exposing (Time)

--

import Lyrics.Model exposing (LyricBook, LyricPage, LyricLine, Lyric)
import Model exposing (Model)
import Update exposing (..)


scrubberHeight : Int
scrubberHeight =
    60


toCssPercent : Float -> String
toCssPercent proportion =
    (toString (proportion * 100)) ++ "%"


proportionInSeconds : Time -> Float -> Float
proportionInSeconds duration position =
    (duration * position) / Time.second


decodeClickX : Decode.Decoder Float
decodeClickX =
    (Decode.map2 (/)
        (Decode.map2 (-)
            (Decode.at [ "pageX" ] Decode.float)
            (Decode.at [ "target", "offsetLeft" ] Decode.float)
        )
        (Decode.at [ "target", "offsetWidth" ] Decode.float)
    )


mouseScrub : Bool -> Time -> Decode.Decoder Msg
mouseScrub dragging duration =
    case dragging of
        True ->
            Decode.map
                (((*) duration)
                    >> (SyncPlayhead >> AtTime)) (decodeClickX)

        False ->
            Decode.succeed (AtTime NoOp)


mouseSeek : Time -> Decode.Decoder Msg
mouseSeek duration =
    Decode.map SetPlayhead decodeClickX


timeAsPercent : Time -> Time -> Float
timeAsPercent duration position =
    (position / duration) * 100


lyricMark : Time -> Int -> Int -> Lyric -> Html msg
lyricMark duration tokenCount index lyric =
    let vspace =
        (scrubberHeight - 8) // tokenCount
    in
        Html.div 
            [ HtmlAttr.style
                [ ( "position", "absolute" )
                , ( "left", (toString <| timeAsPercent duration lyric.time) ++ "%" )
                , ( "top", (toString <| (index * vspace) + 4) ++ "px" )
                , ( "width", "5px" )
                , ( "height", (toString <| vspace - 2) ++ "px" )
                , ( "display", "block" )
                , ( "overflow", "auto" )
                , ( "background-color", "#a00" )
                ]
            ]
            [ ]


lineMarks : Time -> Int -> LyricLine -> List (Html Msg)
lineMarks duration tokenCount line =
    List.indexedMap (lyricMark duration tokenCount) line


countPageTokens : LyricPage -> Int
countPageTokens page =
    List.map List.length page |> List.sum


pageMarks : Time -> LyricPage -> List (Html Msg)
pageMarks duration page =
    [ Html.div
        [ HtmlAttr.style
            [ ( "position", "absolute" )
            , ( "width", "100%" )
            , ( "height", "100%" )
            , ( "background-color", "transparent" )
            ]
        ]
        <| List.indexedMap (lyricMark duration <| countPageTokens page)
        <| List.concat page
    ]


eventMarks : Time -> LyricBook -> List (Html Msg)
eventMarks duration book =
    List.concatMap (pageMarks duration) book


view : Model -> Html Msg
view model =
    Html.div
        [ HtmlAttr.style
            [ ( "id", "scrubber" )
            ]
        ]
        [ Html.div
            [ HtmlAttr.style
                [ ( "background", "#000" )
                , ( "width", toCssPercent (model.playhead / model.duration) )
                , ( "height", "100%" )
                ]
            ]
            []
        , Html.div
            [ HtmlAttr.style
                [ ( "position", "absolute" )
                , ( "bottom", "0" )
                , ( "background-color", "transparent" )
                , ( "width", "100%" )
                , ( "height", "100%" )
                ]
            , onMouseDown (ScrubberDrag True)
            , on "mousemove" (mouseScrub model.dragging model.duration)
            , on "mouseup" (mouseSeek model.duration)
            ]
            (eventMarks model.duration model.lyrics)
        ]
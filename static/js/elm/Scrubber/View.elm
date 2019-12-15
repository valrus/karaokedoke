module Scrubber.View exposing (view, scrubberHeight)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (on, onMouseDown, onMouseUp, onMouseOver, onMouseLeave)
import Html.Lazy exposing (lazy2)
import Json.Decode as Decode
import Time exposing (Time)
import Debug exposing (log)

--

import Lyrics.Model exposing (LyricBook, LyricPage, LyricLine, Lyric)
import Scrubber.Model exposing (Model)
import Update exposing (..)
import Helpers exposing (traceDecoder)


scrubberHeight : Int
scrubberHeight =
    80


toCssPercent : Float -> String
toCssPercent proportion =
    (toString <| proportion * 100) ++ "%"


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
    let msg =
        case dragging of
            True ->
                DragScrubber

            False ->
                MoveScrubberCursor
    in
        Decode.map (msg >> AtTime) decodeClickX


mouseSeek : Time -> Decode.Decoder Msg
mouseSeek duration =
    Decode.map ((proportionInSeconds duration) >> SetPlayhead) decodeClickX


timeAsPercent : Time -> Time -> Float
timeAsPercent duration position =
    (position / duration) * 100


lyricMark : Time -> Int -> Int -> Lyric -> Html Msg
lyricMark duration tokenCount index lyric =
    let
        vspace =
            (scrubberHeight - 8) // tokenCount
        markHeight =
            min 4 <| vspace - 1
    in
        Html.div 
            [ HtmlAttr.style
                [ ( "position", "absolute" )
                , ( "left", (toString <| timeAsPercent duration lyric.time) ++ "%" )
                , ( "top", (toString <| (index * (markHeight + 1)) + 4) ++ "px" )
                , ( "width", "5px" )
                , ( "height", (toString <| markHeight) ++ "px" )
                , ( "display", "block" )
                , ( "overflow", "auto" )
                , ( "background-color", "#a00" )
                ]
            , HtmlAttr.title lyric.text
            , onMouseUp (SetPlayhead <| lyric.time / Time.second)
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


eventMarks : Time -> LyricBook -> Html Msg
eventMarks duration book =
    Html.div
        [ HtmlAttr.id "marks" ]
        <| List.concatMap (pageMarks duration) book


cursorMark : Maybe Float -> Html Msg
cursorMark position =
    case position of
        Just proportion ->
            Html.div 
                [ HtmlAttr.style
                    [ ( "position", "absolute" )
                    , ( "left", toCssPercent proportion )
                    , ( "top", "0" )
                    , ( "width", "1px" )
                    , ( "height", "100%" )
                    , ( "display", "block" )
                    , ( "overflow", "auto" )
                    , ( "background-color", "#0a0" )
                    , ( "pointer-events", "none" )
                    ]
                ]
                [ ]
        
        Nothing ->
            Html.div [] []


view : Model -> LyricBook -> Html Msg
view model lyrics =
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
            , on "mousedown" (mouseScrub True model.duration)
            , on "mousemove" (mouseScrub model.dragging model.duration)
            , on "mouseup" (mouseSeek model.duration)
            , onMouseLeave (AtTime LeaveScrubber)
            ]
            [ lazy2 eventMarks model.duration lyrics
            , cursorMark model.cursorX
            ]
        ]
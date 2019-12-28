module Scrubber.View exposing (scrubberHeight, view)

--

import Debug exposing (log)
import Helpers exposing (Milliseconds, Seconds, Proportion, inSeconds, traceDecoder)
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (on, onMouseDown, onMouseLeave, onMouseOver, onMouseUp)
import Html.Lazy exposing (lazy2)
import Json.Decode as Decode
import Lyrics.Model exposing (Lyric, LyricBook, LyricLine, LyricPage)
import Scrubber.Model exposing (Model)
import String
import Update exposing (..)


scrubberHeight : Int
scrubberHeight =
    80


toCssPercent : Float -> String
toCssPercent proportion =
    (String.fromFloat <| proportion * 100) ++ "%"


proportionInMilliseconds : Milliseconds -> Proportion -> Milliseconds
proportionInMilliseconds duration position =
    duration * position


decodeClickXProportion : Decode.Decoder Proportion
decodeClickXProportion =
    Decode.map2 (/)
        (Decode.map2 (-)
            (Decode.at [ "pageX" ] Decode.float)
            (Decode.at [ "target", "offsetLeft" ] Decode.float)
        )
        (Decode.at [ "target", "offsetWidth" ] Decode.float)


mouseScrub : Bool -> Decode.Decoder Msg
mouseScrub dragging =
    let
        msg =
            case dragging of
                True ->
                    DragScrubber

                False ->
                    MoveScrubberCursor
    in
    Decode.map (msg >> Immediately) decodeClickXProportion


mouseSeek : Milliseconds -> Decode.Decoder Msg
mouseSeek duration =
    Decode.map (proportionInMilliseconds duration >> SetPlayhead) decodeClickXProportion


timeAsPercent : Milliseconds -> Milliseconds -> Float
timeAsPercent duration position =
    (100 * position) / duration


lyricMark : Milliseconds -> Int -> Int -> Lyric -> Html Msg
lyricMark duration tokenCount index lyric =
    let
        vspace =
            (scrubberHeight - 8) // tokenCount

        markHeight =
            min 4 <| vspace - 1
    in
    Html.div
        [ HtmlAttr.style "position" "absolute"
        , HtmlAttr.style "left" ((String.fromFloat <| timeAsPercent duration lyric.time) ++ "%")
        , HtmlAttr.style "top" ((String.fromInt <| (index * (markHeight + 1)) + 4) ++ "px")
        , HtmlAttr.style "width" "5px"
        , HtmlAttr.style "height" ((String.fromInt <| markHeight) ++ "px")
        , HtmlAttr.style "display" "block"
        , HtmlAttr.style "overflow" "auto"
        , HtmlAttr.style "background-color" "#a00"
        , HtmlAttr.title lyric.text
        , onMouseUp (SetPlayhead <| lyric.time)
        ]
        []


lineMarks : Milliseconds -> Int -> LyricLine -> List (Html Msg)
lineMarks duration tokenCount line =
    List.indexedMap (lyricMark duration tokenCount) line


countPageTokens : LyricPage -> Int
countPageTokens page =
    List.map List.length page |> List.sum


pageMarks : Milliseconds -> LyricPage -> List (Html Msg)
pageMarks duration page =
    [ Html.div
        [ HtmlAttr.style "position" "absolute"
        , HtmlAttr.style "width" "100%"
        , HtmlAttr.style "height" "100%"
        , HtmlAttr.style "background-color" "transparent"
        ]
      <|
        List.indexedMap (lyricMark duration <| countPageTokens page) <|
            List.concat page
    ]


eventMarks : Milliseconds -> LyricBook -> Html Msg
eventMarks duration book =
    Html.div
        [ HtmlAttr.id "marks" ]
    <|
        List.concatMap (pageMarks duration) book


cursorMark : Maybe Float -> Html Msg
cursorMark position =
    case position of
        Just proportion ->
            Html.div
                [ HtmlAttr.style "position" "absolute"
                , HtmlAttr.style "left" (toCssPercent proportion)
                , HtmlAttr.style "top" "0"
                , HtmlAttr.style "width" "1px"
                , HtmlAttr.style "height" "100%"
                , HtmlAttr.style "display" "block"
                , HtmlAttr.style "overflow" "auto"
                , HtmlAttr.style "background-color" "#0a0"
                , HtmlAttr.style "pointer-events" "none"
                ]
                []

        Nothing ->
            Html.div [] []


view : Model -> LyricBook -> Html Msg
view model lyrics =
    Html.div
        [ HtmlAttr.style "id" "scrubber"
        ]
        [ Html.div
            [ HtmlAttr.style "background" "#000"
            , HtmlAttr.style "width" (model.playhead / model.duration |> toCssPercent)
            , HtmlAttr.style "height" "100%"
            ]
            []
        , Html.div
            [ HtmlAttr.style "position" "absolute"
            , HtmlAttr.style "bottom" "0"
            , HtmlAttr.style "background-color" "transparent"
            , HtmlAttr.style "width" "100%"
            , HtmlAttr.style "height" "100%"
            , on "mousedown" (mouseScrub True)
            , on "mousemove" (mouseScrub model.dragging)
            , on "mouseup" (mouseSeek model.duration)
            , onMouseLeave (Immediately LeaveScrubber)
            ]
            [ lazy2 eventMarks model.duration lyrics
            , cursorMark model.cursorX
            ]
        ]

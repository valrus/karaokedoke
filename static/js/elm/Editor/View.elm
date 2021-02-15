module Editor.View exposing (view)

import Debug exposing (log)
import Editor.State exposing (Model, Msg(..), waveformContainerName)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Helpers exposing (Milliseconds, errorToString)
import Html exposing (Html)
import Html.Attributes exposing (id, style)
import Html.Events exposing (on)
import Json.Decode
import Lyrics.Model exposing (..)
import Ports
import RemoteData exposing (RemoteData(..), WebData)


songHeader : Model -> Element Msg
songHeader model =
    el
        [ centerX
        , Font.size 36
        ]
    <|
        text <|
            (RemoteData.toMaybe >> Maybe.map .name >> Maybe.withDefault "Unknown song") model.song



-- cursor setting: https://gist.github.com/dsdsdsdsdsds/bd142334efcd81f0b30e


snipStrip : Model -> Element Msg
snipStrip model =
    let
        cursorStyle =
            if model.snipping then
                "url(/images/scissors-closed-white.svg) 16 16, ew-resize"

            else
                "url(/images/scissors-open-white.svg) 16 16, ew-resize"
    in
    el
        (List.concat
            [ [ centerX
              , alignTop
              , height fill
              , width (px 16)
              , Background.color <| rgba 1.0 0.0 0.0 0.1
              , htmlAttribute <| style "cursor" cursorStyle
              , Events.onMouseDown ClickedSnipStrip
              , Events.onMouseLeave CanceledSnip
              ]
            , if model.snipping then
                [ Events.onMouseUp Snipped ]

              else
                []
            ]
        )
        Element.none


waveform : Element Msg
waveform =
    el
        [ htmlAttribute <| id waveformContainerName
        , width fill
        , height (px 60)
        , centerX
        , centerY
        ]
        Element.none


playingSymbol : Model -> String
playingSymbol model =
    if model.playing then "⏸️" else "▶️"


playPauseButton : Model -> Element Msg
playPauseButton model =
    el
        [ Font.size 56
        , Events.onClick <| PlayPause model.playing
        , centerY
        , moveDown 5
        , width shrink
        , height shrink
        , pointer
        ]
        (text <| playingSymbol model)


songControls : Model -> Element Msg
songControls model =
    column
        [ ]
        [ playPauseButton model ]


waveformSection : Model -> Element Msg
waveformSection model =
    row
        [ width fill
        , centerX
        , centerY
        , spacing 10
        ]
        [ songControls model
        , waveform ]


lyricsLineElement : Milliseconds -> Timespan LyricLine -> Element Msg
lyricsLineElement playhead line =
    row [ spacing 5, padding 5 ] <| (List.map .text >> List.map text) line.tokens


lyricsPageElement : Milliseconds -> Timespan LyricPage -> Element Msg
lyricsPageElement playhead page =
    column
        [ centerX
        , alignTop
        , width fill
        , Background.color <|
            if pageIsBefore playhead page then
                rgba 1.0 0.8 0.8 1.0
            else
                rgba 0.9 0.9 0.9 0.8
        ]
    <|
        List.map (lyricsLineElement playhead) page.lines


lyricsElement : Milliseconds -> WebData LyricBook -> Element Msg
lyricsElement playhead lyricData =
    column [ centerX, alignTop, width fill, spacing 10 ] <|
        case lyricData of
            NotAsked ->
                [ text "La de da" ]

            Loading ->
                [ text "Loading" ]

            Failure e ->
                [ text <| errorToString e ]

            Success lyrics ->
                List.map (lyricsPageElement playhead) lyrics


lyricsSection : Model -> Element Msg
lyricsSection model =
    row
        [ centerX, alignTop ]
        [ snipStrip model
        , lyricsElement model.playhead model.lyrics
        ]


iconAttribution : Element Msg
iconAttribution =
    el
        [ centerX
        , width fill
        , alignBottom
        , padding 10
        , Background.color <| rgba 0.8 0.8 1.0 0.9
        ]
    <|
        paragraph
            [ centerX, width shrink ]
            [ text "Scissors cursor icons made by "
            , link [] { url = "https://www.flaticon.com/authors/freepik", label = text "Freepik" }
            , text " from "
            , link [] { url = "https://www.flaticon.com/", label = text "flaticon.com" }
            ]


viewEditor : Model -> Element Msg
viewEditor model =
    column
        [ centerX
        , alignTop
        , width fill
        , paddingEach { top = 130, right = 40, bottom = 40, left = 40 }
        , spacing 20
        ]
        [ lyricsSection model
        ]


header : Model -> Element Msg
header model =
    column
        [ width fill
        , alignTop
        , padding 10
        , spacing 10
        , Background.color <| rgba 0.8 0.8 0.8 1.0
        ]
        [ songHeader model
        , waveformSection model
        ]


view : Model -> Html Msg
view model =
    layout
        [ inFront <| header model
        , inFront <| iconAttribution
        ]
    <|
        viewEditor model

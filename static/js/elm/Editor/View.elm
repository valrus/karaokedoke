module Editor.View exposing (view)

import Debug exposing (log)
import Editor.State exposing (Model, Msg(..), waveformContainerName)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Helpers exposing (errorToString)
import Html exposing (Html)
import Html.Attributes exposing (id)
import Html.Events exposing (on)
import Json.Decode
import Lyrics.Model exposing (..)
import Ports
import RemoteData exposing (RemoteData(..), WebData)


headerSection : Model -> Element Msg
headerSection model =
    el
        [ Font.size 36
        , centerX
        ]
    <|
        text <|
            (RemoteData.toMaybe >> Maybe.map .name >> Maybe.withDefault "Unknown song") model.song


waveformSection : model -> Element Msg
waveformSection model =
    el
        [ htmlAttribute <| id waveformContainerName
        , width fill
        , centerX
        ]
        Element.none


lineElement : Timespan LyricLine -> Element Msg
lineElement line =
    text <| String.join " " (List.map .token line.tokens)


pageElement : Timespan LyricPage -> Element Msg
pageElement page =
    column [ centerX, alignTop, width fill ] <| List.map lineElement page.lines


lyricsElement : LyricBook -> Element Msg
lyricsElement lyrics =
    column [ centerX, alignTop, width fill ] <| List.map pageElement lyrics


lyricsSection : WebData LyricBook -> Element Msg
lyricsSection lyricData =
    el
        [ centerX, alignTop ]
    <|
        case lyricData of
            NotAsked ->
                text "La de da"

            Loading ->
                text "Loading"

            Failure e ->
                text <| errorToString e

            Success lyrics ->
                lyricsElement lyrics


viewEditor : Model -> Element Msg
viewEditor model =
    column
        [ centerX
        , alignTop
        , width fill
        , padding 40
        , spacing 20
        ]
        [ headerSection model
        , waveformSection model
        , lyricsSection model.lyrics
        ]


view : Model -> Html Msg
view model =
    layout [] <| viewEditor model

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
import Lyrics.Model exposing (LyricBook)
import Ports
import RemoteData exposing (RemoteData(..), WebData)


headerSection : Model -> Element Msg
headerSection model =
    el
        [ Font.size 36
        , centerX
        ]
    <|
        text <| (RemoteData.toMaybe >> Maybe.map .name >> Maybe.withDefault "Unknown song") model.song


waveformSection : model -> Element Msg
waveformSection model =
    el
        [ htmlAttribute <| id waveformContainerName
        , width fill
        , centerX
        ]
        Element.none


lyricsSection : WebData LyricBook -> Element Msg
lyricsSection lyricData =
    el
        []
    <|
        text <|
            case lyricData of
                NotAsked ->
                    "La de da"

                Loading ->
                    "Loading"

                Failure e ->
                    errorToString e

                Success lyrics ->
                    "Lyrics will go here..."


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

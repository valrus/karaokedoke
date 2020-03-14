module Editor.View exposing (view)

import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes exposing (id)
import Html.Events exposing (on)
import Json.Decode

--

import RemoteData exposing (WebData, RemoteData(..))

--

import Editor.State exposing (Model, Msg(..), waveformContainerName)
import Helpers exposing (errorToString)
import Ports


header : Model -> Element Msg
header model =
    el
        [ Font.size 36
        , centerX
        ] <|
        text <|
            case model.lyrics of
                NotAsked ->
                    "La de da"

                Loading ->
                    "Loading"

                Failure e ->
                    errorToString e

                Success a ->
                    model.song.name


waveform : model -> Element Msg
waveform model =
    el
        [ htmlAttribute <| id waveformContainerName
        , width fill
        , centerX
        ]
        Element.none


viewEditor : Model -> Element Msg
viewEditor model =
    column
        [ centerX
        , alignTop
        , width fill
        , padding 40
        , spacing 20
        ]
        [ header model
        , waveform model
        ]


view : Model -> Html Msg
view model =
    layout [ ] <| viewEditor model

module Editor.View exposing (view)

import Debug exposing (log)
import Dict
import Editor.State exposing (Model, Msg(..), waveformContainerName)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Helpers exposing (Milliseconds, errorToString, inSeconds)
import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Html.Events exposing (on)
import Json.Decode
import Lyrics.Model exposing (..)
import Ports
import RemoteData exposing (RemoteData(..), WebData, toMaybe)
import Url.Builder


headerPadding : Int
headerPadding =
    10


headerContentHeight : Int
headerContentHeight =
    56


waveformWidth : Int
waveformWidth =
    800


headerHeight : Int
headerHeight =
    headerContentHeight + (2 * headerPadding)


returnLink : Element Msg
returnLink =
    el
        [ width (px controlsWidth) ]
            <|
        link [] { url = Url.Builder.absolute [] [], label = text "Back" }


songHeader : Model -> Element Msg
songHeader model =
    row
        [ centerX
        , Font.size 36
        , width (px waveformWidth)
        ]
    <|
        [ el [ alignLeft, clipX, width <| maximum (waveformWidth - controlsWidth) <| fill ] <|
            text <|
                (RemoteData.toMaybe >> Maybe.map .name >> Maybe.withDefault "Unknown song") model.song
        , songControls model
        ]



-- cursor setting: https://gist.github.com/dsdsdsdsdsds/bd142334efcd81f0b30e


waveform : Model -> Element Msg
waveform model =
    el
        [ htmlAttribute <| id waveformContainerName
        , htmlAttribute <| style "display" "flex"

        -- TODO: pass this through the port to initialize wavesurfer
        , width (px waveformWidth)
        , height fill
        , centerX
        , alignTop
        , inFront <| viewEditor model
        ]
        Element.none


playingSymbol : Model -> String
playingSymbol model =
    if model.playing then
        "⏸️"

    else
        "▶️"


controlsWidth : Int
controlsWidth =
    56


waveformSpacing : Int
waveformSpacing =
    10


lyricsLeftMargin : Int
lyricsLeftMargin =
    (waveformSpacing * 2) + controlsWidth


playPauseButton : Model -> Element Msg
playPauseButton model =
    el
        [ Font.size headerContentHeight
        , Events.onClick <| PlayPause model.playing
        , centerY
        , centerX
        , moveDown 5
        , width shrink
        , height shrink
        , pointer
        ]
        (text <| playingSymbol model)


songControls : Model -> Element Msg
songControls model =
    column
        [ alignRight
        , width (px controlsWidth)
        ]
        [ playPauseButton model ]


lyricTokensHtml : LyricLine -> Html Msg
lyricTokensHtml line =
    div
        [ style "padding" "5px"
        ]
    <|
        [ div [] <| [ Html.text <| (List.map .text >> String.join " ") line.tokens ] ]


lyricsLineHtml : Model -> LyricLine -> Html Msg
lyricsLineHtml model line =
    let
        ( lineMilliseconds, topPixels ) =
            case Dict.get line.id model.lyricPositions of
                Just pos ->
                    ( pos.startTime, pos.bottomPixels )

                Nothing ->
                    ( line.begin, round <| 20 * inSeconds line.begin )
    in
    div
        -- TODO move this to CSS
        [ style "position" "absolute"
        , style "display" "flex"
        , style "justify-content" "center"
        , style "width" "100%"
        , style "top" <| String.concat [ String.fromInt <| topPixels, "px" ]
        , style "background-color" <|
            if lineMilliseconds < model.playhead then
                "rgba(255, 200, 200, 0.8)"

            else
                "rgba(222, 222, 222, 0.8)"
        ]
        [ lyricTokensHtml line
        ]


lyricsPageHtml : Model -> LyricPage -> Html Msg
lyricsPageHtml model page =
    let
        pageBackground =
            if page.begin < model.playhead then
                "rgba(1.0, 0.8, 0.8, 1.0)"

            else
                "rgba(0.9, 0.9, 0.9, 0.8)"
    in
    div
        [ style "background-color" pageBackground
        ]
    <|
        List.map (lyricsLineHtml model) page.lines


statusMessage : String -> Element Msg
statusMessage s =
    el [ centerX, padding 100, Font.size 36 ] (text s)


lyricsHtml : Model -> Element Msg
lyricsHtml model =
    case ( model.waveformLength, model.lyrics ) of
        ( Success _, Success lyrics ) ->
            html <| div [] <| List.map (lyricsLineHtml model) <| List.concatMap .lines lyrics

        ( NotAsked, _ ) ->
            statusMessage "La de da"

        ( Failure e, _ ) ->
            statusMessage e

        ( Loading, _ ) ->
            statusMessage "Loading"

        ( _, NotAsked ) ->
            statusMessage "La de da"

        ( _, Loading ) ->
            statusMessage "Loading"

        ( _, Failure e ) ->
            statusMessage <| errorToString e



lyricsSection : Model -> Element Msg
lyricsSection model =
    row
        [ centerX
        , alignTop
        , width fill
        ]
        [ lyricsHtml model ]


viewEditor : Model -> Element Msg
viewEditor model =
    column
        [ centerX
        , alignTop
        , width fill
        , htmlAttribute <| style "z-index" "5"
        ]
        [ lyricsSection model
        ]


saveLink : Model -> Element Msg
saveLink model =
    case model.lyricsChanged of
        True ->
            el
                [ width (px controlsWidth)
                , Events.onClick <| SaveLyrics
                ]
                (text "Save")

        False ->
            el
                [ width (px controlsWidth) ]
                (text "Saved")


header : Model -> Element Msg
header model =
    row
        [ width fill
        , alignTop
        , padding headerPadding
        , spacing 10
        , Background.color <| rgba 0.8 0.8 0.8 1.0
        ]
        [ returnLink
        , songHeader model
        , saveLink model
        ]


view : Model -> Html Msg
view model =
    layout
        [ inFront <| header model
        ]
    <|
        row
            [ width fill
            , alignTop
            , centerX
            , paddingEach { top = headerHeight + waveformSpacing, right = 0, bottom = 0, left = 0 }
            ]
            [ waveform model
            ]

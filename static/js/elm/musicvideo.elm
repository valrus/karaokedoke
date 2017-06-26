module MusicVideo exposing (..)

import AnimationFrame
import Html
import Platform.Cmd exposing ((!))
import Svg exposing (Svg)
import Time exposing (Time)

--

import Lyrics.Data exposing (lyrics)
import Lyrics.Model exposing (Lyric, LyricLine, LyricBook)
import Lyrics.Style exposing (lyricBaseFontTTF, lyricBaseFontName, svgScratchId)
import Model exposing (..)
import Ports exposing (..)
import Update exposing (..)
import View exposing (view)


init : ( Model, Cmd Msg )
init =
    { playhead = 0.0
    , page = Nothing
    , playing = Loading
    , lyrics = lyrics
    , duration = 0.0
    , dragging = False
    }
        ! [ loadFonts [ { name = lyricBaseFontName, path = lyricBaseFontTTF } ] ]


lyricToSvg : Lyric -> Svg Msg
lyricToSvg lyric =
    Svg.g []
        [ Svg.text_ []
            [ Svg.text lyric.text ]
        ]


animateMsg : Model -> (Time -> Msg)
animateMsg model =
    case model.dragging of
        True ->
            WithTime <| Animate <| Just model.playhead

        False ->
            WithTime <| Animate Nothing


playStateOnLoad : Bool -> PlayState
playStateOnLoad success =
    case success of
        True ->
            Loading

        False ->
            Error


toPlayState : Bool -> PlayState
toPlayState playing =
    case playing of
        True ->
            Playing

        False ->
            Paused


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs <| animateMsg model
        , loadedFonts (AtTime << SetPlayState << playStateOnLoad)
        , playState (AtTime << SetPlayState << toPlayState)
        , gotSizes (AtTime << SetPageSizes)
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

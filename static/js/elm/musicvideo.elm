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
import Scrubber.Model
import Model exposing (..)
import Ports
import Update exposing (..)
import View exposing (view)


init : ( Model, Cmd Msg )
init =
    { page = Nothing
    , playing = Loading
    , lyrics = lyrics
    , scrubber = Scrubber.Model.init
    }
        ! [ Ports.jsLoadFonts [ { name = lyricBaseFontName, path = lyricBaseFontTTF } ] ]


lyricToSvg : Lyric -> Svg Msg
lyricToSvg lyric =
    Svg.g []
        [ Svg.text_ []
            [ Svg.text lyric.text ]
        ]


animateMsg : Scrubber.Model.Model -> (Time -> Msg)
animateMsg scrubber =
    case scrubber.dragging of
        True ->
            WithTime <| Animate <| Just scrubber.playhead

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
        [ AnimationFrame.diffs <| animateMsg model.scrubber
        , Ports.loadedFonts (AtTime << SetPlayState << playStateOnLoad)
        , Ports.playState (AtTime << SetPlayState << toPlayState)
        , Ports.gotSizes (AtTime << SetPageSizes)
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

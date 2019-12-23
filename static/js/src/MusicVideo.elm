module MusicVideo exposing (..)

--

import Browser exposing (application)
import Browser.Events exposing (onAnimationFrameDelta)
import Helpers exposing (Milliseconds)
import Html
import Lyrics.Model exposing (Lyric, LyricBook, LyricLine)
import Lyrics.Style exposing (lyricBaseFontName, lyricBaseFontTTF, svgScratchId)
import Model exposing (..)
import Ports
import Scrubber.Model
import Svg exposing (Svg)
import Time exposing (Posix)
import Update exposing (..)
import View exposing (view)


type alias Flags
    = {}


lyrics : LyricBook
lyrics =
    []

init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { page = Nothing
      , playing = Loading
      , lyrics = lyrics
      , scrubber = Scrubber.Model.init
      }
    , Ports.jsLoadFonts [ { name = lyricBaseFontName, path = lyricBaseFontTTF } ]
    )


lyricToSvg : Lyric -> Svg Msg
lyricToSvg lyric =
    Svg.g []
        [ Svg.text_ []
            [ Svg.text lyric.text ]
        ]


animateMsg : Scrubber.Model.Model -> (Float -> Msg)
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
        [ onAnimationFrameDelta <| animateMsg model.scrubber
        , Ports.loadedFonts (Immediately << SetPlayState << playStateOnLoad)
        , Ports.playState (Immediately << SetPlayState << toPlayState)
        , Ports.gotSizes (Immediately << SetPageSizes)
        ]


main =
    application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickLink
        , onUrlChange = ChangeUrl
        }

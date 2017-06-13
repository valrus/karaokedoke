module MusicVideo exposing (..)

import AnimationFrame
import Html
import Platform.Cmd exposing ((!))
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Task
import Time exposing (Time)
import Debug exposing (log)

--

import Lyrics.Data exposing (lyrics)
import Lyrics.Model exposing (Lyric, LyricLine, LyricBook)
import Lyrics.Style exposing (lyricBaseFontTTF, lyricBaseFontName)
import Model exposing (..)
import Ports exposing (playState, playhead, gotSizes, getSizes)
import Update exposing (..)
import View exposing (view)


init : ( Model, Cmd Msg )
init =
    { playhead = 0.0
    , page = Nothing
    , playing = False
    , lyrics = []
    , duration = 0.0
    , dragging = False
    }
        ! [ getSizes
                { lyrics = lyrics
                , fontPath = lyricBaseFontTTF
                , fontName = lyricBaseFontName
                }
          ]


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs <| animateMsg model
        , playState (AtTime << PlayState)
        , playhead (AtTime
                        << (uncurry SyncPlayhead)
                        << (Tuple.mapFirst ((*) Time.second))
                        << (Tuple.mapSecond ((*) Time.second))
                   )
        , gotSizes (AtTime << SetLyricSizes)
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

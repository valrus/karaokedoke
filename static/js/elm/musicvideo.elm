port module MusicVideo exposing (..)

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
import Update exposing (..)
import View exposing (view, lyricBefore)


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


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


pageIsBefore : Time -> SizedLyricPage -> Bool
pageIsBefore t page =
    List.head page.content
        |> Maybe.andThen (.content >> List.head)
        |> lyricBefore t


findPage : SizedLyricBook -> Time -> Maybe SizedLyricPage
findPage book time =
    last <| List.filter (pageIsBefore time) book


animateTime : Model -> Time -> Maybe Time -> Time
animateTime model delta override =
    case override of
        Just newTime ->
            newTime

        Nothing ->
            model.playhead
                + (if model.playing then
                    delta
                    else
                    0
                  )


updateModel : ModelMsg -> Time -> Model -> Model
updateModel msg delta model =
    case msg of
        SetLyricSizes result ->
            case result of
                Nothing ->
                    model

                Just sizedLyrics ->
                    { model
                        | lyrics = (log "lyrics" sizedLyrics)
                    }

        PlayState playing ->
            { model
                | playing = playing
            }

        Animate timeOverride ->
            let
                newTime =
                    animateTime model delta timeOverride
            in
                { model
                    | playhead = newTime
                    , page = findPage model.lyrics newTime
                }

        SyncPlayhead duration playheadTime ->
            { model
                | duration = duration
                , playhead = playheadTime
            }

        NoOp ->
            model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AtTime wrappedMsg ->
            ( model, Task.perform (WithTime wrappedMsg) Time.now )

        WithTime modelMsg time ->
            updateModel modelMsg time model
                ! [ Cmd.none ]

        TogglePlayback ->
            model ! [ togglePlayback (not model.playing) ]

        SetPlayhead pos ->
            { model | dragging = False }
            ! [ seekTo pos ]

        ScrubberDrag dragging ->
            { model | dragging = dragging } ! [ togglePlayback False ]


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Maybe SizedLyricBook -> msg) -> Sub msg


port playhead : (( Float, Float ) -> msg) -> Sub msg


port getSizes : { lyrics : LyricBook, fontPath : String, fontName : String } -> Cmd msg


port togglePlayback : Bool -> Cmd msg


port seekTo : Float -> Cmd msg


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

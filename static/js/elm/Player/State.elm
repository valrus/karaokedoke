module Player.State exposing (..)

import Browser.Events exposing (onAnimationFrameDelta)
import Debug exposing (log)
import Ports
import Task
import Time

--

import Helpers exposing (Milliseconds, inSeconds, seconds)
import Lyrics.Model exposing (..)
import Lyrics.Style exposing (lyricBaseFontName, svgScratchId)
import Song exposing (Song, SongId)
import Scrubber.State as Scrubber


type PlayState
    = Loading
    | Paused
    | Playing
    | Ended
    | Error


type alias Model =
    { song : Song
    , page : Maybe SizedLyricPage
    , playing : PlayState
    , lyrics : LyricBook
    , scrubber : Scrubber.Model
    }


init : SongId -> Song -> ( Model, Cmd Msg )
init _ song =
    ( { song = song
      , page = Nothing
      , playing = Loading
      , lyrics = []
      , scrubber = Scrubber.init
      }
    , Cmd.none
    )


type Msg
    = Immediately ModelMsg
    | WithTime ModelMsg Milliseconds
    | TogglePlayback
    | SetPlayhead Milliseconds


type ModelMsg
    = SetPageSizes (Maybe SizedLyricPage)
    | SetDuration Milliseconds
    | SetPlayState PlayState
    | SyncPlayhead Milliseconds
    | MoveScrubberCursor Float
    | DragScrubber Float
    | LeaveScrubber
    | Animate (Maybe Milliseconds)
    | NoOp


animateTime : Model -> Milliseconds -> Maybe Milliseconds -> Milliseconds
animateTime model delta override =
    case override of
        Just newTime ->
            newTime

        Nothing ->
            if model.playing == Playing then
                (seconds model.scrubber.playhead) + delta
            else
                0


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


pageStartTime : LyricPage -> Maybe Milliseconds
pageStartTime page =
    Just page.begin


sizedPageStartTime : SizedLyricPage -> Maybe Milliseconds
sizedPageStartTime =
    .content >> List.head >> Maybe.map .content >> Maybe.map .begin


pageIsBefore : Milliseconds -> LyricPage -> Bool
pageIsBefore t page =
    List.head page.lines
        |> Maybe.andThen (Just << .tokens)
        |> Maybe.andThen List.head
        |> lyricBefore t


findPage : Milliseconds -> LyricBook -> Maybe LyricPage
findPage time book =
    last <| List.filter (pageIsBefore time) book


pagesMatch : SizedLyricPage -> LyricPage -> Bool
pagesMatch sizedPage otherPage =
    sizedPageStartTime sizedPage == pageStartTime otherPage



-- Get the Cmd, if necessary, for fetching sizes for a new page.


getNewPage : Maybe SizedLyricPage -> Maybe LyricPage -> Cmd Msg
getNewPage prevPage nextPage =
    case ( prevPage, nextPage ) of
        ( _, Nothing ) ->
            Cmd.none

        ( Nothing, Just newPage ) ->
            Ports.jsGetSizes
                { lyrics = newPage
                , scratchId = svgScratchId
                , fontName = lyricBaseFontName
                }

        ( Just oldPage, Just newPage ) ->
            if pagesMatch oldPage newPage then
                Cmd.none

            else
                Ports.jsGetSizes
                    { lyrics = newPage
                    , scratchId = svgScratchId
                    , fontName = lyricBaseFontName
                    }


updateModel : ModelMsg -> Milliseconds -> Model -> ( Model, Cmd Msg )
updateModel msg delta model =
    case msg of
        SetPageSizes result ->
            case result of
                Nothing ->
                    ( model
                    , Cmd.none
                    )

                Just sizedLyricPage ->
                    ( { model
                        | page = Just sizedLyricPage
                      }
                    , Cmd.none
                    )

        SetDuration time ->
            ( { model
                | scrubber = Scrubber.setDuration time model.scrubber
              }
            , Cmd.none
            )

        SetPlayState playing ->
            ( { model
                | playing = log "SetPlayState" playing
              }
            , Cmd.none
            )

        Animate timeOverride ->
            let
                newTime =
                    animateTime model delta timeOverride

                newPage =
                    findPage newTime model.lyrics
            in
            ( { model
                | scrubber = Scrubber.setPlayhead newTime model.scrubber
              }
            , getNewPage model.page newPage
            )

        SyncPlayhead playheadTime ->
            ( { model
                | scrubber = Scrubber.setPlayhead playheadTime model.scrubber
              }
            , Cmd.none
            )

        MoveScrubberCursor cursorXProportion ->
            ( { model
                | scrubber = Scrubber.moveCursor (log "scrubCursor" cursorXProportion) model.scrubber
              }
            , Cmd.none
            )

        DragScrubber playheadProportion ->
            ( { model
                | scrubber = Scrubber.dragPlayhead playheadProportion model.scrubber
              }
            , if model.playing == Playing then
                Ports.jsSetPlayback False

              else
                Cmd.none
            )

        LeaveScrubber ->
            ( { model
                | scrubber = log "LeaveScrubber" Scrubber.mouseLeave model.scrubber
              }
            , Cmd.none
            )

        NoOp ->
            ( model
            , Cmd.none
            )


togglePlaybackIfPossible : PlayState -> Cmd Msg
togglePlaybackIfPossible state =
    case state of
        Playing ->
            Ports.jsSetPlayback False

        Paused ->
            Ports.jsSetPlayback True

        _ ->
            Cmd.none


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        Immediately wrappedMsg ->
            ( model
            , Task.perform
                (WithTime wrappedMsg)
                (Task.map (Time.posixToMillis >> toFloat) Time.now)
            )

        WithTime modelMsg millis ->
            let
                result =
                    updateModel modelMsg millis model
            in
            ( Tuple.first result
            , Tuple.second result
            )

        TogglePlayback ->
            ( model
            , togglePlaybackIfPossible model.playing
            )

        SetPlayhead pos ->
            ( { model | scrubber = Scrubber.stopDragging model.scrubber }
            , Ports.jsSeekTo (log "seekTo" (inSeconds pos))
            )


-- Subscriptions and related functions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onAnimationFrameDelta <| animateMsg model.scrubber
        , Ports.loadedFonts (Immediately << SetPlayState << playStateOnLoad)
        , Ports.playState (Immediately << SetPlayState << toPlayState)
        , Ports.gotSizes (Immediately << SetPageSizes)
        ]


animateMsg : Scrubber.Model -> (Float -> Msg)
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

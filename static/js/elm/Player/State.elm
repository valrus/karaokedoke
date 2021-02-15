module Player.State exposing (..)

--

import Browser.Events exposing (onAnimationFrameDelta)
import Debug exposing (log)
import Helpers exposing (Milliseconds, inSeconds, seconds)
import Http exposing (Error(..))
import Json.Decode as D
import Lyrics.Model exposing (..)
import Lyrics.Style exposing (leagueGothicFontData, leagueGothicFontName, svgScratchId)
import Ports
import RemoteData exposing (RemoteData(..), WebData, unwrap)
import Scrubber.State as Scrubber
import Song exposing (Prepared, Song, SongId, songDecoder)
import Task
import Time
import Url.Builder


type PlayState
    = Paused
    | Playing
    | Ended
    | Error


type alias Model =
    { songId : SongId
    , song : WebData (Prepared Song)
    , songUrl : WebData String
    , page : Maybe SizedLyricPage
    , playing : PlayState
    , lyrics : WebData LyricBook
    , scrubber : Scrubber.Model
    , fontsLoaded : Bool
    }


init : SongId -> ( Model, Cmd Msg )
init songId =
    ( { songId = songId
      , song = Loading
      , songUrl = Loading
      , page = Nothing
      , playing = Paused
      , lyrics = Loading
      , scrubber = Scrubber.init
      , fontsLoaded = False
      }
    , Cmd.batch
        [ Http.get
            { url = Url.Builder.absolute [ "lyrics", songId ] []
            , expect = Http.expectJson (GotLyrics >> Immediately) lyricBookDecoder
            }
        , Http.get
            { url = Url.Builder.absolute [ "api", "song_data", songId ] []
            , expect = Http.expectJson (GotSong >> Immediately) songDecoder
            }
        , Ports.jsLoadFonts [ leagueGothicFontData ]
        ]
    )


type Msg
    = Immediately ModelMsg
    | WithTime ModelMsg Milliseconds
    | TogglePlayback
    | SetPlayhead Milliseconds


type ModelMsg
    = GotSong (Result Http.Error (Prepared Song))
    | GotLyrics (Result Http.Error LyricBook)
    | GotFonts Bool
    | SetPageSizes (Result D.Error SizedLyricPage)
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
                model.scrubber.playhead + delta

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


pagesMatch : SizedLyricPage -> LyricPage -> Bool
pagesMatch sizedPage otherPage =
    sizedPageStartTime sizedPage == pageStartTime otherPage



-- Get the Cmd, if necessary, for fetching sizes for a new page.


getNewPage : Maybe SizedLyricPage -> Maybe LyricPage -> Cmd Msg
getNewPage prevPage nextPage =
    case (log "getNewPage args" ( prevPage, nextPage )) of
        ( _, Nothing ) ->
            Cmd.none

        ( Nothing, Just newPage ) ->
            Ports.jsGetSizes
                { lyrics = newPage
                , scratchId = svgScratchId
                , fontName = leagueGothicFontName
                }

        ( Just oldPage, Just newPage ) ->
            if pagesMatch oldPage newPage then
                Cmd.none

            else
                Ports.jsGetSizes
                    { lyrics = newPage
                    , scratchId = svgScratchId
                    , fontName = leagueGothicFontName
                    }


updateModel : ModelMsg -> Milliseconds -> Model -> ( Model, Cmd Msg )
updateModel msg delta model =
    case msg of
        GotSong (Ok song) ->
            ( { model | song = Success song }, Cmd.none )

        GotSong (Err error) ->
            ( { model | song = Failure error }, Cmd.none )

        GotLyrics (Ok lyrics) ->
            ( { model | lyrics = Success lyrics }, Cmd.none )

        GotLyrics (Err error) ->
            ( { model | song = Failure error }, Cmd.none )

        GotFonts fontsLoaded ->
            ( { model | fontsLoaded = fontsLoaded }, Cmd.none )

        SetPageSizes (Err error) ->
            ( { model | song = Failure <| BadBody <| D.errorToString error }
            , Cmd.none
            )

        SetPageSizes (Ok result) ->
            ( { model | page = Just (log "SetPageSizes result" result) }
            , Cmd.none
            )

        SetDuration time ->
            ( { model | scrubber = Scrubber.setDuration time model.scrubber }
            , Cmd.none
            )

        SetPlayState playing ->
            ( { model | playing = log "SetPlayState" playing }
            , Cmd.none
            )

        Animate timeOverride ->
            let
                newTime =
                    animateTime model delta timeOverride

                newPage =
                    unwrap Nothing (pageAtTime newTime) model.lyrics
            in
            ( { model | scrubber = Scrubber.setPlayhead newTime model.scrubber }
            , getNewPage model.page newPage
            )

        SyncPlayhead playheadTime ->
            ( { model
                | scrubber = Scrubber.setPlayhead (log "SyncPlayhead" playheadTime) model.scrubber
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
    Sub.batch <|
        [ Ports.loadedFonts (Immediately << GotFonts)
        , Ports.playState (Immediately << SetPlayState << toPlayState)
        , Ports.playhead (Immediately << SyncPlayhead)
        , Ports.gotSizes (Immediately << SetPageSizes << D.decodeValue sizedLyricPageDecoder)
        ]
            ++ (if model.playing == Playing then
                    [ onAnimationFrameDelta <| animateMsg model.scrubber ]

                else
                    []
               )


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
            Paused

        False ->
            Error


toPlayState : Bool -> PlayState
toPlayState playing =
    case playing of
        True ->
            Playing

        False ->
            Paused

module Player.State exposing (..)

--

import Browser.Events exposing (onAnimationFrameDelta)
import Debug exposing (log)
import Helpers exposing (Milliseconds, Seconds, inSeconds, seconds)
import Http exposing (Error(..))
import Json.Decode as D
import Lyrics.Decode exposing (lyricBookDecoder, sizedLyricPageDecoder)
import Lyrics.Model exposing (..)
import Lyrics.Style exposing (leagueGothicFontData, leagueGothicFontName, svgScratchId)
import Player.Ports as Ports
import RemoteData exposing (RemoteData(..), WebData, unwrap)
import Scrubber.Helpers exposing (WaveformLengthResult, waveformInitResultDecoder)
import Scrubber.Ports as ScrubberPorts
import Song exposing (Prepared, Song, SongId, songDecoder)
import Task
import Time
import Url.Builder


type alias Model =
    { songId : SongId
    , song : WebData (Prepared Song)
    , songUrl : WebData String
    , page : Maybe SizedLyricPage
    , playing : Bool
    , lyrics : WebData LyricBook
    , waveformLength : WaveformLengthResult
    , playhead : Milliseconds
    , fontsLoaded : Bool
    }


waveformContainerName : String
waveformContainerName =
    "waveform"


init : SongId -> ( Model, Cmd Msg )
init songId =
    ( { songId = songId
      , song = Loading
      , songUrl = Loading
      , page = Nothing
      , playing = False
      , lyrics = Loading
      , waveformLength = NotAsked
      , playhead = 0
      , fontsLoaded = False
      }
    , Cmd.batch
        [ Http.get
            { url = Url.Builder.absolute [ "lyrics", songId ] []
            , expect = Http.expectJson GotLyrics lyricBookDecoder
            }
        , Http.get
            { url = Url.Builder.absolute [ "api", "song_data", songId ] []
            , expect = Http.expectJson GotSong songDecoder
            }
        , Ports.jsLoadFonts [ leagueGothicFontData ]
        ]
    )


type Msg
    = GotSong (Result Http.Error (Prepared Song))
    | GotLyrics (Result Http.Error LyricBook)
    | GotWaveform (Result D.Error WaveformLengthResult)
    | GotFonts Bool
    | SetPageSizes (Result D.Error SizedLyricPage)
    | PlayPause
    | ChangedPlaystate (Result D.Error Bool)
    | SetPlayhead (Result D.Error Seconds)
    | NoOp


animateTime : Model -> Milliseconds -> Maybe Milliseconds -> Milliseconds
animateTime model delta override =
    case override of
        Just newTime ->
            newTime

        Nothing ->
            if model.playing == True then
                model.playhead + delta

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
    case ( prevPage, nextPage ) of
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


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        GotSong (Ok song) ->
            ( { model | song = Success song }, Cmd.none )

        GotSong (Err error) ->
            ( { model | song = Failure error }, Cmd.none )

        GotLyrics (Ok lyrics) ->
            ( { model | lyrics = Success lyrics }
            , Ports.jsPlayerInitWaveform <|
                { containerId = waveformContainerName
                , songUrl = Url.Builder.absolute [ "accompaniment", model.songId ] []
                }
            )

        GotLyrics (Err error) ->
            ( { model | song = Failure error }, Cmd.none )

        GotFonts fontsLoaded ->
            ( { model | fontsLoaded = fontsLoaded }, Cmd.none )

        GotWaveform (Err waveformResultDecodeError) ->
            ( { model | waveformLength = Failure (log "waveformErr" (D.errorToString waveformResultDecodeError)) }
            , Cmd.none
            )

        GotWaveform (Ok result) ->
            ( { model | waveformLength = result }
            , Cmd.none
            )

        SetPageSizes (Err error) ->
            ( { model | song = Failure <| BadBody <| D.errorToString error }
            , Cmd.none
            )

        SetPageSizes (Ok result) ->
            ( { model | page = Just result }
            , Cmd.none
            )

        PlayPause ->
            ( { model | playing = not model.playing }
            , ScrubberPorts.jsPlayPause model.playing )

        ChangedPlaystate (Err error) ->
            ( model, Cmd.none )

        ChangedPlaystate (Ok playing) ->
            ( { model | playing = playing }
            , Cmd.none
            )

        SetPlayhead (Err error) ->
            ( model, Cmd.none )

        SetPlayhead (Ok positionInSeconds) ->
            let
                newPage =
                    unwrap Nothing (pageAtTime <| seconds positionInSeconds) model.lyrics
            in
            ( { model | playhead = seconds positionInSeconds }
            , getNewPage model.page newPage
            )

        NoOp ->
            ( model
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        [ Ports.loadedFonts GotFonts
        , ScrubberPorts.changedPlaystate (ChangedPlaystate << D.decodeValue D.bool)
        , ScrubberPorts.movedPlayhead (SetPlayhead << D.decodeValue D.float)
        , Ports.gotSizes (SetPageSizes << D.decodeValue sizedLyricPageDecoder)
        , ScrubberPorts.gotWaveformLength (GotWaveform << D.decodeValue waveformInitResultDecoder)
        ]

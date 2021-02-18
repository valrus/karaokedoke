module Editor.State exposing (..)

--

import Debug exposing (log)
import Editor.Ports as Ports
import Helpers exposing (Milliseconds, Seconds, seconds)
import Http
import Json.Decode as D
import List exposing (filter)
import Lyrics.Model exposing (LyricBook, allLines, lyricBookDecoder)
import RemoteData exposing (RemoteData(..), WebData)
import Song exposing (Prepared, Song, SongId, songDecoder)
import Url.Builder


type alias WaveformResult =
    RemoteData String ()


type alias Model =
    { songId : SongId
    , song : WebData (Prepared Song)
    , lyrics : WebData LyricBook
    , waveform : WaveformResult
    , snipping : Bool
    , playhead : Milliseconds
    , playing : Bool
    }


type Msg
    = GotSong (Result Http.Error (Prepared Song))
    | GotLyrics (Result Http.Error LyricBook)
    | MoveLyric
    | GotWaveform (Result D.Error WaveformResult)
    | ClickedSnipStrip
    | Snipped
    | CanceledSnip
    | SetPlayhead (Result D.Error Seconds)
    | PlayPause Bool
    | ChangedPlaystate (Result D.Error Bool)


waveformContainerName : String
waveformContainerName =
    "waveform"


init : SongId -> ( Model, Cmd Msg )
init songId =
    ( { songId = songId
      , song = Loading
      , lyrics = Loading
      , waveform = NotAsked
      , snipping = False
      , playhead = 0
      , playing = False
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
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.gotWaveform (GotWaveform << D.decodeValue waveformInitResultDecoder)
        , Ports.movePlayhead (SetPlayhead << D.decodeValue D.float)
        , Ports.changedPlaystate (ChangedPlaystate << D.decodeValue D.bool)
        ]


makeWaveformResult : Bool -> String -> WaveformResult
makeWaveformResult success errorMsg =
    case success of
        True ->
            Success ()

        False ->
            Failure errorMsg


waveformInitResultDecoder : D.Decoder WaveformResult
waveformInitResultDecoder =
    D.map2 makeWaveformResult (D.at [ "success" ] D.bool) (D.at [ "error" ] D.string)


makeRegions : LyricBook -> List Ports.WaveformRegion
makeRegions lyrics =
    List.map
        (\line ->
            { id = line.id
            , start = Helpers.inSeconds line.begin
            }
        )
    <|
        allLines lyrics


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        GotLyrics (Ok lyricBook) ->
            ( { model | lyrics = Success lyricBook, waveform = Loading }
            , Ports.jsEditorInitWaveform <|
                { containerId = waveformContainerName
                , songUrl = Url.Builder.absolute [ "api", "songs", model.songId ] []
                }
            )

        GotLyrics (Err error) ->
            ( { model | lyrics = Failure error }, Cmd.none )

        GotSong (Ok song) ->
            ( { model | song = Success song }, Cmd.none )

        GotSong (Err error) ->
            ( { model | song = Failure error }, Cmd.none )

        MoveLyric ->
            ( model, Cmd.none )

        GotWaveform (Err waveformResultDecodeError) ->
            ( { model | waveform = Failure (D.errorToString waveformResultDecodeError) }, Cmd.none )

        GotWaveform (Ok result) ->
            ( { model | waveform = log "GotWaveform Ok" result }
            , Ports.jsEditorCreateRegions <| RemoteData.unwrap [] makeRegions model.lyrics
            )

        ClickedSnipStrip ->
            ( { model | snipping = True }, Cmd.none )

        Snipped ->
            ( { model | snipping = False }, Cmd.none )

        CanceledSnip ->
            ( { model | snipping = False }, Cmd.none )

        SetPlayhead (Err error) ->
            ( model, Cmd.none )

        SetPlayhead (Ok positionInSeconds) ->
            ( { model | playhead = seconds positionInSeconds }
            , Cmd.none
            )

        PlayPause playing ->
            ( model, Ports.jsEditorPlayPause playing )

        ChangedPlaystate (Err error) ->
            ( model, Cmd.none )

        ChangedPlaystate (Ok playing) ->
            ( { model | playing = playing }, Cmd.none )

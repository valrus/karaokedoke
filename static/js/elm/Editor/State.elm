module Editor.State exposing (..)

--

import Debug exposing (log)
import Http
import Json.Decode as D
import List exposing (filter)
import Lyrics.Model exposing (LyricBook, lyricBookDecoder)
import Ports
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
    }


type Msg
    = GotSong (Result Http.Error (Prepared Song))
    | GotLyrics (Result Http.Error LyricBook)
    | MoveLyric
    | GotWaveform (Result D.Error WaveformResult)


waveformContainerName : String
waveformContainerName =
    "waveform"


init : SongId -> ( Model, Cmd Msg )
init songId =
    ( { songId = songId
      , song = Loading
      , lyrics = Loading
      , waveform = NotAsked
      }
    , Cmd.batch
        [ Http.get
            { url = Url.Builder.absolute [ "api", "lyrics", songId ] []
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
            ( { model | waveform = log "GotWaveform Ok" result }, Cmd.none )

module Editor.State exposing (..)

--

import Debug exposing (log)
import Http
import List exposing (filter)
import Lyrics.Model exposing (LyricBook, lyricBookDecoder)
import Ports
import RemoteData exposing (RemoteData(..), WebData)
import Song exposing (Song, SongId, Prepared, songDecoder)
import Url.Builder


type alias Model =
    { songId : SongId
    , song : WebData (Prepared Song)
    , lyrics : WebData LyricBook
    , waveformAvailable : Bool
    }


type Msg
    = GotSong (Result Http.Error (Prepared Song))
    | GotLyrics (Result Http.Error LyricBook)
    | MoveLyric
    | GotWaveform


waveformContainerName : String
waveformContainerName =
    "waveform"


init : SongId -> ( Model, Cmd Msg )
init songId =
    ( { songId = songId
      , song = Loading
      , lyrics = Loading
      , waveformAvailable = False
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


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        GotLyrics (Ok lyricBook) ->
            ( { model | lyrics = Success lyricBook }
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

        GotWaveform ->
            ( { model | waveformAvailable = True }, Cmd.none )

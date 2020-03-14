module Editor.State exposing (..)

--

import Debug exposing (log)
import Http
import List exposing (filter)
import RemoteData exposing (WebData, RemoteData(..))
import Url.Builder

--

import Lyrics.Model exposing (LyricBook, lyricBookDecoder)
import Ports
import Song exposing (Song, SongId)


type alias Model =
    { songId : SongId
    , song : Song
    , lyrics : WebData LyricBook
    , waveformAvailable : Bool
    }


type Msg
    = GotLyrics (Result Http.Error LyricBook)
    | MoveLyric
    | GotWaveform


waveformContainerName : String
waveformContainerName =
    "waveform"


init : SongId -> Song -> ( Model, Cmd Msg )
init songId song =
    ( { songId = songId
      , song = song
      , lyrics = Loading
      , waveformAvailable = False
      }
    , Http.get
        { url = Url.Builder.absolute [ "api", "lyrics", songId ] []
        , expect = Http.expectJson GotLyrics lyricBookDecoder
        }
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

        MoveLyric ->
            ( model, Cmd.none )

        GotWaveform ->
            ( { model | waveformAvailable = True }, Cmd.none )

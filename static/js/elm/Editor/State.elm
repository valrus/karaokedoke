module Editor.State exposing (..)

--

import List exposing (filter)

--

import Lyrics.Model exposing (LyricBook)
import Song exposing (Song, SongId)


type alias Model =
    { song : Song
    , lyrics : LyricBook
    }


init : Song -> ( Model, Cmd Msg )
init song =
    ( { song = song
      , lyrics = [] -- note: init with the song lyrics
      }
    , Cmd.none
    )


type Msg
    = MoveLyric


update : Model -> Msg -> Model
update model msg =
    case msg of
        MoveLyric ->
            model

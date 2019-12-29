module Editor.State exposing (..)

--

import List exposing (filter)

--

import Lyrics.Model exposing (LyricBook)
import Dashboard.State exposing (Song, SongId)


type alias Model =
    { song : Song
    , lyrics : LyricBook
    }


init : Song -> Model
init song =
    { song = song
    , lyrics = [] -- note: init with the song lyrics
    }


type Msg
    = MoveLyric


update : Model -> Msg -> Model
update model msg =
    case msg of
        MoveLyric ->
            model

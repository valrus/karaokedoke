module Editor.Model exposing (Model)

--

import Lyrics.Model exposing (LyricBook)
import Dashboard.Model exposing (Song)


type alias Model =
    { song : Song
    , lyrics : LyricBook
    }

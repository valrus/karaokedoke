module Dashboard.Model exposing (Model, Song, SongId)

--

import Lyrics.Model exposing (LyricBook)


type alias SongId
    = String


type alias Song =
    { id : SongId
    , name : String
    , artist : String
    , hasLyrics : Bool
    , hasBackingTrack : Bool
    , hasVocalTrack : Bool
    , hasSyncMap : Bool
    }

type alias Model =
    List Song

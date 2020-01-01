module Song exposing (..)

import Json.Decode as Decode exposing (..)

-- import Lyrics.Model exposing (LyricBook)


type alias SongId
    = String


type alias Song =
    { id : SongId
    , name : String
    , artist : String
    , prepared : Bool
    }


type alias SongList =
    List Song


songDecoder : Decode.Decoder Song
songDecoder =
    Decode.map4 Song
    (at ["id"] Decode.string)
    (at ["name"] Decode.string)
    (at ["artist"] Decode.string)
    (at ["prepared"] Decode.bool)


songListDecoder : Decode.Decoder SongList
songListDecoder =
    at ["songs"] <| Decode.list songDecoder

module Song exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (..)

-- import Lyrics.Model exposing (LyricBook)


type alias SongId
    = String


type alias Song =
    { name : String
    , artist : String
    , prepared : Bool
    }


type alias SongDict =
    Dict SongId Song


songDecoder : Decode.Decoder Song
songDecoder =
    Decode.map3 Song
    (at ["name"] Decode.string)
    (at ["artist"] Decode.string)
    (at ["prepared"] Decode.bool)


songDictDecoder : Decode.Decoder SongDict
songDictDecoder =
    at ["songs"] <| Decode.dict songDecoder

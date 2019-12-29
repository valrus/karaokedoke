module Dashboard.State exposing (..)

--

import Http
import Json.Decode as Decode exposing (..)
import List exposing (filter)
import RemoteData exposing (..)
import Url.Builder

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


type alias SongList =
    List Song


type alias Model =
    WebData SongList


type Msg
    = AddSong Song
    | DeleteSong SongId
    | GotSongList (WebData SongList)


update : Model -> Msg -> Model
update model msg =
    case msg of
        AddSong song ->
            RemoteData.map ((::) song) model

        DeleteSong songId ->
            RemoteData.map (filter (.id >> (/=) songId)) model

        GotSongList songListResult ->
            songListResult


songDecoder : Decode.Decoder Song
songDecoder =
    Decode.map7 Song
    (at ["id"] Decode.string)
    (at ["name"] Decode.string)
    (at ["artist"] Decode.string)
    (at ["hasLyrics"] Decode.bool)
    (at ["hasBackingTrack"] Decode.bool)
    (at ["hasVocalTrack"] Decode.bool)
    (at ["hasSyncMap"] Decode.bool)


songListDecoder : Decode.Decoder SongList
songListDecoder =
    Decode.list songDecoder


init : ( Model, Cmd Msg )
init =
    ( RemoteData.Loading
    , Http.get
        { url = Url.Builder.relative ["list"] []
        , expect = Http.expectJson (fromResult >> GotSongList) songListDecoder
        }
    )

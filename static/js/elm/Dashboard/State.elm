module Dashboard.State exposing (..)

--

import List exposing (filter)

--

import Song exposing (..)


type alias Model =
    ()


type Msg
    = AddSong Song
    | DeleteSong SongId


updateSongList : Msg -> SongList -> SongList
updateSongList msg songList =
    case msg of
        AddSong song ->
            song :: songList

        DeleteSong songId ->
            filter (.id >> (/=) songId) songList


init : ( Model, Cmd Msg )
init =
    ( (), Cmd.none )

module Dashboard.Update exposing (Msg, update)

--

import List exposing (filter)

--

import Dashboard.Model exposing (Model, Song, SongId)


type Msg
    = AddSong Song
    | DeleteSong SongId


update : Model -> Msg -> Model
update model msg =
    case msg of
        AddSong song ->
            song :: model

        DeleteSong songId ->
            filter (.id >> (/=) songId) model

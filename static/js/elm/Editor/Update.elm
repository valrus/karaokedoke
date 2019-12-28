module Editor.Update exposing (Msg, update)

--

import List exposing (filter)

--

import Dashboard.Model exposing (Model, Song, SongId)


type Msg
    = MoveLyric


update : Model -> Msg -> Model
update model msg =
    case msg of
        MoveLyric ->
            model

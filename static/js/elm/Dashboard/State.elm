module Dashboard.State exposing (..)

--

import File exposing (File)
import List exposing (filter)

--

import Song exposing (..)


type alias Model =
    { dragging : Bool }


type Msg
    = AddSong Song
    | DeleteSong SongId
    | DragEnter
    | DragLeave
    | ProcessFiles File (List File)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragEnter ->
            ( { model | dragging = True }, Cmd.none )

        DragLeave ->
            ( { model | dragging = False }, Cmd.none )

        ProcessFiles file files ->
            ( { model | dragging = False }, Cmd.none )

        _ ->
            ( model, Cmd.none )


updateSongList : Msg -> SongList -> SongList
updateSongList msg songList =
    case msg of
        AddSong song ->
            song :: songList

        DeleteSong songId ->
            filter (.id >> (/=) songId) songList

        _ ->
            songList


init : ( Model, Cmd Msg )
init =
    ( { dragging = False }, Cmd.none )

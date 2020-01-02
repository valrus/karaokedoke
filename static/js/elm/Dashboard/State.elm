module Dashboard.State exposing (..)

--

import File exposing (File)
import Dict
import Http
import Json.Decode as D
import List exposing (filter)
import RemoteData exposing (fromResult)
import Url.Builder

--

import Helpers exposing (errorToString)
import Song exposing (..)


type alias Model =
    { dragging : Bool }


type Msg
    = AddUploadedSongs (Result Http.Error SongDict)
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
            ( { model | dragging = False }
            , Http.post
                { url = Url.Builder.relative ["songs"] []
                , body = Http.multipartBody <| List.map (Http.filePart "song[]") <| file :: files
                , expect = Http.expectJson AddUploadedSongs <| songDictDecoder
                }
            )

        _ ->
            ( model, Cmd.none )


updateSongDict : Msg -> SongDict -> SongDict
updateSongDict msg songDict =
    case msg of
        AddUploadedSongs (Ok songUpload) ->
            Dict.union songUpload songDict

        AddUploadedSongs (Err songUploadError) ->
            -- TODO replace ugly debugger code with actual error handling
            Dict.singleton "err" { name = errorToString songUploadError, artist = "-", prepared = False }

        DeleteSong songId ->
            Dict.remove songId songDict

        _ ->
            songDict


init : ( Model, Cmd Msg )
init =
    ( { dragging = False }, Cmd.none )

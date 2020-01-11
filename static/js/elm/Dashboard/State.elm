module Dashboard.State exposing (..)

--

import File exposing (File)
import Dict
import Http
import Json.Decode as D
import Ports
import List exposing (filter)
import RemoteData exposing (fromResult)
import Url.Builder

--

import Helpers exposing (errorToString)
import Song exposing (..)


type alias Model =
    { dragging : Bool }


type alias ProcessingEvent =
    { processingState : ProcessingState
    , songId : SongId
    }


type Msg
    = AddUploadedSongs (Result Http.Error SongUpload)
    | DeleteSong SongId
    | DragEnter
    | DragLeave
    | ProcessFiles File (List File)
    | HandleProcessingEvent (Result D.Error ProcessingEvent)


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
                , expect = Http.expectJson AddUploadedSongs <| songUploadDecoder
                }
            )

        _ ->
            ( model, Cmd.none )


updateSongWithState : ProcessingState -> Maybe (Processed Song) -> Maybe (Processed Song)
updateSongWithState newState currentSong =
    Maybe.map (updateProcessingState newState) currentSong


updateSongDict : Msg -> SongDict -> SongDict
updateSongDict msg songDict =
    case msg of
        AddUploadedSongs (Ok songUpload) ->
            mergeSongUploads songUpload songDict

        AddUploadedSongs (Err songUploadError) ->
            -- TODO replace ugly debugger code with actual error handling
            Dict.singleton "err" { name = "-", artist = "-", processingState = Failed (errorToString songUploadError) }

        DeleteSong songId ->
            Dict.remove songId songDict

        HandleProcessingEvent (Ok processingEvent) ->
            Dict.update processingEvent.songId (updateSongWithState processingEvent.processingState) songDict

        HandleProcessingEvent (Err eventDecodeError) ->
            songDict

        _ ->
            songDict


init : ( Model, Cmd Msg )
init =
    ( { dragging = False }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.processingEvent (HandleProcessingEvent << D.decodeValue processingEventDecoder)


makeProcessingEvent : String -> String -> String -> ProcessingEvent
makeProcessingEvent event task songId =
    let
        processingState =
            case "event" of
                "start" ->
                    InProgress task

                "step" ->
                    InProgress task

                "success" ->
                    Complete

                "error" ->
                    Failed "Error processing song"

                _ ->
                    Failed <| "Invalid processing event: " ++ event

    in
        { processingState = processingState, songId = songId }


processingEventDecoder : D.Decoder ProcessingEvent
processingEventDecoder =
    D.map3 makeProcessingEvent
        (D.at ["event"] D.string)
        (D.at ["task"] D.string)
        (D.at ["songId"] D.string)

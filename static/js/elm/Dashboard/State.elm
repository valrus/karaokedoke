module Dashboard.State exposing (..)

--

import File exposing (File)
import Debug
import Dict
import Http
import Json.Decode as D
import Ports
import List exposing (filter)
import RemoteData exposing (WebData, fromResult)
import Url.Builder

--

import Helpers exposing (errorToString)
import Song exposing (..)


type alias Model =
    { dragging : Bool }


type alias ProcessingEvent =
    { state : ProcessingState
    , songId : SongId
    }


type Msg
    = AddUploadedSongs (Result Http.Error SongUpload)
    | DeleteSongData SongId
    | RemoveSong SongId (Result Http.Error ())
    | DragEnter
    | DragLeave
    | ProcessFiles File (List File)
    | HandleProcessingEvent (Result D.Error ProcessingEvent)


updateSongWithState : ProcessingState -> Maybe (Processed Song) -> Maybe (Processed Song)
updateSongWithState newState currentSong =
    Maybe.map (updateProcessingState newState) currentSong


updateSongDict : Model -> WebData SongDict -> ( Model, WebData SongDict, Cmd Msg )
updateSongDict model songDict =
    ( model, songDict, Cmd.none )


update : Model -> Msg -> (WebData SongDict) -> ( Model, WebData SongDict, Cmd Msg )
update model msg songDict =
    case msg of
        AddUploadedSongs (Ok songUpload) ->
            updateSongDict model <| RemoteData.succeed <|
                mergeSongUploads songUpload <| RemoteData.withDefault Dict.empty songDict

        AddUploadedSongs (Err songUploadError) ->
            updateSongDict model <| RemoteData.Failure <| songUploadError

        RemoveSong songId _ ->
            updateSongDict model <| RemoteData.map (Dict.remove songId) songDict

        DeleteSongData songId ->
            ( model
            , songDict
            , Http.request
                { method = "DELETE"
                , headers = []
                , url = Url.Builder.absolute ["api", "songs", songId] []
                , body = Http.emptyBody
                , expect = Http.expectWhatever <| (RemoveSong songId)
                , timeout = Nothing
                , tracker = Nothing
                }
                )

        DragEnter ->
            ( { model | dragging = True }, songDict, Cmd.none )

        DragLeave ->
            ( { model | dragging = False }, songDict, Cmd.none )

        HandleProcessingEvent (Ok processingEvent) ->
            updateSongDict model <| RemoteData.map
                (Dict.update processingEvent.songId <| updateSongWithState processingEvent.state) songDict

        HandleProcessingEvent (Err eventDecodeError) ->
            updateSongDict model songDict

        ProcessFiles file files ->
            ( { model | dragging = False }
            , songDict
            , Http.post
                { url = Url.Builder.absolute ["api", "songs"] []
                , body = Http.multipartBody <| List.map (Http.filePart "song[]") <| file :: files
                , expect = Http.expectJson AddUploadedSongs songUploadDecoder
                }
            )


init : ( Model, Cmd Msg )
init =
    ( { dragging = False }
    , Http.get
        { url = Url.Builder.absolute ["api", "songs"] []
        , expect = Http.expectJson AddUploadedSongs songUploadDecoder
        }
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.processingEvent (HandleProcessingEvent << D.decodeValue processingEventDecoder)


makeProcessingEvent : String -> String -> String -> ProcessingEvent
makeProcessingEvent event task songId =
    let
        processingState =
            case (Debug.log "event" event) of
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
        { state = processingState, songId = songId }


processingEventDecoder : D.Decoder ProcessingEvent
processingEventDecoder =
    D.map3 makeProcessingEvent
        (D.at ["event"] D.string)
        (D.at ["task"] D.string)
        (D.at ["songId"] D.string)

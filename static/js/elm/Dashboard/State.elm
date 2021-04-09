module Dashboard.State exposing (..)

--

import File exposing (File)
import File.Select as Select
import Debug
import Dict
import Http
import Json.Decode as D
import Ports
import List exposing (filter)
import RemoteData exposing (RemoteData(..), WebData, fromResult)
import Url.Builder

--

import Helpers exposing (errorToString)
import Song exposing (..)


type alias YoutubeData =
    { song : String
    , artist : String
    , url : String
    }


type YoutubeField
    = YoutubeSong
    | YoutubeArtist
    | YoutubeUrl


blankYoutubeData : YoutubeData
blankYoutubeData =
    { song = ""
    , artist = ""
    , url = ""
    }


type DashboardState
    = Default
    | ShowingYoutubeDialog YoutubeData
    | Dragging


type alias Model =
    { songDict : WebData SongDict
    , state : DashboardState
    }


type alias ProcessingEvent =
    { state : ProcessingState
    , songId : SongId
    }


type Msg
    = AddUploadedSongs (Result Http.Error SongUpload)
    | DeleteSongData SongId
    | RemoveSong SongId (Result Http.Error ())
    | DragEnter
    | RestoreDefaultState
    | ShowYoutubeDialog
    | UpdateYoutubeData YoutubeField String
    | FilesRequested
    | YoutubeRequested
    | ProcessFiles File (List File)
    | HandleProcessingEvent (Result D.Error ProcessingEvent)


updateSongWithState : ProcessingState -> Maybe (Processed Song) -> Maybe (Processed Song)
updateSongWithState newState currentSong =
    Maybe.map (updateProcessingState newState) currentSong


updateSongDict : Model -> WebData SongDict -> ( Model, Cmd Msg )
updateSongDict model songDict =
    ( { model | songDict = songDict }, Cmd.none )


updateYoutubeData : YoutubeData -> YoutubeField -> String -> YoutubeData
updateYoutubeData data field s =
    case field of
      YoutubeSong ->
          { data | song = s }

      YoutubeArtist ->
          { data | artist = s }

      YoutubeUrl ->
          { data | url = s }


update : Model -> Msg -> (WebData SongDict) -> ( Model, Cmd Msg )
update model msg songDict =
    case msg of
        AddUploadedSongs (Ok songUpload) ->
            updateSongDict model
                <| RemoteData.succeed
                <| mergeSongUploads songUpload
                <| RemoteData.withDefault Dict.empty songDict

        AddUploadedSongs (Err songUploadError) ->
            updateSongDict model <| RemoteData.Failure <| songUploadError

        RemoveSong songId _ ->
            updateSongDict model <| RemoteData.map (Dict.remove songId) songDict

        DeleteSongData songId ->
            ( model
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
            ( { model | state = Dragging }, Cmd.none )

        RestoreDefaultState ->
            ( { model | state = Default }, Cmd.none )

        HandleProcessingEvent (Ok processingEvent) ->
            updateSongDict model
                <| RemoteData.map
                    (Dict.update processingEvent.songId <| updateSongWithState processingEvent.state)
                    songDict

        HandleProcessingEvent (Err eventDecodeError) ->
            updateSongDict model songDict

        FilesRequested ->
            ( model, Select.files ["audio/mpeg"] ProcessFiles )

        ShowYoutubeDialog ->
            ( { model | state = ShowingYoutubeDialog blankYoutubeData }, Cmd.none )

        UpdateYoutubeData field s ->
            case model.state of
                ShowingYoutubeDialog youtubeData ->
                    ( { model | state = ShowingYoutubeDialog <| updateYoutubeData youtubeData field s }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        YoutubeRequested ->
            ( model, Cmd.none )

        ProcessFiles file files ->
            ( { model | state = Default }
            , Http.post
                { url = Url.Builder.absolute ["api", "songs"] []
                , body = Http.multipartBody <| List.map (Http.filePart "song[]") <| file :: files
                , expect = Http.expectJson AddUploadedSongs songUploadDecoder
                }
            )


init : ( Model, Cmd Msg )
init =
    ( { songDict = NotAsked
      , state = Default
      }
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

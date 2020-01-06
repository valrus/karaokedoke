module Song exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (..)

-- import Lyrics.Model exposing (LyricBook)


type alias SongId
    = String


type ProcessingState
    = NotStarted
    | InProgress String
    | Complete
    | Failed


type alias Song =
    { name : String
    , artist : String
    }


type alias Processed t =
    { t | processingState : ProcessingState }


type alias Prepared t =
    { t | prepared : Bool }


type alias SongDict =
    Dict SongId (Processed Song)


type alias SongUpload =
    Dict SongId (Prepared Song)


makePreparedSong : String -> String -> Bool -> (Prepared Song)
makePreparedSong name artist prepared =
    { name = name
    , artist = artist
    , prepared = prepared
    }


songDecoder : Decode.Decoder (Prepared Song)
songDecoder =
    Decode.map3 makePreparedSong
    (at ["name"] Decode.string)
    (at ["artist"] Decode.string)
    (at ["prepared"] Decode.bool)


songUploadDecoder : Decode.Decoder SongUpload
songUploadDecoder =
    at ["songs"] <| Decode.dict songDecoder


-- merge :
-- (comparable -> a -> result -> result) ->
-- (comparable -> a -> b -> result -> result) ->
-- (comparable -> b -> result -> result) ->
-- Dict comparable a -> Dict comparable b -> result -> result

-- If the song is only in the upload, use ProcessingState NotStarted
-- If the song is in both and the SongUpload shows the song is prepared,
-- set the song's ProcessingState to Complete
-- If the song is in both but not prepared, leave it alone so as not to
-- override the current processing state
-- If the song is only in the dict, leave it

mergeUploadOnly : SongId -> (Prepared Song) -> SongDict -> SongDict
mergeUploadOnly songId upload =
    Dict.insert songId <|
        { name = upload.name
        , artist = upload.artist
        , processingState = NotStarted
        }


mergeConflict : SongId -> (Prepared Song) -> (Processed Song) -> SongDict -> SongDict
mergeConflict songId upload existingSong =
    let
        processingState =
            case upload.prepared of
                True ->
                    Complete

                False ->
                    existingSong.processingState

    in
        Dict.insert songId <| { existingSong | processingState = processingState }


mergeSongUploads : SongUpload -> SongDict -> SongDict
mergeSongUploads songUpload songDict =
    Dict.merge mergeUploadOnly mergeConflict Dict.insert songUpload songDict Dict.empty

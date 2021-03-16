module Editor.State exposing (..)

--

import Debug exposing (log)
import Dict exposing (Dict)
import Editor.Ports as Ports
import Helpers exposing (Milliseconds, Seconds, seconds)
import Http
import Json.Decode as D
import List exposing (filter)
import Lyrics.Model exposing (LyricBook, LyricId, allLines, lyricBookDecoder, secondsStringAsMillisecondsDecoder)
import RemoteData exposing (RemoteData(..), WebData)
import Song exposing (Prepared, Song, SongId, songDecoder)
import Url.Builder


type alias WaveformLengthResult =
    RemoteData String Milliseconds


type alias LyricPosition =
    { startTime : Milliseconds
    , topPixels : Int
    , bottomPixels : Int
    }


lyricPositionDecoder : D.Decoder ( LyricId, LyricPosition )
lyricPositionDecoder =
    D.map2 Tuple.pair
        (D.field "id" D.string)
        (D.map3 LyricPosition
             (D.map seconds <| D.field "start" D.float)
             (D.field "startPixels" D.int)
             (D.field "endPixels" D.int))


type alias Model =
    { songId : SongId
    , song : WebData (Prepared Song)
    , lyrics : WebData LyricBook
    , lyricPositions : Dict LyricId LyricPosition
    , waveformLength : WaveformLengthResult
    , playhead : Milliseconds
    , playing : Bool
    }


type Msg
    = GotSong (Result Http.Error (Prepared Song))
    | GotLyrics (Result Http.Error LyricBook)
    | MoveLyric
    | GotWaveform (Result D.Error WaveformLengthResult)
    | SetPlayhead (Result D.Error Seconds)
    | PlayPause Bool
    | ChangedPlaystate (Result D.Error Bool)
    | AddedRegion (Result D.Error ( LyricId, LyricPosition ))


waveformContainerName : String
waveformContainerName =
    "waveform"


init : SongId -> ( Model, Cmd Msg )
init songId =
    ( { songId = songId
      , song = Loading
      , lyrics = Loading
      , lyricPositions = Dict.empty
      , waveformLength = NotAsked
      , playhead = 0
      , playing = False
      }
    , Cmd.batch
        [ Http.get
            { url = Url.Builder.absolute [ "lyrics", songId ] []
            , expect = Http.expectJson GotLyrics lyricBookDecoder
            }
        , Http.get
            { url = Url.Builder.absolute [ "api", "song_data", songId ] []
            , expect = Http.expectJson GotSong songDecoder
            }
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.gotWaveformLength (GotWaveform << D.decodeValue waveformInitResultDecoder)
        , Ports.movedPlayhead (SetPlayhead << D.decodeValue D.float)
        , Ports.changedPlaystate (ChangedPlaystate << D.decodeValue D.bool)
        , Ports.addedRegion (AddedRegion << D.decodeValue lyricPositionDecoder)
        ]


makeWaveformResult : Maybe Float -> Maybe String -> WaveformLengthResult
makeWaveformResult waveformLength errorMsg =
    case ( waveformLength, errorMsg ) of
        ( Just length, _ ) ->
            Success (seconds length)

        ( _, Just error) ->
            Failure error

        _ ->
            Failure "Totally unrecognizable result from waveform initialization???"


waveformInitResultDecoder : D.Decoder WaveformLengthResult
waveformInitResultDecoder =
    D.map2 makeWaveformResult
        (D.at [ "length" ] (D.nullable D.float))
        (D.at [ "error" ] (D.nullable D.string))


makeRegions : LyricBook -> List Ports.WaveformRegion
makeRegions lyrics =
    List.map
        (\line ->
            { id = line.id
            , start = Helpers.inSeconds line.begin
            }
        )
    <|
        allLines lyrics


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        GotLyrics (Ok lyricBook) ->
            ( { model | lyrics = Success lyricBook, waveformLength = Loading }
            , Ports.jsEditorInitWaveform <|
                { containerId = waveformContainerName
                , songUrl = Url.Builder.absolute [ "api", "songs", model.songId ] []
                }
            )

        GotLyrics (Err error) ->
            ( { model | lyrics = Failure error }, Cmd.none )

        GotSong (Ok song) ->
            ( { model | song = Success song }, Cmd.none )

        GotSong (Err error) ->
            ( { model | song = Failure error }, Cmd.none )

        MoveLyric ->
            ( model, Cmd.none )

        GotWaveform (Err waveformResultDecodeError) ->
            ( { model | waveformLength = Failure (log "waveformErr" (D.errorToString waveformResultDecodeError)) }
            , Cmd.none )

        GotWaveform (Ok result) ->
            ( { model | waveformLength = log "GotWaveform Ok" result }
            , Ports.jsEditorCreateRegions <| RemoteData.unwrap [] makeRegions model.lyrics
            )

        AddedRegion (Err addedRegionDecodeError) ->
            ( { model | waveformLength = Failure (log "regionErr" (D.errorToString addedRegionDecodeError)) }
            , Cmd.none )

        AddedRegion (Ok ( id, pos )) ->
            ( { model | lyricPositions = Dict.insert id pos model.lyricPositions }
            , Cmd.none)

        SetPlayhead (Err error) ->
            ( model
            , Cmd.none )

        SetPlayhead (Ok positionInSeconds) ->
            ( { model | playhead = seconds positionInSeconds }
            , Cmd.none
            )

        PlayPause playing ->
            ( model, Ports.jsEditorPlayPause playing )

        ChangedPlaystate (Err error) ->
            ( model, Cmd.none )

        ChangedPlaystate (Ok playing) ->
            ( { model | playing = playing }, Cmd.none )

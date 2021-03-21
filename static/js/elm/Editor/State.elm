module Editor.State exposing (..)

--

import Debug exposing (log)
import Dict exposing (Dict)
import Editor.Ports as Ports
import Helpers exposing (Milliseconds, Seconds, seconds)
import Http
import Json.Decode as D
import Json.Encode
import List exposing (filter)
import Lyrics.Decode exposing (lyricBookDecoder)
import Lyrics.Encode exposing (encodeLyricBook)
import Lyrics.Model exposing (..)
import RemoteData exposing (RemoteData(..), WebData)
import Scrubber.Helpers exposing (..)
import Scrubber.Ports as ScrubberPorts
import Song exposing (Prepared, Song, SongId, songDecoder)
import Url.Builder


type alias LyricAdjustments =
    Dict LyricId LyricPosition


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
    , lyricPositions : LyricAdjustments
    , waveformLength : WaveformLengthResult
    , playhead : Milliseconds
    , playing : Bool
    , lyricsUnsaved : Bool
    }


type Msg
    = GotSong (Result Http.Error (Prepared Song))
    | GotLyrics (Result Http.Error LyricBook)
    | GotWaveform (Result D.Error WaveformLengthResult)
    | SetPlayhead (Result D.Error Seconds)
    | PlayPause Bool
    | ChangedPlaystate (Result D.Error Bool)
    | AddedRegion (Result D.Error ( LyricId, LyricPosition ))
    | LyricsSaved (Result Http.Error ())
    | SaveLyrics


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
      , lyricsUnsaved = False
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
        [ ScrubberPorts.gotWaveformLength (GotWaveform << D.decodeValue waveformInitResultDecoder)
        , ScrubberPorts.movedPlayhead (SetPlayhead << D.decodeValue D.float)
        , ScrubberPorts.changedPlaystate (ChangedPlaystate << D.decodeValue D.bool)
        , Ports.addedRegion (AddedRegion << D.decodeValue lyricPositionDecoder)
        ]


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


adjustTokens : Milliseconds -> List Lyric -> List Lyric
adjustTokens timeDelta lyrics =
    List.map (\lyric -> { lyric | begin = lyric.begin + timeDelta, end = lyric.end + timeDelta }) lyrics


adjustLine : LyricAdjustments -> LyricLine -> LyricLine
adjustLine lyricAdjustments line =
    let
        timeDelta =
            (-)
                ( Maybe.withDefault line.begin
                     <| Maybe.map .startTime
                     <| Dict.get line.id lyricAdjustments
                )
                line.begin

    in
        { line |
              tokens = adjustTokens timeDelta line.tokens,
              begin = (+) line.begin timeDelta,
              end = (+) line.end timeDelta
        }

adjustPage : LyricAdjustments -> LyricPage -> LyricPage
adjustPage lyricAdjustments page =
    let
        newLines =
            List.map (adjustLine lyricAdjustments) page.lines

    in
        { page |
              lines = newLines,
              begin = Maybe.withDefault 0 <| List.minimum <| List.map .begin newLines,
              end = Maybe.withDefault 0 <| List.maximum <| List.map .end newLines
        }


compileChanges : Model -> LyricBook
compileChanges model =
    List.map
        (adjustPage model.lyricPositions)
        <| RemoteData.withDefault [] model.lyrics


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
            ( { model | lyricPositions = Dict.insert id pos model.lyricPositions, lyricsUnsaved = True }
            , Cmd.none)

        SetPlayhead (Err error) ->
            ( model
            , Cmd.none )

        SetPlayhead (Ok positionInSeconds) ->
            ( { model | playhead = seconds positionInSeconds }
            , Cmd.none
            )

        PlayPause playing ->
            ( model, ScrubberPorts.jsPlayPause playing )

        ChangedPlaystate (Err error) ->
            ( model, Cmd.none )

        ChangedPlaystate (Ok playing) ->
            ( { model | playing = playing }, Cmd.none )

        LyricsSaved (Err error) ->
            ( model, Cmd.none )

        LyricsSaved (Ok ()) ->
            ( model, Cmd.none )

        SaveLyrics ->
            ( model
            , Http.request
                  { method = "PUT"
                  , headers = []
                  , url = Url.Builder.absolute ["api", "lyrics", model.songId] []
                  , body = Http.jsonBody <| Json.Encode.object [ ( "syncMap", encodeLyricBook <| compileChanges model ) ]
                  , expect = Http.expectWhatever LyricsSaved
                  , timeout = Nothing
                  , tracker = Nothing
                  }
            )

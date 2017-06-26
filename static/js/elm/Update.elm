module Update exposing (..)

import Task
import Time exposing (Time)
import Debug exposing (log)

--

import Lyrics.Model exposing (LyricBook, LyricPage)
import Lyrics.Style exposing (svgScratchId, lyricBaseFontName)
import Model exposing (Model, SizedLyricBook, SizedLyricPage, PlayState(..))
import Helpers exposing (lyricBefore)
import Ports exposing (getSizes, togglePlayback, seekTo)


type Msg
    = AtTime ModelMsg
    | WithTime ModelMsg Time
    | TogglePlayback
    | SetPlayhead Float
    | ScrubberDrag Bool


type ModelMsg
    = SetPageSizes (Maybe SizedLyricPage)
    | SetDuration Time
    | SetPlayState PlayState
    | SyncPlayhead Time
    | Animate (Maybe Time)
    | NoOp


animateTime : Model -> Time -> Maybe Time -> Time
animateTime model delta override =
    case override of
        Just newTime ->
            newTime

        Nothing ->
            model.playhead
                + (if (model.playing == Playing) then
                    delta
                    else
                    0
                  )


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


pageStartTime : LyricPage -> Maybe Time
pageStartTime page =
    List.head page
        |> Maybe.andThen List.head
        |> Maybe.andThen (Just << .time)


sizedPageStartTime : SizedLyricPage -> Maybe Time
sizedPageStartTime page =
    List.head page.content
        |> Maybe.andThen (Just << .content)
        |> Maybe.andThen List.head
        |> Maybe.andThen (Just << .time)


pageIsBefore : Time -> LyricPage -> Bool
pageIsBefore t page =
    List.head page
        |> Maybe.andThen List.head
        |> lyricBefore t


findPage : Time -> LyricBook -> Maybe LyricPage
findPage time book =
    last <| List.filter (pageIsBefore time) book


pagesMatch : SizedLyricPage -> LyricPage -> Bool
pagesMatch sizedPage otherPage =
    (sizedPageStartTime sizedPage == pageStartTime otherPage)


-- Get the Cmd, if necessary, for fetching sizes for a new page.
getNewPage : Maybe SizedLyricPage -> Maybe LyricPage -> Cmd Msg
getNewPage prevPage nextPage =
    case ( prevPage, nextPage ) of
        ( _, Nothing ) ->
            Cmd.none

        ( Nothing, Just newPage ) ->
            getSizes
                { lyrics = newPage
                , scratchId = svgScratchId
                , fontName = lyricBaseFontName
                }

        ( Just oldPage, Just newPage ) ->
            if (pagesMatch oldPage newPage) then
                Cmd.none
            else
                getSizes
                    { lyrics = newPage
                    , scratchId = svgScratchId
                    , fontName = lyricBaseFontName
                    }


updateModel : ModelMsg -> Time -> Model -> ( Model, Cmd Msg )
updateModel msg delta model =
    case msg of
        SetPageSizes result ->
            case result of
                Nothing ->
                    model ! [ Cmd.none ]

                Just sizedLyricPage ->
                    { model
                        | page = Just sizedLyricPage
                    } ! [ Cmd.none ]

        SetDuration time ->
            { model
                | duration = (log "SetDuration" time)
            } ! [ Cmd.none ]

        SetPlayState playing ->
            { model
                | playing = (log "SetPlayState" playing)
            } ! [ Cmd.none ]

        Animate timeOverride ->
            let
                newTime =
                    animateTime model delta timeOverride
                newPage =
                    findPage newTime model.lyrics
            in
                { model
                    | playhead = newTime
                } ! [ getNewPage model.page newPage ]

        SyncPlayhead playheadTime ->
            { model
                | playhead = playheadTime
            } ! [ Cmd.none ]

        NoOp ->
            model ! [ Cmd.none ]


togglePlaybackIfPossible : PlayState -> Cmd Msg
togglePlaybackIfPossible state =
    case state of
        Playing ->
            togglePlayback False

        Paused ->
            togglePlayback True

        _ ->
            Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AtTime wrappedMsg ->
            ( model, Task.perform (WithTime wrappedMsg) Time.now )

        WithTime modelMsg time ->
            let
                result =
                    updateModel modelMsg time model
            in
                (Tuple.first result) ! [ Tuple.second result ]

        TogglePlayback ->
            model ! [ togglePlaybackIfPossible model.playing ]

        SetPlayhead pos ->
            { model | dragging = False }
            ! [ seekTo pos ]

        ScrubberDrag dragging ->
            { model | dragging = dragging } ! [ togglePlayback False ]

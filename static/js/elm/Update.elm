module Update exposing (..)

import Task
import Time exposing (Time)

--

import Model exposing (Model, SizedLyricBook, SizedLyricPage)
import Helpers exposing (lyricBefore)
import Ports exposing (getSizes, togglePlayback, seekTo)


type Msg
    = AtTime ModelMsg
    | WithTime ModelMsg Time
    | TogglePlayback
    | SetPlayhead Float
    | ScrubberDrag Bool


type ModelMsg
    = SetLyricSizes (Maybe SizedLyricBook)
    | PlayState Bool
    | SyncPlayhead Time Time
    | Animate (Maybe Time)
    | NoOp


animateTime : Model -> Time -> Maybe Time -> Time
animateTime model delta override =
    case override of
        Just newTime ->
            newTime

        Nothing ->
            model.playhead
                + (if model.playing then
                    delta
                    else
                    0
                  )


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


pageIsBefore : Time -> SizedLyricPage -> Bool
pageIsBefore t page =
    List.head page.content
        |> Maybe.andThen (.content >> List.head)
        |> lyricBefore t


findPage : SizedLyricBook -> Time -> Maybe SizedLyricPage
findPage book time =
    last <| List.filter (pageIsBefore time) book


updateModel : ModelMsg -> Time -> Model -> Model
updateModel msg delta model =
    case msg of
        SetLyricSizes result ->
            case result of
                Nothing ->
                    model

                Just sizedLyrics ->
                    { model
                        | lyrics = sizedLyrics
                    }

        PlayState playing ->
            { model
                | playing = playing
            }

        Animate timeOverride ->
            let
                newTime =
                    animateTime model delta timeOverride
            in
                { model
                    | playhead = newTime
                    , page = findPage model.lyrics newTime
                }

        SyncPlayhead duration playheadTime ->
            { model
                | duration = duration
                , playhead = playheadTime
            }

        NoOp ->
            model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AtTime wrappedMsg ->
            ( model, Task.perform (WithTime wrappedMsg) Time.now )

        WithTime modelMsg time ->
            updateModel modelMsg time model
                ! [ Cmd.none ]

        TogglePlayback ->
            model ! [ togglePlayback (not model.playing) ]

        SetPlayhead pos ->
            { model | dragging = False }
            ! [ seekTo pos ]

        ScrubberDrag dragging ->
            { model | dragging = dragging } ! [ togglePlayback False ]

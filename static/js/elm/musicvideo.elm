port module MusicVideo exposing (..)

import AnimationFrame
import Array exposing (Array)
import Platform.Cmd exposing ((!))
import Html exposing (Html)
import Task
import Time exposing (Time)

import Lyrics exposing (..)


type Msg
    = AtTime ModelMsg
    | WithTime ModelMsg Time


type ModelMsg
    = PlayState Bool
    | Animate
    | NoOp


type alias Model =
    { lyrics : Array Lyric
    , playhead : Time
    , lyricIndex : Int
    , playing : Bool
    , display : Array String
    }


init : (Model, Cmd Msg)
init =
    { lyrics = lyrics
    , playhead = 0.0
    , lyricIndex = 0
    , playing = False
    , display = Array.fromList []
    }
    ! [ Cmd.none ]


view : Model -> Html Msg
view model =
    Html.div [] []


updateModel : ModelMsg -> Time -> Model -> Model
updateModel msg time model =
    case msg of
        PlayState playing ->
            { model
            | playing = playing
            }

        Animate ->
            let
                newTime = model.playhead + time
                nextLyric = findNextLyric model newTime
            in
                { model
                | playhead = newTime
                , display = updateDisplay model
                }

        NoOp ->
            model


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        AtTime wrappedMsg ->
            ( model, Task.perform (WithTime wrappedMsg) Time.now )

        WithTime modelMsg time ->
            updateModel modelMsg time model
            ! [ Cmd.none ]


port state : (Bool -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs (WithTime Animate)
        , state (AtTime << PlayState)
        ]


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
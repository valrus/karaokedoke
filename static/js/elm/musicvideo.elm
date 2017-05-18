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
    , startTime : Time
    , currentTime : Time
    , currentEventIndex : Int
    , playing : Bool
    }


init : (Model, Cmd Msg)
init =
    { lyrics = lyrics
    , startTime = 0.0
    , currentTime = 0.0
    , currentEventIndex = 0
    , playing = False
    }
    ! [ Cmd.none ]


view : Model -> Html Msg
view model =
    Html.div [] []


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        AtTime wrappedMsg ->
            ( model, Task.perform (WithTime wrappedMsg) Time.now )

        WithTime wrappedMsg time ->
            { model
            | startTime = time
            }
            ! [ Cmd.none ]


port state : (Bool -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.times (WithTime Animate)
        , state (AtTime << PlayState)
        ]


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
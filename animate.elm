import AnimationFrame
import Array exposing (Array)
import Platform.Cmd exposing ((!))
import Html exposing (Html)
import Time exposing (Time)

import Lyrics exposing (..)


type Msg =
    TimeUpdate Time
    | NoOp


type alias Model =
    { lyrics : Array Lyric
    , currentTime : Time
    , currentEventIndex : Int
    }


init : (Model, Cmd Msg)
init =
    { lyrics = lyrics
    , currentTime = 0.0
    , currentEventIndex = 0
    }
    ! [ Cmd.none ]


view : Model -> Html Msg
view model =
    Html.div [] []


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    (model, Cmd.none)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs TimeUpdate ]


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
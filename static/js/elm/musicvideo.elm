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
    { playhead : Time
    , page : Maybe LyricPage
    , playing : Bool
    }


init : ( Model, Cmd Msg )
init =
    { playhead = 0.0
    , page = Nothing
    , playing = False
    }
        ! [ Cmd.none ]


flattenPage : Time -> LyricPage -> List String
flattenPage time page =
    List.map
        (List.map .text << List.filter (Maybe.withDefault False << lyricBefore time)) page
        |> List.map (String.join "")


simpleDisplay : Time -> Maybe LyricPage -> Html Msg
simpleDisplay time mpage =
    case mpage of
        Nothing ->
            Html.div [] []

        Just page ->
            Html.div
                []
                <| List.map
                    (Html.p [] << List.singleton << Html.text)
                    (flattenPage time page)


view : Model -> Html Msg
view model =
    Html.div
        []
        [ simpleDisplay model.playhead model.page
        , Html.text <| toString <| Time.inSeconds model.playhead
        ]


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


lyricBefore : Time -> Lyric -> Maybe Bool
lyricBefore t lyric =
    Just (lyric.time < t)


pageBefore : Time -> LyricPage -> Bool
pageBefore t page =
    List.head page
        |> Maybe.andThen List.head
        |> Maybe.andThen (lyricBefore t)
        |> Maybe.withDefault False


findPage : LyricBook -> Time -> Maybe LyricPage
findPage lyrics time =
    last <| List.filter (pageBefore time) lyrics


updateModel : ModelMsg -> Time -> Model -> Model
updateModel msg time model =
    case msg of
        PlayState playing ->
            { model
                | playing = playing
            }

        Animate ->
            let
                newTime =
                    model.playhead + time
            in
                { model
                    | playhead = newTime
                    , page = findPage lyrics newTime
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

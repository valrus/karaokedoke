port module MusicVideo exposing (..)

import AnimationFrame
import Array exposing (Array)
import Platform.Cmd exposing ((!))
import Html exposing (Html)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Task
import Time exposing (Time)

import Lyrics exposing (..)

import Debug exposing (log)


type Msg
    = AtTime ModelMsg
    | WithTime ModelMsg Time


type ModelMsg
    = SetLyricSizes SizedLyricBook
    | PlayState Bool
    | Animate
    | NoOp


type alias Size =
    { height : Float
    , width : Float
    }


type alias Position =
    { x : Float
    , y : Float
    }


type alias Positioned t =
    { t | pos : Position }


type alias Sized t =
    { content : t
    , size : Size
    }

type alias Located t =
    { content : t
    , size : Size
    , pos : Position
    }

type alias LocatedLyricLine =
    Located (List Lyric)


type alias SizedLyricPage =
    Sized (List (LocatedLyricLine))


type alias SizedLyricBook =
    List SizedLyricPage


type alias Model =
    { playhead : Time
    , page : Maybe (SizedLyricPage)
    , playing : Bool
    , lyrics : SizedLyricBook
    }


init : ( Model, Cmd Msg )
init =
    { playhead = 0.0
    , page = Nothing
    , playing = False
    , lyrics = []
    }
    ! [ getSizes lyrics ]


-- pageLines : Time -> SizedLyricPage -> List String
-- pageLines time page =
--     List.map
--         (List.map .text << List.filter
--              <| Maybe.withDefault False << lyricBefore time) page
--         |> List.map (String.join "")


stringAttr : (String -> (Svg.Attribute msg)) -> a -> (Svg.Attribute msg)
stringAttr attr value =
    attr <| toString value


lyricToSvg : Lyric -> Svg Msg
lyricToSvg lyric =
    Svg.g
        []
        [ Svg.text_
              []
              [ Svg.text lyric.text ]
        ]


lineToSvg : Time -> LocatedLyricLine -> Svg Msg
lineToSvg time line =
    Svg.g
        []
        [ Svg.text_
              [ stringAttr SvgAttr.x line.pos.x
              , stringAttr SvgAttr.y line.pos.y
              ]
              [ List.filter (.time >> (>) time) line.content
                  |> List.map .text
                  |> String.join ""
                  |> Svg.text
              ]
        ]


lineBefore : Time -> LocatedLyricLine -> Bool
lineBefore t line =
    List.head line.content
        |> lyricBefore t


simpleDisplay : Time -> Maybe SizedLyricPage -> Html Msg
simpleDisplay time mpage =
    case mpage of
        Nothing ->
            Html.div [] []

        Just page ->
            Svg.svg
                []
                (List.map (lineToSvg time) <| List.filter (lineBefore time) page.content)


view : Model -> Html Msg
view model =
    Html.div
        []
        [ simpleDisplay model.playhead model.page
        ]


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


lyricBefore : Time -> Maybe Lyric -> Bool
lyricBefore t token =
    case token of
        Nothing ->
            False

        Just tok ->
          tok.time < t


pageIsBefore : Time -> SizedLyricPage -> Bool
pageIsBefore t page =
    List.head page.content
        |> Maybe.andThen (.content >> List.head)
        |> lyricBefore t


findPage : SizedLyricBook -> Time -> Maybe SizedLyricPage
findPage book time =
    last <| List.filter (pageIsBefore time) book


updateModel : ModelMsg -> Time -> Model -> Model
updateModel msg time model =
    case msg of
        SetLyricSizes sizedLyrics ->
            { model
                  | lyrics = (log "lyrics" sizedLyrics)
            }

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
                    , page = findPage model.lyrics newTime
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


port playState : (Bool -> msg) -> Sub msg
port gotSizes : (SizedLyricBook -> msg) -> Sub msg


port getSizes : LyricBook -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs (WithTime Animate)
        , playState (AtTime << PlayState)
        , gotSizes (AtTime << SetLyricSizes)
        ]


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

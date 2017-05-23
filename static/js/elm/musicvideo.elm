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


type alias Sized t =
    { size : Size
    , content : t
    }


type alias SvgData =
    { attrs : List (Svg.Attribute Msg)
    , elements : SvgElements
    }


type SvgElements =
    SvgElements (List (Located SvgData))


type alias Positioned t =
    { t | pos : Position }


type alias Located t =
    Positioned (Sized t)


type alias SizedLyricPage =
    Sized (List (SizedLyricsLine))


type alias SizedLyricsLine =
    Sized (List (Sized Lyric))


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


pageLines : Time -> SizedLyricPage -> List String
pageLines time page =
    List.map
        (List.map .text << List.filter
             <| Maybe.withDefault False << lyricBefore time) page
        |> List.map (String.join "")


nextLyricView : Sized Lyric -> Located (Svg Msg) -> Located (Svg Msg)
nextLyricView lyric prevSvg =
    Svg.svg
        []
        [ Svg.text_
              [ SvgAttr.x prevSvg.x + prevSvg.content.width
              , SvgAttr.y prevSvg.y
              ]
              [ Svg.text lyric.text ]
        ]


firstLyricSvg : Sized Lyric -> Located SvgData
firstLyricSvg lyric =
    { content =
          { attrs =
                [ SvgAttr.x "0"
                , SvgAttr.y "0"
                ]
          , elements =
              [ { attrs = []
                , elements = SvgElements ()
              ]
          }
    , pos = Position 0 0
    , size = lyric.size
    }


lyricLineView : SizedLyricsLine -> List (Located SvgData)
lyricLineView line =
    case Maybe.map2 (,) (List.head line.content) (List.tail line.content) of
        Just ( first, rest ) ->
            List.scanl
                nextLyricView
                (firstLyricSvg first)
                rest

        Nothing ->
            Svg.svg [] []


firstLineSvg : SizedLyricsLine -> Located SvgData
firstLineSvg line =
    { content =
          { attrs =
                [ SvgAttr.x "0"
                , SvgAttr.y "0"
                ]
          , elements =
              SvgElements (lyricLineView line)
          }
    , pos = Position 0 0
    , size = line.size
    }


nextLineView : SizedLyricsLine -> Located SvgData -> Located SvgData
nextLineView line prevSvg =
    let
        pos =
            Position 0 (prevSvg.pos.y + prevSvg.size.height)
    in
        { prevSvg
            | pos = pos
            , size = line.size
            , content =
              { attrs =
                    [ SvgAttr.x <| toString pos.x
                    , SvgAttr.y <| toString pos.y ]
              , elements =
                  SvgElements (lyricLineView line)
              }
        }


lyricPageView : SizedLyricPage -> List (Located SvgData)
lyricPageView page =
    case Maybe.map2 (,) (List.head page.content) (List.tail page.content) of
        Just ( first, rest ) ->
            List.scanl
                nextLineView
                (firstLineSvg first)
                rest

        Nothing ->
            [ ]


simpleDisplay : Time -> Maybe SizedLyricPage -> Html Msg
simpleDisplay time mpage =
    case mpage of
        Nothing ->
            Html.div [] []

        Just page ->
            Html.div
                []
                lyricPageView page


view : Model -> Html Msg
view model =
    Html.div
        []
        
        [ simpleDisplay model.playhead model.page
        ]


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


lyricBefore : Time -> Sized Lyric -> Maybe Bool
lyricBefore t token =
    Just (token.content.time < t)


pageIsBefore : Time -> SizedLyricPage -> Bool
pageIsBefore t page =
    List.head page.content
        |> Maybe.andThen (.content >> List.head)
        |> Maybe.andThen (lyricBefore t)
        |> Maybe.withDefault False


findPage : SizedLyricBook -> Time -> Maybe SizedLyricPage
findPage book time =
    last <| List.filter (pageIsBefore time) book


updateModel : ModelMsg -> Time -> Model -> Model
updateModel msg time model =
    case msg of
        SetLyricSizes sizedLyrics ->
            { model
                  | lyrics = sizedLyrics
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

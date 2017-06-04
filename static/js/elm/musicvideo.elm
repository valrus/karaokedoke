port module MusicVideo exposing (..)

import AnimationFrame
import Platform.Cmd exposing ((!))
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events
import List.Extra exposing (scanl1)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Task
import Time exposing (Time)
import Lyrics exposing (..)
import Debug exposing (log)


type Msg
    = AtTime ModelMsg
    | WithTime ModelMsg Time
    | TogglePlayback


type ModelMsg
    = SetLyricSizes (Maybe SizedLyricBook)
    | PlayState Bool
    | SyncPlayhead Time
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


type alias Height =
    { min : Float
    , max : Float
    }


type alias WithDims t =
    { content : t
    , width : Float
    , y : Height
    }


type alias Located t =
    { content : t
    , size : Size
    , pos : Position
    }


type alias SizedLyricPage =
    Sized (List (WithDims LyricLine))


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
        ! [ getSizes { lyrics = lyrics
                     , fontPath = lyricBaseFontTTF
                     , fontName = lyricBaseFontName
                     }
          ]



-- pageLines : Time -> SizedLyricPage -> List String
-- pageLines time page =
--     List.map
--         (List.map .text << List.filter
--              <| Maybe.withDefault False << lyricBefore time) page
--         |> List.map (String.join "")


controlFontSize : Float
controlFontSize =
    512.0


stringAttr : (String -> Svg.Attribute msg) -> a -> Svg.Attribute msg
stringAttr attr value =
    attr <| toString value


lyricToSvg : Lyric -> Svg Msg
lyricToSvg lyric =
    Svg.g []
        [ Svg.text_ []
            [ Svg.text lyric.text ]
        ]


fontScale : Float -> Float -> Float
fontScale extent controlWidth =
    (extent / controlWidth)


fontSizeToFill : Float -> Float -> Float
fontSizeToFill extent controlWidth =
    (fontScale extent controlWidth) * controlFontSize


lineToSvg : VerticalLine -> Svg Msg
lineToSvg line =
    Svg.g []
        [ Svg.text_
            [ stringAttr SvgAttr.x 0
            , stringAttr SvgAttr.y line.y
            , SvgAttr.fontSize
                <| toString line.fontSize
                ++ "px"
            ]
            [ line.content
            ]
        ]


type alias VerticalLine =
    { content : Svg Msg
    , fontSize : Float
    , height : Height
    , y : Float
    }


lineWithHeight : Time -> WithDims LyricLine -> VerticalLine
lineWithHeight time line =
    let
        factor = fontScale 1024.0 line.width

    in
        { content =
              List.filter (.time >> (>) time) line.content
            |> List.map .text
            |> String.join ""
            |> Svg.text
        , fontSize = fontSizeToFill 1024.0 line.width
        , height =
              { min = factor * line.y.min
              , max = factor * line.y.max
              }
        , y = factor * line.y.max
        }


accumulateHeights : VerticalLine -> VerticalLine -> VerticalLine
accumulateHeights this prev =
    { this
        | y = prev.y + (this.height.max - prev.height.min)
    }


lineBefore : Time -> WithDims LyricLine -> Bool
lineBefore t line =
    List.head line.content
        |> lyricBefore t


simpleDisplay : Time -> Maybe SizedLyricPage -> Html Msg
simpleDisplay time mpage =
    case mpage of
        Nothing ->
            Svg.svg [] []

        Just page ->
            Svg.svg
                [ SvgAttr.fontFamily lyricBaseFontName
                , SvgAttr.width "100%"
                , SvgAttr.height "100%"
                ]
                <| (List.filter (lineBefore time) page.content
                   |> List.map (lineWithHeight time)
                   |> scanl1 accumulateHeights
                   |> List.map lineToSvg
                   )


view : Model -> Html Msg
view model =
    Html.div
        [ HtmlAttr.style
            [ ( "width", "100%" )
            , ( "height", "100%" )
            ]
        , Html.Events.onClick TogglePlayback
        ]
        [ Html.div
            [ HtmlAttr.width 1024
            , HtmlAttr.style
                [ ( "margin", "auto auto" )
                , ( "width", "1024px" )
                ]
            ]
            [ simpleDisplay model.playhead model.page
            ]
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
        SetLyricSizes result ->
            case result of
                Nothing ->
                    model

                Just sizedLyrics ->
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
                    case model.playing of
                        True ->
                            model.playhead + time

                        False ->
                            model.playhead
            in
                { model
                    | playhead = newTime
                    , page = findPage model.lyrics newTime
                }

        SyncPlayhead playheadTime ->
            { model
                | playhead = playheadTime
                , page = findPage model.lyrics playheadTime
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
            model ! [ togglePlayback model.playing ]


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Maybe SizedLyricBook -> msg) -> Sub msg


port playhead : (Float -> msg) -> Sub msg


port getSizes : { lyrics: LyricBook, fontPath: String, fontName: String } -> Cmd msg


port togglePlayback : Bool -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs (WithTime Animate)
        , playState (AtTime << PlayState)
        , playhead (AtTime << SyncPlayhead << ((*) Time.second))
        , gotSizes (AtTime << SetLyricSizes)
        ]


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

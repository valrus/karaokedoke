port module MusicVideo exposing (..)

import AnimationFrame
import Platform.Cmd exposing ((!))
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events
import Json.Decode as Decode
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
    | SetPlayhead Float
    | ScrubberDrag Bool


type ModelMsg
    = SetLyricSizes (Maybe SizedLyricBook)
    | PlayState Bool
    | SyncPlayhead Time Time
    | Animate (Maybe Time)
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
    , duration : Time
    , dragging : Bool
    }


init : ( Model, Cmd Msg )
init =
    { playhead = 0.0
    , page = Nothing
    , playing = False
    , lyrics = []
    , duration = 0.0
    , dragging = False
    }
        ! [ getSizes
                { lyrics = lyrics
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
        factor =
            fontScale 1024.0 line.width
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


computePage : Time -> SizedLyricPage -> List (Svg Msg)
computePage time page =
    List.filter (lineBefore time) page.content
        |> List.map (lineWithHeight time)
        |> scanl1 accumulateHeights
        |> List.map lineToSvg


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
                <| computePage time page


toCssPercent : Float -> String
toCssPercent proportion =
    (toString (proportion * 100)) ++ "%"


decodeClickX : Decode.Decoder Float
decodeClickX =
    (Decode.map2 (/)
        (Decode.map2 (-)
            (Decode.at [ "pageX" ] Decode.float)
            (Decode.at [ "target", "offsetLeft" ] Decode.float)
        )
        (Decode.at [ "target", "offsetWidth" ] Decode.float)
    )


proportionInSeconds : Time -> Float -> Float
proportionInSeconds duration position =
    (duration * position) / Time.second


mouseScrub : Bool -> Time -> Decode.Decoder Msg
mouseScrub dragging duration =
    case dragging of
        True ->
            Decode.map
                (((*) duration)
                    >> ((SyncPlayhead duration) >> AtTime)) (decodeClickX)

        False ->
            Decode.succeed (AtTime NoOp)


mouseSeek : Time -> Decode.Decoder Msg
mouseSeek duration =
    Decode.map ((proportionInSeconds duration) >> SetPlayhead) (decodeClickX)


footer : Time -> Time -> Bool -> Html Msg
footer currTime duration dragging =
    Html.footer
        [ HtmlAttr.style
            [ ( "position", "fixed" )
            , ( "bottom", "0" )
            , ( "width", "100%" )
            , ( "height", "60px" )
            ]
        ]
        [ Html.div
            [ HtmlAttr.style
                [ ( "background", "#000" )
                , ( "width", toCssPercent (currTime / duration) )
                , ( "height", "100%" )
                ]
            ]
            []
        , Html.div
            [ HtmlAttr.style
                  [ ( "position", "absolute" )
                  , ( "bottom", "0" )
                  , ( "background", "#ccc" )
                  , ( "width", "100%" )
                  , ( "height", "100%" )
                  , ( "filter", "alpha(opacity=0)" )
                  , ( "opacity", "0" )
                  ]
            , Html.Events.onMouseDown (ScrubberDrag True)
            , Html.Events.on "mousemove" (mouseScrub dragging duration)
            , Html.Events.on "mouseup" (mouseSeek duration)
            ]
            []
        ]


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
        , footer model.playhead model.duration model.dragging
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


updateModel : ModelMsg -> Time -> Model -> Model
updateModel msg delta model =
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


port playState : (Bool -> msg) -> Sub msg


port gotSizes : (Maybe SizedLyricBook -> msg) -> Sub msg


port playhead : (( Float, Float ) -> msg) -> Sub msg


port getSizes : { lyrics : LyricBook, fontPath : String, fontName : String } -> Cmd msg


port togglePlayback : Bool -> Cmd msg


port seekTo : Float -> Cmd msg


animateMsg : Model -> (Time -> Msg)
animateMsg model =
    case model.dragging of
        True ->
            WithTime <| Animate <| Just model.playhead

        False ->
            WithTime <| Animate Nothing


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs <| animateMsg model
        , playState (AtTime << PlayState)
        , playhead (AtTime
                        << (uncurry SyncPlayhead)
                        << (Tuple.mapFirst ((*) Time.second))
                        << (Tuple.mapSecond ((*) Time.second))
                   )
        , gotSizes (AtTime << SetLyricSizes)
        ]


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

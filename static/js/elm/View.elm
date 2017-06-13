module View exposing (view)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events
import Json.Decode as Decode
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Time exposing (Time)

--

import List.Extra exposing (scanl1)

--

import Lyrics.Model exposing (Lyric, LyricLine)
import Lyrics.Style exposing (lyricBaseFontTTF, lyricBaseFontName)
import Model exposing (Model, SizedLyricPage, WithDims, Height)
import Update exposing (..)
import Helpers exposing (lyricBefore)


type alias VerticalLine =
    { content : Svg Msg
    , fontSize : Float
    , height : Height
    , y : Float
    }


lineBefore : Time -> WithDims LyricLine -> Bool
lineBefore t line =
    List.head line.content
        |> lyricBefore t


fontScale : Float -> Float -> Float
fontScale extent controlWidth =
    (extent / controlWidth)


controlFontSize : Float
controlFontSize =
    512.0


fontSizeToFill : Float -> Float -> Float
fontSizeToFill extent controlWidth =
    (fontScale extent controlWidth) * controlFontSize


lineWithHeight : Time -> WithDims LyricLine -> VerticalLine
lineWithHeight time line =
    let
        factor =
            fontScale 1024.0 line.width
    in
        { content =
            List.filter (Just >> lyricBefore time) line.content
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


stringAttr : (String -> Svg.Attribute msg) -> a -> Svg.Attribute msg
stringAttr attr value =
    attr <| toString value


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


computePage : Time -> SizedLyricPage -> List (Svg Msg)
computePage time page =
    List.filter (lineBefore time) page.content
        |> List.map (lineWithHeight time)
        |> scanl1 accumulateHeights
        |> List.map lineToSvg


viewPage : Time -> Maybe SizedLyricPage -> Html Msg
viewPage time mpage =
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


toCssPercent : Float -> String
toCssPercent proportion =
    (toString (proportion * 100)) ++ "%"


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
            [ viewPage model.playhead model.page
            ]
        , footer model.playhead model.duration model.dragging
        ]
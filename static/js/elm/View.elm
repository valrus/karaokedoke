module View exposing (view)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Time exposing (Time)

--

import List.Extra exposing (scanl1)

--

import Lyrics.Model exposing (Lyric, LyricLine)
import Lyrics.Style exposing (lyricBaseFontTTF, lyricBaseFontName, svgScratchId)
import Model exposing (Model, SizedLyricPage, WithDims, Height)
import Scrubber
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


footer : Model -> Html Msg
footer model =
    Html.footer
        [ HtmlAttr.style
            [ ( "position", "fixed" )
            , ( "bottom", "0" )
            , ( "left", "0" )
            , ( "width", "100%" )
            , ( "height", (toString Scrubber.scrubberHeight) ++ "px" )
            ]
        ]
        [ Scrubber.view model
        ]


scratch : Model -> Html Msg
scratch model =
    Html.div
        [ HtmlAttr.style
            [ ( "position", "absolute" )
            , ( "left", "-1024px" )
            , ( "width", "1024px" )
            , ( "height", "768px" )
            ]
        ]
        [ Svg.svg
            [ SvgAttr.id svgScratchId
            , SvgAttr.visibility "hidden"
            , SvgAttr.width "1024px"
            , SvgAttr.height "768px"
            , SvgAttr.fontFamily lyricBaseFontName
            , SvgAttr.fontSize "512px"
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
        [ scratch model
        , Html.div
            [ HtmlAttr.width 1024
            , HtmlAttr.style
                [ ( "margin", "auto auto" )
                , ( "width", "1024px" )
                ]
            ]
            [ viewPage model.playhead model.page
            ]
        , footer model
        ]
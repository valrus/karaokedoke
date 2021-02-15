module Player.View exposing (view)

--

import Debug exposing (log)
import AudioPlayer
import Helpers exposing (Milliseconds, seconds)
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events
import List.Extra exposing (scanl1)
import Lyrics.Model exposing (..)
import Lyrics.Style exposing (leagueGothicFontName, svgScratchId)
import Player.State exposing (..)
import RemoteData exposing (RemoteData(..))
import Scrubber.View
import String
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr


type alias VerticalLine =
    { content : Svg Msg
    , fontSize : Float
    , yRange : Range
    , y : Float
    }


lineBefore : Milliseconds -> SizedLyricLine -> Bool
lineBefore t line =
    List.head line.content.tokens
        |> lyricBefore t


fontScale : Float -> Float -> Float
fontScale extent controlWidth =
    extent / controlWidth


controlFontSize : Float
controlFontSize =
    512.0


fontSizeToFill : Float -> Float -> Float
fontSizeToFill extent controlWidth =
    fontScale extent controlWidth * controlFontSize


lineWithHeight : Milliseconds -> SizedLyricLine -> VerticalLine
lineWithHeight time line =
    let
        factor =
            fontScale 1024.0 line.width
    in
    { content =
        List.filter (Just >> lyricBefore time) line.content.tokens
            |> List.map .text
            |> String.join ""
            |> Svg.text
    , fontSize = fontSizeToFill 1024.0 line.width
    , yRange =
        { min = factor * line.yRange.min
        , max = factor * line.yRange.max
        }
    , y = factor * line.yRange.max
    }


accumulateHeights : VerticalLine -> VerticalLine -> VerticalLine
accumulateHeights this prev =
    { this
        | y = prev.y + (this.yRange.max - prev.yRange.min)
    }


stringAttr : (String -> Svg.Attribute msg) -> Float -> Svg.Attribute msg
stringAttr attr value =
    attr <| String.fromFloat value


lineToSvg : VerticalLine -> Svg Msg
lineToSvg line =
    Svg.g []
        [ Svg.text_
            [ stringAttr SvgAttr.x 0.0
            , stringAttr SvgAttr.y line.y
            , SvgAttr.fontSize <|
                String.fromFloat line.fontSize
                    ++ "px"
            ]
            [ line.content
            ]
        ]


lyricToSvg : Lyric -> Svg Msg
lyricToSvg lyric =
    Svg.g []
        [ Svg.text_ []
            [ Svg.text lyric.text ]
        ]


computePage : Milliseconds -> SizedLyricPage -> List (Svg Msg)
computePage time page =
    List.filter (lineBefore time) page.content
        |> List.map (lineWithHeight time)
        |> scanl1 accumulateHeights
        |> List.map lineToSvg


viewPage : Milliseconds -> Maybe SizedLyricPage -> Html Msg
viewPage time maybePage =
    case (log "maybePage" maybePage) of
        Nothing ->
            Svg.svg [] []

        Just page ->
            Svg.svg
                [ SvgAttr.fontFamily leagueGothicFontName
                , SvgAttr.width "100%"
                , SvgAttr.height "100%"
                ]
            <|
                computePage time page


footer : Model -> Html Msg
footer model =
    let
        footerContent =
            case model.lyrics of
                Success lyricBook ->
                    Scrubber.View.view model.scrubber lyricBook

                _ ->
                    Html.text "No lyrics"
    in
    Html.footer
        [ HtmlAttr.style "position" "fixed"
        , HtmlAttr.style "bottom" "0"
        , HtmlAttr.style "left" "0"
        , HtmlAttr.style "width" "100%"
        , HtmlAttr.style "height" (String.fromInt Scrubber.View.scrubberHeight ++ "px")
        ]
        [ footerContent
        ]


scratch : Model -> Html Msg
scratch model =
    Html.div
        [ HtmlAttr.style "position" "absolute"
        , HtmlAttr.style "left" "-1024px"
        , HtmlAttr.style "width" "1024px"
        , HtmlAttr.style "height" "768px"
        ]
        [ Svg.svg
            [ SvgAttr.id svgScratchId
            , SvgAttr.visibility "hidden"
            , SvgAttr.width "1024px"
            , SvgAttr.height "768px"
            , SvgAttr.fontFamily leagueGothicFontName
            , SvgAttr.fontSize "512px"
            ]
            []
        ]


view : Model -> Html Msg
view model =
    Html.div
        [ HtmlAttr.style "width" "100%"
        , HtmlAttr.style "height" "100%"
        , Html.Events.onMouseUp TogglePlayback
        ]
        [ scratch model
        , AudioPlayer.view model
        , Html.div
            [ HtmlAttr.width 1024
            , HtmlAttr.style "margin" "auto auto"
            , HtmlAttr.style "width" "1024px"
            ]
            [ viewPage model.scrubber.playhead model.page
            ]
        , footer model
        ]

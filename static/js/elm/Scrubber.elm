module Scrubber exposing (..)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events
import Json.Decode as Decode
import Time exposing (Time)

--

import Model exposing (Model)
import Update exposing (..)


toCssPercent : Float -> String
toCssPercent proportion =
    (toString (proportion * 100)) ++ "%"


proportionInSeconds : Time -> Float -> Float
proportionInSeconds duration position =
    (duration * position) / Time.second


decodeClickX : Decode.Decoder Float
decodeClickX =
    (Decode.map2 (/)
        (Decode.map2 (-)
            (Decode.at [ "pageX" ] Decode.float)
            (Decode.at [ "target", "offsetLeft" ] Decode.float)
        )
        (Decode.at [ "target", "offsetWidth" ] Decode.float)
    )


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


view : Model -> Html Msg
view model =
    Html.div
        [ HtmlAttr.style
            [ ( "id", "scrubber" )
            ]
        ]
        [ Html.div
            [ HtmlAttr.style
                [ ( "background", "#000" )
                , ( "width", toCssPercent (model.playhead / model.duration) )
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
            , Html.Events.on "mousemove" (mouseScrub model.dragging model.duration)
            , Html.Events.on "mouseup" (mouseSeek model.duration)
            ]
            []
        ]
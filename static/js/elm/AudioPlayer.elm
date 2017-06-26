module AudioPlayer exposing (view)

import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (on, onMouseDown)
import Json.Decode as Decode
import Time

--

import Model exposing (Model, PlayState(..))
import Update exposing (..)


decodeTargetAttribute : String -> Decode.Decoder a -> Decode.Decoder a
decodeTargetAttribute attr attrDecoder =
    Decode.at [ "target", attr ] attrDecoder


timeEvent : String -> String -> Decode.Decoder a -> (a -> msg) -> Html.Attribute msg
timeEvent evt attr decoder msg =
    on evt
        <| Decode.map msg
        <| decodeTargetAttribute attr decoder


fromSeconds : Float -> Time.Time
fromSeconds numSeconds =
    numSeconds * Time.second


view : Model -> Html Msg
view model =
    Html.audio
        [ HtmlAttr.id "audio-player"
        , HtmlAttr.src "static/audio/song.mp3"
        , HtmlAttr.type_ "audio/mp3"
        , timeEvent "timeupdate" "currentTime" Decode.float (fromSeconds >> SyncPlayhead >> AtTime)
        , timeEvent "loadedmetadata" "duration" Decode.float (fromSeconds >> SetDuration >> AtTime)
        , timeEvent "canplaythrough" "duration" (Decode.succeed Paused) (SetPlayState >> AtTime)
        , timeEvent "ended" "ended" (Decode.succeed Ended) (SetPlayState >> AtTime)
        , timeEvent "playing" "paused" (Decode.succeed Playing) (SetPlayState >> AtTime)
        , timeEvent "pause" "paused" (Decode.succeed Paused) (SetPlayState >> AtTime)
        ]
        [ ]

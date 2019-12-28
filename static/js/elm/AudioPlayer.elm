module AudioPlayer exposing (view)

--

import Helpers exposing (seconds)
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events exposing (on, onMouseDown)
import Json.Decode as Decode
import Player.Model exposing (Model, PlayState(..))
import Player.Update exposing (..)


decodeTargetAttribute : String -> Decode.Decoder a -> Decode.Decoder a
decodeTargetAttribute attr attrDecoder =
    Decode.at [ "target", attr ] attrDecoder


timeEvent : String -> String -> Decode.Decoder a -> (a -> msg) -> Html.Attribute msg
timeEvent evt attr decoder msg =
    on evt <|
        Decode.map msg <|
            decodeTargetAttribute attr decoder


view : Model -> Html Msg
view model =
    Html.audio
        [ HtmlAttr.id "audio-player"
        , HtmlAttr.src "static/audio/song.mp3"
        , HtmlAttr.type_ "audio/mp3"
        , timeEvent "timeupdate" "currentTime" Decode.float (seconds >> SyncPlayhead >> Immediately)
        , timeEvent "loadedmetadata" "duration" Decode.float (seconds >> SetDuration >> Immediately)
        , timeEvent "canplaythrough" "duration" (Decode.succeed Paused) (SetPlayState >> Immediately)
        , timeEvent "ended" "ended" (Decode.succeed Ended) (SetPlayState >> Immediately)
        , timeEvent "playing" "paused" (Decode.succeed Playing) (SetPlayState >> Immediately)
        , timeEvent "pause" "paused" (Decode.succeed Paused) (SetPlayState >> Immediately)
        ]
        []

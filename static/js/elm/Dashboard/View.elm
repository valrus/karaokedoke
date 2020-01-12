module Dashboard.View exposing (view)

import Dict
import File
import Html exposing (Html)
import Html.Events exposing (preventDefaultOn)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Json.Decode as D
import RemoteData exposing (WebData, RemoteData(..))
import Url.Builder

--

import Dashboard.State exposing (Msg(..), Model)
import Helpers exposing (errorToString)
import Song exposing (Processed, SongDict, SongId, Song, ProcessingState(..))


tableBorder : List (Attribute Msg)
tableBorder =
    [ Border.width 1
    , Border.color <| rgb255 200 200 200
    , Border.rounded 5
    ]


tableCellAttrs : List (Attribute Msg)
tableCellAttrs =
    [ padding 5
    ]


songTableCell : List (Attribute Msg) -> Element Msg -> Element Msg
songTableCell attrs content =
    el (List.append tableCellAttrs attrs) <| content


linkToSong : ( SongId, (Processed Song) ) -> Element Msg
linkToSong ( songId, song ) =
    link [] { url = Url.Builder.relative [ "edit", songId ] [], label = text song.name }


stateIcon : ProcessingState -> String
stateIcon state =
    case state of
        NotStarted ->
            "-"

        InProgress _ ->
            "..."

        Complete ->
            ">"

        Failed err ->
            "x"


viewSongDict : Model -> SongDict -> Element Msg
viewSongDict model songDict =
    case model.dragging of
        False ->
            table
                (List.append [ centerX, centerY, width shrink ] tableBorder)
                { data = Dict.toList songDict
                , columns =
                    [ { header = songTableCell [ Font.bold ] <| text "Song"
                        , width = fill |> maximum 300
                        , view = (linkToSong >> songTableCell [])
                        }
                    , { header = songTableCell [ Font.bold ] <| text "Artist"
                        , width = fill |> maximum 300
                        , view = (Tuple.second >> .artist >> text >> songTableCell [])
                        }
                    , { header = songTableCell [ centerX, Font.bold ] <| text "Play"
                        , width = fill |> maximum 50
                        , view = (Tuple.second >> .processingState >> stateIcon >> text >> el [ centerX ] >> songTableCell [])
                        }
                    ]
                }

        True ->
            el [ centerX, centerY, width shrink, height shrink, Font.size 300 ] <| text "⇪"


viewSongDictData : Model -> WebData SongDict -> Element Msg
viewSongDictData model songDictData =
    case songDictData of
        NotAsked ->
            text "Initialising."

        Loading ->
            text "Loading."

        Failure err ->
            text ("Error: " ++ errorToString err)

        Success songDict ->
            viewSongDict model songDict


-- drag and drop, see https://github.com/elm/file/blob/master/examples/DragAndDrop.elm

view : Model -> WebData SongDict -> Html Msg
view model songDictData =
    layout
    [ hijackOn "dragenter" (D.succeed DragEnter)
    , hijackOn "dragover" (D.succeed DragEnter)
    , hijackOn "dragleave" (D.succeed DragLeave)
    , hijackOn "drop" dropDecoder
    ]
    <| viewSongDictData model songDictData


dropDecoder : D.Decoder Msg
dropDecoder =
  D.at ["dataTransfer", "files"] (D.oneOrMore ProcessFiles File.decoder)


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    htmlAttribute <| preventDefaultOn event (D.map hijack decoder)


hijack : msg -> (msg, Bool)
hijack msg =
    (msg, True)

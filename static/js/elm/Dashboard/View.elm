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
import Song exposing (SongDict, SongId, Song)


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


songTableCell : Element Msg -> Element Msg
songTableCell content =
    el tableCellAttrs <| content


linkToSong : ( SongId, Song ) -> Element Msg
linkToSong ( songId, song ) =
    link [] { url = Url.Builder.relative [ "edit", songId ] [], label = text song.name }


booleanIcon : Bool -> Element Msg
booleanIcon canPlay =
    let
        icon =
            case canPlay of
                True -> ">"
                False -> "-"

    in
        text icon


viewSongDict : Model -> SongDict -> Element Msg
viewSongDict model songDict =
    case model.dragging of
        False ->
            table
                (List.append [ centerX, centerY, width shrink ] tableBorder)
                { data = Dict.toList songDict
                , columns =
                    [ { header = el (List.append [ Font.bold ] tableCellAttrs) (text "Song")
                        , width = fill |> maximum 300
                        , view = (linkToSong >> songTableCell)
                        }
                    , { header = el (List.append [ Font.bold ] tableCellAttrs) (text "Artist")
                        , width = fill |> maximum 300
                        , view = (Tuple.second >> .artist >> text >> songTableCell)
                        }
                    , { header = el (List.append [ Font.bold ] tableCellAttrs) (text "Play")
                        , width = fill |> maximum 50
                        , view = (Tuple.second >> .prepared >> booleanIcon >> songTableCell)
                        }
                    ]
                }

        True ->
            el [ centerX, centerY, width <| px 300, height <| px 300 ] <| text "Upload"


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

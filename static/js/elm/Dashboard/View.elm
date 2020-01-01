module Dashboard.View exposing (view)

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
import Song exposing (SongList, Song)


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


linkToSong : Song -> Element Msg
linkToSong song =
    link [] { url = Url.Builder.relative [ "edit", song.id ] [], label = text song.name }


booleanIcon : Bool -> Element Msg
booleanIcon canPlay =
    let
        icon =
            case canPlay of
                True -> ">"
                False -> "-"

    in
        text icon


viewSongList : Model -> SongList -> Element Msg
viewSongList model songList =
    case model.dragging of
        False ->
            table
                (List.append [ centerX, centerY, width shrink ] tableBorder)
                { data = songList
                , columns =
                    [ { header = el (List.append [ Font.bold ] tableCellAttrs) (text "Song")
                        , width = fill |> maximum 300
                        , view = (linkToSong >> songTableCell)
                        }
                    , { header = el (List.append [ Font.bold ] tableCellAttrs) (text "Artist")
                        , width = fill |> maximum 300
                        , view = (.artist >> text >> songTableCell)
                        }
                    , { header = el (List.append [ Font.bold ] tableCellAttrs) (text "Play")
                        , width = fill |> maximum 50
                        , view = (.prepared >> booleanIcon >> songTableCell)
                        }
                    ]
                }

        True ->
            el [ centerX, centerY, width <| px 300, height <| px 300 ] <| text "Upload"


viewSongListData : Model -> WebData SongList -> Element Msg
viewSongListData model songListData =
    case songListData of
        NotAsked ->
            text "Initialising."

        Loading ->
            text "Loading."

        Failure err ->
            text ("Error: " ++ errorToString err)

        Success songList ->
            viewSongList model songList


-- drag and drop, see https://github.com/elm/file/blob/master/examples/DragAndDrop.elm

view : Model -> WebData SongList -> Html Msg
view model songListData =
    layout
    [ hijackOn "dragenter" (D.succeed DragEnter)
    , hijackOn "dragover" (D.succeed DragEnter)
    , hijackOn "dragleave" (D.succeed DragLeave)
    , hijackOn "drop" dropDecoder
    ]
    <| viewSongListData model songListData


dropDecoder : D.Decoder Msg
dropDecoder =
  D.at ["dataTransfer","files"] (D.oneOrMore ProcessFiles File.decoder)


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    htmlAttribute <| preventDefaultOn event (D.map hijack decoder)


hijack : msg -> (msg, Bool)
hijack msg =
    (msg, True)

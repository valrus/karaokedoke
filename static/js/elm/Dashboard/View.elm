module Dashboard.View exposing (view)

import Html exposing (Html)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import RemoteData exposing (WebData, RemoteData(..))
import Url.Builder

--

import Dashboard.State exposing (Msg, Model)
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


viewSongList : SongList -> Element Msg
viewSongList songList =
    Element.table
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


viewSongListData : WebData SongList -> Element Msg
viewSongListData songListData =
    case songListData of
        NotAsked ->
            text "Initialising."

        Loading ->
            text "Loading."

        Failure err ->
            text ("Error: " ++ errorToString err)

        Success songList ->
            viewSongList songList


view : WebData SongList -> Html Msg
view songListData =
    Element.layout [] <| viewSongListData songListData

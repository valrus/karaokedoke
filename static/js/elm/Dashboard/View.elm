module Dashboard.View exposing (view)

import Html exposing (Html, text)
import RemoteData exposing (WebData, RemoteData(..))

--

import Dashboard.State exposing (Msg, Model)
import Helpers exposing (errorToString)
import Song exposing (SongList, Song)


viewSongItem : Song -> Html Msg
viewSongItem song =
    Html.li
        []
        [ text song.name
        ]


viewSongList : SongList -> Html Msg
viewSongList songList =
    Html.ul
        []
        (songList |> List.map viewSongItem)


view : WebData SongList -> Html Msg
view songListData =
    case songListData of
        NotAsked ->
            text "Initialising."

        Loading ->
            text "Loading."

        Failure err ->
            text ("Error: " ++ errorToString err)

        Success songList ->
            viewSongList songList

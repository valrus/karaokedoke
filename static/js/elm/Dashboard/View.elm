module Dashboard.View exposing (view)

--

import Dashboard.State exposing (Model, Msg(..))
import Dict
import Element exposing (..)
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import File
import Helpers exposing (errorToString)
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events exposing (preventDefaultOn)
import Json.Decode as D
import RemoteData exposing (RemoteData(..), WebData)
import Song exposing (Processed, ProcessingState(..), Song, SongDict, SongId)
import Url.Builder


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


editSongLink : ( SongId, Processed Song ) -> Element Msg
editSongLink ( songId, song ) =
    link [] { url = Url.Builder.absolute [ "edit", songId ] [], label = text song.name }


deleteSongLink : SongId -> Element Msg
deleteSongLink songId =
    el
        [ Events.onClick <| DeleteSongData songId
        , htmlAttribute <| style "cursor" "pointer"
        ]
        (text "X")


stateIcon : ProcessingState -> String
stateIcon state =
    case state of
        NotStarted ->
            "-"

        InProgress _ ->
            "⋯"

        Complete ->
            ">"

        Failed err ->
            "x"


playSongState : ( SongId, Processed Song ) -> Element Msg
playSongState ( songId, song ) =
    let
        content =
            case song.processingState of
                NotStarted ->
                    text "-"

                InProgress _ ->
                    text "⋯"

                Complete ->
                    link [] { url = Url.Builder.absolute [ "play", songId ] [], label = text ">" }

                Failed err ->
                    text "x"
    in
    el [ centerX ] content


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
                      , view = editSongLink >> songTableCell []
                      }
                    , { header = songTableCell [ Font.bold ] <| text "Artist"
                      , width = fill |> maximum 300
                      , view = Tuple.second >> .artist >> text >> songTableCell []
                      }
                    , { header = songTableCell [ centerX, Font.bold ] <| text "Play"
                      , width = fill |> maximum 50
                      , view = playSongState >> songTableCell []
                      }
                    , { header = songTableCell [ centerX, Font.bold ] <| text "Delete"
                      , width = fill |> maximum 50
                      , view = Tuple.first >> deleteSongLink >> el [ centerX ] >> songTableCell []
                      }
                    ]
                }

        True ->
            el [ centerX, centerY, width shrink, height shrink, Font.size 300 ] <| text "⇪"


viewSongDictData : Model -> WebData SongDict -> Element Msg
viewSongDictData model songDictData =
    case songDictData of
        NotAsked ->
            el [ centerX, centerY ] <| text "Initialising…"

        Loading ->
            el [ centerX, centerY ] <| text "Loading…"

        Failure err ->
            el [ centerX, centerY ] <| text ("Error: " ++ errorToString err)

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
    <|
        viewSongDictData model songDictData


dropDecoder : D.Decoder Msg
dropDecoder =
    D.at [ "dataTransfer", "files" ] (D.oneOrMore ProcessFiles File.decoder)


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    htmlAttribute <| preventDefaultOn event (D.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )

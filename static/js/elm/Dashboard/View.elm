module Dashboard.View exposing (view)

--

import Dashboard.State exposing (DashboardState(..), Model, Msg(..), YoutubeData, YoutubeField(..))
import Dict
import Element exposing (..)
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import File
import Helpers exposing (errorToString)
import Html exposing (Html)
import Html.Attributes exposing (href, style)
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
    [ padding 5 ]


songTableCell : List (Attribute Msg) -> Element Msg -> Element Msg
songTableCell attrs content =
    el (List.append tableCellAttrs attrs) <| content


editSongLink : ( SongId, Processed Song ) -> Html Msg
editSongLink ( songId, song ) =
    Html.a [ href <| Url.Builder.absolute [ "edit", songId ] [] ] <| [ Html.text song.name ]


songTableEllipsisCell : Html Msg -> Element Msg
songTableEllipsisCell content =
    Element.html <|
        Html.div
            [ style "text-overflow" "ellipsis"
            , style "white-space" "nowrap"
            , style "overflow" "hidden"
            , style "width" "100%"
            , style "max-width" "300px"
            , style "padding" "5px"
            , style "flex-basis" "auto"
            ]
            [ content ]


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
    table
        (List.append [ centerX, centerY, width shrink ] tableBorder)
        { data = Dict.toList songDict
        , columns =
            [ { header = songTableCell [ Font.bold ] <| text "Song"
              , width = fill
              , view = editSongLink >> songTableEllipsisCell
              }
            , { header = songTableCell [ Font.bold ] <| text "Artist"
              , width = fill
              , view = Tuple.second >> .artist >> Html.text >> songTableEllipsisCell
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


addSongLinks : Model -> SongDict -> Element Msg
addSongLinks model songDict =
    row
        [ width fill
        , padding 5
        ]
        [ Input.button [ alignLeft ] { onPress = Just FilesRequested, label = text "Upload MP3" }
        , Input.button [ alignRight ] { onPress = Just ShowYoutubeDialog, label = text "Load from YouTube" }
        ]



-- drag and drop, see https://github.com/elm/file/blob/master/examples/DragAndDrop.elm


draggable : List (Attribute Msg)
draggable =
    [ hijackOn "dragenter" (D.succeed DragEnter)
    , hijackOn "dragover" (D.succeed DragEnter)
    , hijackOn "dragleave" (D.succeed RestoreDefaultState)
    , hijackOn "drop" dropDecoder
    ]


viewSongDictData : Model -> Html Msg
viewSongDictData model =
    case model.songDict of
        NotAsked ->
            layout [] <| el [ centerX, centerY ] <| text "Initialising…"

        Loading ->
            layout [] <| el [ centerX, centerY ] <| text "Loading…"

        Failure err ->
            layout [] <| el [ centerX, centerY ] <| text ("Error: " ++ errorToString err)

        Success songDict ->
            layout draggable <|
                column
                    [ centerX
                    , centerY
                    , width shrink
                    , spacing 10
                    ]
                    [ viewSongDict model songDict
                    , addSongLinks model songDict
                    ]


viewYoutubeHeader : Element Msg
viewYoutubeHeader =
    row
        [ width fill ]
        [ Input.button [ alignLeft ] { onPress = Just RestoreDefaultState, label = text "Return to song list" } ]


viewYoutubeDialog : YoutubeData -> Element Msg
viewYoutubeDialog youtubeData =
    column
        (List.append tableBorder [ spacing 10, padding 10 ])
        [ Input.text []
            { onChange = UpdateYoutubeData YoutubeSong
            , text = youtubeData.song
            , placeholder = Just (Input.placeholder [] <| text "No Children")
            , label = Input.labelLeft [] <| text "Song Name"
            }
        , Input.text []
            { onChange = UpdateYoutubeData YoutubeArtist
            , text = youtubeData.artist
            , placeholder = Just (Input.placeholder [] <| text "The Mountain Goats")
            , label = Input.labelLeft [] <| text "Artist Name"
            }
        , Input.text []
            { onChange = UpdateYoutubeData YoutubeUrl
            , text = youtubeData.url
            , placeholder = Just (Input.placeholder [] <| text "https://www.youtube.com/watch?v=QS27S3mspjU")
            , label = Input.labelLeft [] <| text "YouTube URL"
            }
        , Input.button [ centerX ]
            { onPress = Just YoutubeRequested
            , label = text "Load YouTube audio"
            }
        ]


viewYoutubeState : YoutubeData -> Element Msg
viewYoutubeState youtubeData =
    column
        [ centerX, centerY, width shrink, height shrink, spacing 10 ]
    <|
        [ viewYoutubeHeader
        , viewYoutubeDialog youtubeData ]


view : Model -> Html Msg
view model =
    case model.state of
        Default ->
            viewSongDictData model

        Dragging ->
            layout [] <| el [ centerX, centerY, width shrink, height shrink, Font.size 300 ] <| text "⇪"

        ShowingYoutubeDialog youtubeData ->
            layout [] <| viewYoutubeState youtubeData


dropDecoder : D.Decoder Msg
dropDecoder =
    D.at [ "dataTransfer", "files" ] (D.oneOrMore ProcessFiles File.decoder)


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    htmlAttribute <| preventDefaultOn event (D.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )

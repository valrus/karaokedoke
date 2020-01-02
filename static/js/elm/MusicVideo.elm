module MusicVideo exposing (..)

--

import Browser exposing (UrlRequest, application)
import Browser.Navigation as Nav
import Dict
import Html exposing (Html)
import Http
import Svg exposing (Svg)
import Time exposing (Posix)
import Url exposing (Url)
import Url.Builder

--

import Dashboard.State as DashboardState
import Dashboard.View as DashboardView
import Editor.State as EditorState
import Editor.View as EditorView
import Helpers exposing (Milliseconds)
import Lyrics.Model exposing (Lyric, LyricBook, LyricLine)
import Lyrics.Style exposing (lyricBaseFontName, lyricBaseFontTTF, svgScratchId)
import Player.State as PlayerState
import Player.View as PlayerView
import Ports exposing (..)
import RemoteData exposing (..)
import Route exposing (Route(..))
import Song exposing (..)


type alias Flags
    = ()


type Page
    = NotFoundPage
    | DashboardPage DashboardState.Model
    | EditorPage EditorState.Model
    | PlayerPage PlayerState.Model


type Msg
    = DashboardPageMsg DashboardState.Msg
    | EditorPageMsg EditorState.Msg
    | PlayerPageMsg PlayerState.Msg
    | GotSongDict (WebData SongDict)
    | ClickLink UrlRequest
    | ChangeUrl Url


type alias Model =
    { route : Route
    , page : Page
    , navKey : Nav.Key
    , songDict : WebData SongDict
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    initCurrentPage
    ( { route = Route.parseUrl url
      , songDict = RemoteData.Loading
      , page = NotFoundPage
      , navKey = key
      }
    , Http.get
        { url = Url.Builder.relative ["songs"] []
        , expect = Http.expectJson (fromResult >> GotSongDict) songDictDecoder
        }
    )


-- Ports.jsLoadFonts [ { name = lyricBaseFontName, path = lyricBaseFontTTF } ]

view : Model -> Browser.Document Msg
view model =
    let
        html =
            case model.page of
                NotFoundPage ->
                    Html.div [] []

                DashboardPage dashboardModel ->
                    DashboardView.view dashboardModel model.songDict |> Html.map DashboardPageMsg

                EditorPage editorModel ->
                    EditorView.view editorModel |> Html.map EditorPageMsg

                PlayerPage playerModel ->
                    PlayerView.view playerModel |> Html.map PlayerPageMsg

    in
        { title = "Karaokedoke", body = [ html ] }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( DashboardPageMsg dashboardMsg, DashboardPage pageModel ) ->
            let
                (newPage, pageCmd) = DashboardState.update dashboardMsg pageModel
            in
                ( { model
                    | songDict = RemoteData.map (DashboardState.updateSongDict dashboardMsg) model.songDict
                    , page = DashboardPage newPage
                }
                , Cmd.map DashboardPageMsg pageCmd
                )

        ( EditorPageMsg editorMsg, EditorPage pageModel ) ->
            ( { model | page = EditorPage <| EditorState.update pageModel editorMsg }
            , Cmd.none
            )

        ( PlayerPageMsg playerMsg, PlayerPage pageModel ) ->
            let
                (newPage, pageCmd) = PlayerState.update pageModel playerMsg
            in
                ( { model | page = PlayerPage <| newPage }
                , Cmd.map PlayerPageMsg pageCmd
                )

        ( GotSongDict songDictResult, _ ) ->
            ( { model | songDict = songDictResult }
            , Cmd.none
            )

        ( ClickLink request, _ ) ->
            ( model, Cmd.none ) -- TODO

        ( ChangeUrl url, _ ) ->
            ( model, Cmd.none ) -- TODO

        ( _, _ ) ->
            ( model, Cmd.none )


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Dashboard ->
                    let
                        ( pageModel, pageCmds ) =
                            DashboardState.init
                    in
                        ( DashboardPage pageModel, Cmd.map DashboardPageMsg pageCmds)

                Route.Editor songId ->
                    let
                        songFromId = RemoteData.withDefault Dict.empty model.songDict |> Dict.get songId
                    in
                        case songFromId of
                            Just song ->
                                let
                                    ( pageModel, pageCmds ) = EditorState.init song
                                in
                                    ( EditorPage pageModel, Cmd.map EditorPageMsg pageCmds )

                            Nothing ->
                                ( NotFoundPage, Cmd.none )

                Route.Player songId ->
                    let
                        ( pageModel, pageCmds ) =
                            PlayerState.init -- need to init this with the song
                    in
                        ( PlayerPage pageModel, Cmd.map PlayerPageMsg pageCmds )
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        NotFoundPage ->
            Sub.none

        DashboardPage dashboardModel ->
            Sub.none

        EditorPage editorModel ->
            Sub.none

        PlayerPage playerModel ->
            Sub.map PlayerPageMsg <| PlayerState.subscriptions playerModel


main =
    application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickLink
        , onUrlChange = ChangeUrl
        }

module Karaokedoke exposing (..)

--

import Browser exposing (UrlRequest(..), application)
import Browser.Navigation as Nav
import Dashboard.State as DashboardState
import Dashboard.View as DashboardView
import Debug exposing (log)
import Dict
import Editor.State as EditorState
import Editor.View as EditorView
import Helpers exposing (Milliseconds)
import Html exposing (Html)
import Http
import Lyrics.Model exposing (Lyric, LyricBook, LyricLine)
import Lyrics.Style exposing (svgScratchId)
import Player.State as PlayerState
import Player.View as PlayerView
import Ports exposing (..)
import RemoteData exposing (..)
import Route exposing (Route(..))
import Song exposing (..)
import Svg exposing (Svg)
import Time exposing (Posix)
import Url exposing (Url)
import Url.Builder


type alias Flags =
    ()


type Page
    = NotFoundPage
    | DashboardPage DashboardState.Model
    | EditorPage EditorState.Model
    | PlayerPage PlayerState.Model


type Msg
    = DashboardPageMsg DashboardState.Msg
    | EditorPageMsg EditorState.Msg
    | PlayerPageMsg PlayerState.Msg
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
        ( { route = Route.parseUrl (log "initUrl" url)
          , page = NotFoundPage
          , navKey = key
          , songDict = RemoteData.Loading
          }
        , Cmd.none
        )


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


songPage : Maybe (Processed Song) -> (pageModel -> Page) -> (Song -> ( pageModel, Cmd a )) -> ( Page, Cmd a )
songPage foundSong pageConstructor pageInit =
    case foundSong of
        Just processedSong ->
            case processedSong.processingState of
                Complete ->
                    let
                        ( pageModel, pageCmd ) =
                            pageInit { name = processedSong.name, artist = processedSong.artist }
                    in
                    ( pageConstructor pageModel, pageCmd )

                _ ->
                    ( NotFoundPage, Cmd.none )

        Nothing ->
            ( NotFoundPage, Cmd.none )


updateWith : (pageModel -> Page) -> (pageMsg -> Msg) -> Model -> ( pageModel, Cmd pageMsg ) -> ( Model, Cmd Msg )
updateWith toPageModel toMsg model ( pageModel, pageCmd ) =
    ( { model | page = toPageModel pageModel }
    , Cmd.map toMsg pageCmd
    )


dashboardUpdate : Model -> ( DashboardState.Model, WebData SongDict, Cmd DashboardState.Msg ) -> ( Model, Cmd Msg )
dashboardUpdate model ( pageModel, songDict, pageCmd ) =
    ( { model | page = DashboardPage pageModel, songDict = songDict }
    , Cmd.map DashboardPageMsg pageCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( DashboardPageMsg dashboardMsg, DashboardPage pageModel ) ->
            dashboardUpdate model <| DashboardState.update pageModel dashboardMsg model.songDict

        ( EditorPageMsg editorMsg, EditorPage pageModel ) ->
            updateWith EditorPage EditorPageMsg model <| EditorState.update pageModel editorMsg

        ( PlayerPageMsg playerMsg, PlayerPage pageModel ) ->
            updateWith PlayerPage PlayerPageMsg model <| PlayerState.update pageModel playerMsg

        ( ClickLink (Internal url), _ ) ->
            ( model, Nav.pushUrl model.navKey (Url.toString url) )

        ( ClickLink (External url), _ ) ->
            ( model, Nav.load url )

        ( ChangeUrl url, _ ) ->
            initCurrentPage
            ( { model | route = Route.parseUrl url }
            , Ports.jsDestroyWaveform ()
            )

        ( _, _ ) ->
            ( model, Cmd.none )


initPageWithSongId : SongId -> (pageModel -> Page) -> (pageMsg -> Msg) -> (SongId -> ( pageModel, Cmd pageMsg )) -> ( Page, Cmd Msg )
initPageWithSongId songId toPageModel toPageMsg pageInit =
    let
        ( pageModel, pageCmds ) =
            pageInit songId
    in
    ( toPageModel pageModel, Cmd.map toPageMsg pageCmds )


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case log "initCurrentPage route" model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Dashboard ->
                    let
                        ( pageModel, pageCmds ) =
                            DashboardState.init
                    in
                    ( DashboardPage pageModel, Cmd.map DashboardPageMsg pageCmds )

                Route.Editor songId ->
                    initPageWithSongId songId EditorPage EditorPageMsg EditorState.init

                Route.Player songId ->
                    initPageWithSongId songId PlayerPage PlayerPageMsg PlayerState.init
    in
    ( { model | page = log "currentPage in initCurrentPage" currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        NotFoundPage ->
            Sub.none

        DashboardPage dashboardModel ->
            Sub.map DashboardPageMsg <| DashboardState.subscriptions dashboardModel

        EditorPage editorModel ->
            Sub.map EditorPageMsg <| EditorState.subscriptions editorModel

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

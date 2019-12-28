module MusicVideo exposing (..)

--

import Browser exposing (application)
import Html
import Ports
import Route
import Svg exposing (Svg)
import Time exposing (Posix)

--

import Dashboard.Model as DashboardModel
import Dashboard.Update as DashboardUpdate
import Dashboard.View as DashboardView
import Editor.Model as EditorModel
import Editor.Update as EditorUpdate
import Editor.View as EditorView
import Helpers exposing (Milliseconds)
import Lyrics.Model exposing (Lyric, LyricBook, LyricLine)
import Lyrics.Style exposing (lyricBaseFontName, lyricBaseFontTTF, svgScratchId)
import Player.Model as PlayerModel
import Player.Update as PlayerUpdate
import Player.View as PlayerView



type alias Flags
    = ()


type Page
    = NotFoundPage
    | DashboardPage DashboardModel.Model
    | EditorPage EditorModel.Model
    | PlayerPage PlayerModel.Model


type Msg
    = DashboardPageMsg DashboardUpdate.Msg
    | EditorPageMsg EditorUpdate.Msg
    | PlayerPageMsg PlayerUpdate.Msg
    | LinkClicked UrlRequest


type alias Model =
    { route : Route
    , page : Page
    , navKey : Nav.Key
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    initCurrentPage
    ( { route = Route.parseUrl
      , page = NotFoundPage
      , navKey = key
      }
    , Ports.jsLoadFonts [ { name = lyricBaseFontName, path = lyricBaseFontTTF } ]
    )


view : Model -> Html Msg
view model =
    case model.page of
        NotFoundPage ->
            Html.div []

        DashboardPage dashboardModel ->
            DashboardView.view dashboardModel

        EditorPage editorModel ->
            EditorView.view editorModel

        PlayerPage playerModel ->
            PlayerView.view playerModel


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Player ->
                    let
                        ( pageModel, pageCmds ) =
                            Player.init
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
            PlayerUpdate.subscriptions playerModel


main =
    application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickLink
        , onUrlChange = ChangeUrl
        }

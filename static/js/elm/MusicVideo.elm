
module MusicVideo exposing (..)

--

import Browser exposing (UrlRequest, application)
import Browser.Navigation as Nav
import Html exposing (Html)
import Http
import Ports
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
import Route exposing (Route(..))


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
    | ClickLink UrlRequest
    | ChangeUrl Url


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
    , Cmd.none
    )


-- Ports.jsLoadFonts [ { name = lyricBaseFontName, path = lyricBaseFontTTF } ]

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


update : Model -> Msg -> Model
update model msg =
    case msg of
        DashboardPageMsg dashboardMsg ->
            let
                (DashboardPage pageModel) = model.page
            in
                { model | page = DashboardPage <| DashboardState.update dashboardMsg pageModel }

        EditorPageMsg editorMsg ->
            let
                (EditorPage pageModel) = model.page
            in
                { model | page = EditorPage <| EditorState.update editorMsg pageModel }

        PlayerPageMsg playerMsg ->
            let
                (PlayerPage pageModel) = model.page
            in
                { model | page = PlayerPage <| PlayerState.update playerMsg pageModel }

        ClickLink request ->
            model -- TODO

        ChangeUrl url ->
            model -- TODO


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

                Route.Editor songName ->
                    let
                        ( pageModel, pageCmds ) =
                            EditorState.init
                    in
                        ( EditorPage pageModel, Cmd.map EditorPageMsg pageCmds )

                Route.Player songName ->
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
            PlayerState.subscriptions playerModel


main =
    application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickLink
        , onUrlChange = ChangeUrl
        }

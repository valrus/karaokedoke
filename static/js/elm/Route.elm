module Route exposing (Route(..), parseUrl)

import Debug exposing (log)
import Song exposing (SongId)
import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Dashboard
    | Editor SongId
    | Player SongId


songId : Parser (SongId -> a) a
songId =
    string


parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute (log "matchRoute url" url) of
        Just route ->
            log "matchRoute route" route

        Nothing ->
            log "matchRoute not found" NotFound


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Dashboard top
        , map Editor (s "edit" </> songId)
        , map Player (s "play" </> songId)
        ]

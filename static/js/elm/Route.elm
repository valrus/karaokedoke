module Route exposing (Route(..), parseUrl)

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
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Dashboard top
        , map Editor (s "edit" </> songId)
        , map Player (s "play" </> songId)
        ]

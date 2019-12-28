module Route exposing (Route(..), parseUrl)

import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Dashboard
    | Editor SongName
    | Player SongName


type SongName
    = SongName String


songName : Parser (SongName -> a) a
songName =
    custom "SONGNAME" (Just << SongName)

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
        , map Editor (s "edit" </> songName)
        , map Player (s "play" </> songName)
        ]

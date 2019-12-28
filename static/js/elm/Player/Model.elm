module Player.Model exposing (..)

--

import Lyrics.Model exposing (LyricBook, LyricLine)
import Scrubber.Model
import Player.Update exposing (Msg)


type alias Size =
    { height : Float
    , width : Float
    }


type alias Position =
    { x : Float
    , y : Float
    }


type alias Positioned t =
    { t | pos : Position }


type alias Sized t =
    { content : t
    , size : Size
    }


type alias Height =
    { min : Float
    , max : Float
    }


type alias WithDims t =
    { content : t
    , width : Float
    , y : Height
    }


type alias Located t =
    { content : t
    , size : Size
    , pos : Position
    }


type alias SizedLyricPage =
    Sized (List (WithDims LyricLine))


type alias SizedLyricBook =
    List SizedLyricPage


type PlayState
    = Loading
    | Paused
    | Playing
    | Ended
    | Error


type alias Model =
    { page : Maybe SizedLyricPage
    , playing : PlayState
    , lyrics : LyricBook
    , scrubber : Scrubber.Model.Model
    }

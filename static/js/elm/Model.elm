module Model exposing (..)

import Time exposing (Time)

--

import Lyrics.Model exposing (LyricLine)


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


type alias Model =
    { playhead : Time
    , page : Maybe (SizedLyricPage)
    , playing : Bool
    , lyrics : SizedLyricBook
    , duration : Time
    , dragging : Bool
    }

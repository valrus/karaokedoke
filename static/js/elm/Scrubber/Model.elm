module Scrubber.Model exposing (Model, init)

import Time exposing (Time)


type alias Model =
    { duration : Time
    , playhead : Time
    , cursorX : Maybe Float
    , dragging : Bool
    , hovering : Bool
    }


init : Model
init =
    { duration = 0.0
    , playhead = 0.0
    , cursorX = Nothing
    , dragging = False
    , hovering = False
    }
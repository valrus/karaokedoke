module Scrubber.Model exposing (Model, init)

import Helpers exposing (Milliseconds, Seconds)


type alias Model =
    { duration : Milliseconds
    , playhead : Seconds
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

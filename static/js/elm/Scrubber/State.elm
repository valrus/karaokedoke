module Scrubber.State exposing (..)

--

import Debug exposing (log)
import Helpers exposing (Milliseconds, Seconds, inSeconds)


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


setDuration : Milliseconds -> Model -> Model
setDuration duration model =
    { model
        | duration = duration
    }


setPlayhead : Milliseconds -> Model -> Model
setPlayhead playhead model =
    { model
        | playhead = (inSeconds playhead)
    }


moveCursor : Float -> Model -> Model
moveCursor proportion model =
    { model
        | cursorX = Just proportion
    }


dragPlayhead : Float -> Model -> Model
dragPlayhead proportion model =
    { model
        | playhead = model.duration * proportion
        , dragging = True
    }
        |> moveCursor proportion


stopDragging : Model -> Model
stopDragging model =
    { model
        | dragging = False
    }


mouseLeave : Model -> Model
mouseLeave model =
    { model
        | cursorX = Nothing
    }

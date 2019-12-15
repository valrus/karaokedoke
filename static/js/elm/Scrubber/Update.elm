module Scrubber.Update exposing (..)

import Time exposing (Time)
import Debug exposing (log)

--

import Scrubber.Model exposing (Model)


setDuration : Time -> Model -> Model
setDuration duration model =
    { model 
        | duration = duration
    }


setPlayhead : Time -> Model -> Model
setPlayhead playhead model =
    { model
        | playhead = playhead
    }


moveCursor : Float -> Model -> Model 
moveCursor proportion model =
    { model
        | cursorX = Just proportion
    }


dragPlayhead : Float -> Model -> Model
dragPlayhead proportion model =
    { model
        | playhead = (model.duration * proportion)
        , dragging = True
    } |> (moveCursor proportion)


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
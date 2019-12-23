module Scrubber.Update exposing (..)

--

import Debug exposing (log)
import Scrubber.Model exposing (Model)
import Helpers exposing (Milliseconds, Seconds, inSeconds)


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

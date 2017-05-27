module Lyrics exposing (..)

import Array exposing (Array)
import Time exposing (Time)


type alias Lyric =
    { text : String
    , time : Time
    }


type alias LyricLine =
    List Lyric


type alias LyricPage =
    List LyricLine


type alias LyricBook =
    List LyricPage


lyrics : LyricBook
lyrics =
    [ [ [ Lyric "Light " <| 1.650446 * Time.second
        , Lyric "up" <| 2.34241 * Time.second
        ]
      , [ Lyric "what " <| 4.483482 * Time.second
        , Lyric "I " <| 4.69866 * Time.second
        , Lyric "re" <| 4.900892 * Time.second
        , Lyric "veal " <| 5.133035 * Time.second
        , Lyric "to " <| 5.576339 * Time.second
        , Lyric "no " <| 5.932142 * Time.second
        , Lyric "one " <| 6.25625 * Time.second
        , Lyric "else" <| 6.675 * Time.second
        ]
      ]
    , [ [ Lyric "My " <| 8.534375 * Time.second
        , Lyric "trust" <| 9.192857 * Time.second
        ]
      , [ Lyric "I " <| 11.52366 * Time.second
        , Lyric "de" <| 11.77366 * Time.second
        , Lyric "ny " <| 12.067857 * Time.second
        , Lyric "e" <| 12.455803 * Time.second
        , Lyric "ven " <| 12.666964 * Time.second
        , Lyric "my" <| 13.102678 * Time.second
        , Lyric "self" <| 13.712946 * Time.second
        ]
      ]
    , [ [ Lyric "'cause " <| 14.799107 * Time.second
        , Lyric "I'm " <| 15.035267 * Time.second
        , Lyric "a " <| 15.266517 * Time.second
        , Lyric "man" <| 15.480803 * Time.second
        ]
      , [ Lyric "and " <| 18.595982 * Time.second
        , Lyric "men " <| 18.791964 * Time.second
        , Lyric "don't " <| 19.119642 * Time.second
        , Lyric "hurt" <| 19.489732 * Time.second
        ]
      , [ Lyric "like " <| 19.947767 * Time.second
        , Lyric "this " <| 20.412053 * Time.second
        , Lyric "I " <| 20.797321 * Time.second
        , Lyric "hear" <| 21.23125 * Time.second
        ]
      , [ Lyric "but " <| 21.681696 * Time.second
        , Lyric "you " <| 21.896428 * Time.second
        , Lyric "can" <| 22.313392 * Time.second
        ]
      ]
    , [ [ Lyric "dig " <| 25.694642 * Time.second
        , Lyric "through" <| 25.975892 * Time.second
        ]
      , [ Lyric "the " <| 26.382142 * Time.second
        , Lyric "crust" <| 26.604017 * Time.second
        ]
      , [ Lyric "to " <| 27.000892 * Time.second
        , Lyric "find" <| 27.250446 * Time.second
        ]
      , [ Lyric "the " <| 27.667856 * Time.second
        , Lyric "fear" <| 27.872321 * Time.second
        ]
      ]
    , [ [ Lyric "be" <| 28.269196 * Time.second
        , Lyric "tween " <| 28.466071 * Time.second
        ]
      , [ Lyric "my " <| 28.934374 * Time.second
        , Lyric "ears" <| 29.154463 * Time.second
        ]
      , [ Lyric "be" <| 29.558035 * Time.second
        , Lyric "hind " <| 29.75491 * Time.second
        , Lyric "my" <| 30.176785 * Time.second
        ]
      ]
    , [ [ Lyric "face" <| 30.798213 * Time.second
        ]
      , [ Lyric "the " <| 31.243303 * Time.second
        , Lyric "fi" <| 31.463392 * Time.second
        , Lyric "nal " <| 31.677678 * Time.second
        , Lyric "fron" <| 31.902678 * Time.second
        , Lyric "tier" <| 32.359374 * Time.second
        ]
      ]
    ]

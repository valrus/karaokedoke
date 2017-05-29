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


lyricBaseFontTTF : String
lyricBaseFontTTF =
    "static/fonts/leaguegothic/leaguegothic-regular-webfont.ttf"


lyricBaseFontName : String
lyricBaseFontName =
    "LeagueGothic"


lyrics : LyricBook
lyrics =
    [ [ [ Lyric "LIGHT " <| 1.650446 * Time.second
        , Lyric "UP" <| 2.34241 * Time.second
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
    , [ [ Lyric "MY " <| 8.534375 * Time.second
        , Lyric "TRUST" <| 9.192857 * Time.second
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
        , Lyric "MAN" <| 15.480803 * Time.second
        ]
      , [ Lyric "AND " <| 18.595982 * Time.second
        , Lyric "MEN " <| 18.791964 * Time.second
        , Lyric "DON'T " <| 19.119642 * Time.second
        , Lyric "HURT" <| 19.489732 * Time.second
        ]
      , [ Lyric "LIKE " <| 19.947767 * Time.second
        , Lyric "THIS " <| 20.412053 * Time.second
        , Lyric "I " <| 20.797321 * Time.second
        , Lyric "HEAR" <| 21.23125 * Time.second
        ]
      , [ Lyric "BUT " <| 21.681696 * Time.second
        , Lyric "YOU " <| 21.896428 * Time.second
        , Lyric "CAN" <| 22.313392 * Time.second
        ]
      ]
    , [ [ Lyric "DIG " <| 25.694642 * Time.second
        , Lyric "THROUGH" <| 25.975892 * Time.second
        ]
      , [ Lyric "THE " <| 26.382142 * Time.second
        , Lyric "CRUST" <| 26.604017 * Time.second
        ]
      , [ Lyric "TO " <| 27.000892 * Time.second
        , Lyric "FIND" <| 27.250446 * Time.second
        ]
      , [ Lyric "THE " <| 27.667856 * Time.second
        , Lyric "FEAR" <| 27.872321 * Time.second
        ]
      ]
    , [ [ Lyric "BE" <| 28.269196 * Time.second
        , Lyric "TWEEN " <| 28.466071 * Time.second
        ]
      , [ Lyric "MY " <| 28.934374 * Time.second
        , Lyric "EARS" <| 29.154463 * Time.second
        ]
      , [ Lyric "BE" <| 29.558035 * Time.second
        , Lyric "HIND " <| 29.75491 * Time.second
        , Lyric "MY" <| 30.176785 * Time.second
        ]
      ]
    , [ [ Lyric "FACE" <| 30.798213 * Time.second
        ]
      , [ Lyric "THE " <| 31.243303 * Time.second
        , Lyric "FI" <| 31.463392 * Time.second
        , Lyric "NAL " <| 31.677678 * Time.second
        , Lyric "FRON" <| 31.902678 * Time.second
        , Lyric "TIER" <| 32.359374 * Time.second
        ]
      ]
    ]

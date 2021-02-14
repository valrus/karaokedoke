module Lyrics.Style exposing (..)
import Url.Builder


type alias FontData =
    { name : String
    , path : String
    }


leagueGothicFontTTF : String
leagueGothicFontTTF =
    Url.Builder.absolute [ "fonts", "leaguegothic", "leaguegothic-regular-webfont.ttf" ] []


leagueGothicFontName : String
leagueGothicFontName =
    "LeagueGothic"



-- ID of an invisible SVG element for determining text widths


svgScratchId : String
svgScratchId =
    "scratch"


leagueGothicFontData : FontData
leagueGothicFontData =
    { name = leagueGothicFontName
    , path = leagueGothicFontTTF
    }

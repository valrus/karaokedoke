module Lyrics exposing (..)

import Array exposing (Array)
import Time exposing (Time)


type alias Lyric =
    { text : String
    , break : LyricBreak
    , time : Time
    }


type LyricBreak
    = Word
    | Syllable
    | Line
    | Page


-- type alias Lyric =
--     { text : String
--     , time : Time
--     }


-- type alias LyricLine =
--     List Lyric


-- type alias LyricPage =
--     List LyricLine


-- type alias LyricBook =
--     List LyricPage


lyrics : Array Lyric
lyrics =
    Array.fromList <|
        [ Lyric "Light" Word 1.650446
        , Lyric "up" Line 2.34241
        , Lyric "what" Word 4.483482
        , Lyric "I" Word 4.69866
        , Lyric "re" Syllable 4.900892
        , Lyric "veal" Word 5.133035
        , Lyric "to" Word 5.576339
        , Lyric "no" Word 5.932142
        , Lyric "one" Word 6.25625
        , Lyric "else" Page 6.675
        , Lyric "My" Word 8.534375
        , Lyric "trust" Line 9.192857
        , Lyric "I" Word 11.52366
        , Lyric "de" Syllable 11.77366
        , Lyric "ny" Word 12.067857
        , Lyric "e" Syllable 12.455803
        , Lyric "ven" Word 12.666964
        , Lyric "my" Word 13.102678
        , Lyric "self" Page 13.712946
        , Lyric "'cause" Word 14.799107
        , Lyric "I'm" Word 15.035267
        , Lyric "a" Word 15.266517
        , Lyric "man" Line 15.480803
        , Lyric "and" Word 18.595982
        , Lyric "men" Word 18.791964
        , Lyric "don't" Word 19.119642
        , Lyric "hurt" Word 19.489732
        , Lyric "like" Word 19.947767
        , Lyric "this" Word 20.412053
        , Lyric "I" Word 20.797321
        , Lyric "hear" Line 21.23125
        , Lyric "but" Word 21.681696
        , Lyric "you" Word 21.896428
        , Lyric "can" Page 22.313392
        , Lyric "dig" Word 25.694642
        , Lyric "through" Line 25.975892
        , Lyric "the" Word 26.382142
        , Lyric "crust" Line 26.604017
        , Lyric "to" Word 27.000892
        , Lyric "find" Line 27.250446
        , Lyric "the" Word 27.667856
        , Lyric "fear" Page 27.872321
        , Lyric "be" Syllable 28.269196
        , Lyric "tween" Line 28.466071
        , Lyric "my" Word 28.934374
        , Lyric "ears" Line 29.154463
        , Lyric "be" Syllable 29.558035
        , Lyric "hind" Word 29.75491
        , Lyric "my" Word 30.176785
        , Lyric "face" Line 30.798213
        , Lyric "the" Word 31.243303
        , Lyric "fi" Syllable 31.463392
        , Lyric "nal" Word 31.677678
        , Lyric "fron" Syllable 31.902678
        , Lyric "tier" Page 32.359374
        , Lyric "I'm" Word 47.307406
        , Lyric "al" Syllable 47.537774
        , Lyric "ways" Word 47.733688
        , Lyric "hon" Syllable 47.919585
        , Lyric "est" Word 48.118704
        , Lyric "ex" Syllable 50.746909
        , Lyric "cept" Word 50.97247
        , Lyric "for" Word 51.347871
        , Lyric "with" Word 51.559008
        , Lyric "my" Word 51.936012
        , Lyric "own" Word 52.295787
        , Lyric "stone" Word 52.771749
        , Lyric "heart" Word 53.150355
        , Lyric "I" Word 53.495306
        , Lyric "might" Word 53.696428
        , Lyric "ad" Syllable 53.904762
        , Lyric "mon" Syllable 54.033768
        , Lyric "ish" Word 54.309008
        , Lyric "but" Word 56.938015
        , Lyric "don't" Word 57.137935
        , Lyric "don't" Word 57.711653
        , Lyric "don't" Word 58.102678
        , Lyric "don't" Word 58.477678
        , Lyric "let's" Word 58.871508
        , Lyric "start" Word 59.259329
        , Lyric "there" Word 59.638736
        , Lyric "might" Word 59.836653
        , Lyric "be" Word 60.02856
        , Lyric "gi" Syllable 60.186012
        , Lyric "ant" Word 60.470066
        , Lyric "ex" Syllable 63.258528
        , Lyric "pec" Syllable 63.668784
        , Lyric "ta" Syllable 63.861893
        , Lyric "tions" Word 64.284169
        , Lyric "sti" Syllable 64.681204
        , Lyric "fling" Word 65.070226
        , Lyric "me" Word 65.440419
        , Lyric "but" Word 65.81622
        , Lyric "I'm" Word 66.007726
        , Lyric "de" Syllable 66.20364
        , Lyric "fi" Syllable 66.401957
        , Lyric "ant" Word 66.640739
        , Lyric "whe" Syllable 69.389537
        , Lyric "ther" Word 69.607085
        , Lyric "that's" Word 70.012133
        , Lyric "e" Syllable 70.40356
        , Lyric "nough" Word 70.804201
        , Lyric "we'll" Word 71.225675
        , Lyric "see" Word 71.624313
        , Lyric "be" Word 71.992903
        , Lyric "fore" Word 72.177198
        , Lyric "long" Word 72.558207
        , Lyric "my" Word 73.331044
        , Lyric "cri" Syllable 74.116701
        , Lyric "sis" Word 74.915579
        , Lyric "find" Syllable 75.661973
        , Lyric "ing" Word 76.419986
        , Lyric "mind" Word 77.240098
        , Lyric "will" Word 77.938415
        , Lyric "put" Word 78.675996
        , Lyric "my" Word 79.534169
        , Lyric "feel" Syllable 80.27255
        , Lyric "ings" Word 81.018944
        , Lyric "on" Word 81.827438
        , Lyric "the" Word 82.540579
        , Lyric "line" Word 83.298191
        , Lyric "I" Word 84.119906
        , Lyric "have" Word 84.900355
        , Lyric "no" Word 85.637133
        , Lyric "sure" Word 86.42239
        , Lyric "way" Word 87.188415
        , Lyric "to" Word 87.925996
        , Lyric "di" Syllable 88.739698
        , Lyric "vine" Word 89.493704
        , Lyric "which" Word 90.26013
        , Lyric "thoughts" Word 91.005723
        , Lyric "in" Syllable 91.795787
        , Lyric "vade" Word 92.57904
        , Lyric "and" Word 93.349874
        , Lyric "which" Word 94.099073
        , Lyric "are" Word 94.896348
        , Lyric "mine" Word 95.681605
        , Lyric "or" Word 96.394345
        , Lyric "if" Word 97.2413
        , Lyric "it" Word 97.444025
        , Lyric "is" Word 97.763335
        , Lyric "e" Syllable 97.930403
        , Lyric "ven" Word 98.325034
        , Lyric "well" Word 98.54098
        , Lyric "de" Syllable 98.874313
        , Lyric "fined" Word 99.08465
        , Lyric "lend" Word 99.443624
        , Lyric "me" Word 99.717262
        , Lyric "an" Word 100.006525
        , Lyric "ear" Word 100.21606
        , Lyric "I'll" Word 100.590659
        , Lyric "grow" Word 100.796188
        , Lyric "a" Word 101.189217
        , Lyric "spine" Word 101.434009
        , Lyric "In" Word 101.826637
        , Lyric "this" Word 102.029361
        , Lyric "ca" Syllable 102.318223
        , Lyric "thar" Syllable 102.567422
        , Lyric "tic" Word 102.908768
        , Lyric "pan" Syllable 103.106685
        , Lyric "to" Syllable 103.441621
        , Lyric "mime" Word 103.677598
        , Lyric "I'm" Word 104.075835
        , Lyric "the" Word 107.018945
        , Lyric "an" Syllable 107.182006
        , Lyric "droid" Word 107.471669
        , Lyric "who" Word 107.740098
        , Lyric "learns" Word 107.990499
        , Lyric "how" Word 108.264938
        , Lyric "to" Word 108.523352
        , Lyric "hold" Word 108.751717
        , Lyric "some" Syllable 109.103079
        , Lyric "one's" Word 109.311813
        , Lyric "hand" Word 109.560611
        , Lyric "be" Syllable 109.974473
        , Lyric "hind" Word 110.165179
        , Lyric "ob" Syllable 113.091861
        , Lyric "si" Syllable 113.380723
        , Lyric "di" Syllable 113.631124
        , Lyric "an" Word 113.887534
        , Lyric "walls" Word 114.102278
        , Lyric "that" Word 114.438015
        , Lyric "just" Word 114.575836
        , Lyric "crumb" Syllable 114.827438
        , Lyric "le" Word 115.158768
        , Lyric "to" Word 115.386733
        , Lyric "sand" Word 115.664778
        , Lyric "and" Word 116.040179
        , Lyric "you" Word 116.260932
        , Lyric "make" Word 119.450836
        , Lyric "me" Word 119.805002
        , Lyric "a" Word 120.028961
        , Lyric "space" Word 120.3034
        , Lyric "I" Word 120.50372
        , Lyric "can" Word 120.784169
        , Lyric "let" Word 121.020948
        , Lyric "down" Word 121.286172
        , Lyric "my" Word 121.548191
        , Lyric "guard" Word 121.817823
        , Lyric "and" Word 122.198832
        , Lyric "we" Word 122.396348
        , Lyric "dis" Syllable 125.421188
        , Lyric "co" Syllable 125.662775
        , Lyric "ver" Word 125.933207
        , Lyric "that" Word 126.147951
        , Lyric "touch" Syllable 126.415179
        , Lyric "ing" Word 126.667582
        , Lyric "bare" Word 126.922791
        , Lyric "wi" Syllable 127.204041
        , Lyric "res" Word 127.406765
        , Lyric "is" Word 127.58505
        , Lyric "hard" Word 127.755723
        , Lyric "but" Word 128.173993
        , Lyric "we" Word 128.370307
        , Lyric "can" Word 128.527759
        , Lyric "do" Word 128.758528
        , Lyric "it" Word 128.957246
        , Lyric "I" Word 155.513336
        , Lyric "need" Word 155.720868
        , Lyric "to" Word 155.888736
        , Lyric "ar" Syllable 156.07223
        , Lyric "gue" Word 156.335451
        , Lyric "I" Word 158.954842
        , Lyric "need" Word 159.119506
        , Lyric "to" Word 159.485291
        , Lyric "roll" Word 159.714858
        , Lyric "down" Word 160.133127
        , Lyric "in" Word 160.508127
        , Lyric "the" Word 160.895948
        , Lyric "much" Word 161.256525
        , Lyric "Don't" Word 161.630323
        , Lyric "want" Word 161.828239
        , Lyric "to" Word 161.994906
        , Lyric "harm" Word 162.173592
        , Lyric "you" Word 162.408768
        , Lyric "it's" Word 164.095066
        , Lyric "just" Word 164.456845
        , Lyric "my" Word 164.81622
        , Lyric "in" Syllable 165.286973
        , Lyric "stinct" Word 165.865499
        , Lyric "when" Word 166.340259
        , Lyric "I" Word 166.667983
        , Lyric "get" Word 167.05981
        , Lyric "stuck" Word 167.363897
        , Lyric "in" Syllable 167.791381
        , Lyric "side" Word 167.993304
        , Lyric "my" Word 168.173191
        , Lyric "own" Word 168.414377
        , Lyric "head" Word 168.910772
        , Lyric "Like" Word 171.222871
        , Lyric "ev" Syllable 171.419586
        , Lyric "ery" Word 171.64114
        , Lyric "man" Word 172.012134
        , Lyric "I've" Word 172.417983
        , Lyric "ev" Syllable 172.821829
        , Lyric "er" Word 173.180403
        , Lyric "known" Word 173.53497
        , Lyric "I'm" Word 173.891941
        , Lyric "fu" Syllable 174.135131
        , Lyric "ckin'" Word 174.305002
        , Lyric "da" Syllable 174.487294
        , Lyric "maged" Word 174.737695
        , Lyric "By" Word 177.44122
        , Lyric "learn" Syllable 177.597871
        , Lyric "ing" Word 177.819425
        , Lyric "I" Word 178.139137
        , Lyric "should" Word 178.558207
        , Lyric "stay" Word 178.930804
        , Lyric "a" Syllable 179.243304
        , Lyric "lone" Word 179.687214
        , Lyric "with" Word 180.089858
        , Lyric "my" Word 180.264938
        , Lyric "thoughts" Word 180.651957
        , Lyric "you" Word 181.385531
        , Lyric "pry" Word 182.184009
        , Lyric "out" Word 183.00973
        , Lyric "one" Word 183.695627
        , Lyric "by" Word 184.493704
        , Lyric "one" Word 185.208448
        , Lyric "pre" Syllable 186.027759
        , Lyric "cise" Syllable 186.653961
        , Lyric "ly" Word 187.617102
        , Lyric "what" Word 188.313416
        , Lyric "I" Word 189.122711
        , Lyric "need" Syllable 189.900355
        , Lyric "ed" Word 190.602278
        , Lyric "done" Word 191.395948
        , Lyric "I" Word 192.234089
        , Lyric "can't" Word 192.98489
        , Lyric "quite" Word 193.768544
        , Lyric "say" Word 194.521749
        , Lyric "that" Word 195.268945
        , Lyric "this" Word 196.020948
        , Lyric "is" Word 196.785772
        , Lyric "fun" Word 197.567823
        , Lyric "but" Word 198.341461
        , Lyric "I" Word 199.522951
        , Lyric "don't" Word 199.677198
        , Lyric "have" Word 199.845868
        , Lyric "my" Word 200.044185
        , Lyric "wis" Syllable 200.254121
        , Lyric "dom" Word 200.421589
        , Lyric "teeth" Word 200.591861
        , Lyric "ei" Syllable 200.992903
        , Lyric "ther" Word 201.25332
        , Lyric "So" Word 202.282967
        , Lyric "take" Word 202.610691
        , Lyric "me" Word 202.836252
        , Lyric "off" Word 203.025756
        , Lyric "the" Word 203.211653
        , Lyric "God" Syllable 203.382326
        , Lyric "damn" Word 203.732887
        , Lyric "e" Syllable 204.102679
        , Lyric "ther" Word 204.40356
        ]

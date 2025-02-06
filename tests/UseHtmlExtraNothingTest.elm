module UseHtmlExtraNothingTest exposing (all)

import Review.Project as Project exposing (Project)
import Review.Test
import Review.Test.Dependencies as Dependencies
import Test exposing (Test, describe, only, skip, test)
import UseHtmlExtraNothing exposing (rule)


project : Project
project =
    Project.new
        |> Project.addDependency Dependencies.elmHtml


run : String -> Review.Test.ReviewResult
run =
    Review.Test.runWithProjectData project rule


all : Test
all =
    describe "UseHtmlExtraNothing"
        [ describe "should not throw report an error when calling"
            [ test "calling Html.Extra.nothing" <|
                \() ->
                    """module A exposing (..)


import Html.Extra

blank = Html.Extra.nothing
"""
                        |> run
                        |> Review.Test.expectNoErrors
            , test " Html.Styled.text \"\"" <|
                \() ->
                    """module A exposing (..)


import Html.Styled as Html

blank = Html.text ""
                    """
                        |> run
                        |> Review.Test.expectNoErrors
            , test " aliased Html.Extra.nothing" <|
                \() ->
                    """module A exposing (..)


import Html.Extra as Html

blank = Html.nothing
"""
                        |> run
                        |> Review.Test.expectNoErrors
            , test "exposed Html.Extra.nothing" <|
                \() ->
                    """module A exposing (..)


import Html.Extra exposing (nothing)

blank = nothing
"""
                        |> run
                        |> Review.Test.expectNoErrors
            , test "everything-exposed Html.Extra.nothing" <|
                \() ->
                    """module A exposing (..)


import Html.Extra exposing (..)

blank = nothing
"""
                        |> run
                        |> Review.Test.expectNoErrors
            ]
        , describe "Should fix `Html.text \"\"`"
            [ describe "when importing Html by plain `import Html`"
                [ test "and Html.Extra is not imported" <|
                    \() ->
                        """module A exposing (..)


import Html

a = Html.text ""
"""
                            |> run
                            |> Review.Test.expectErrors
                                [ Review.Test.error
                                    { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                    , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                    , under = "Html.text \"\""
                                    }
                                    |> Review.Test.whenFixed """module A exposing (..)


import Html.Extra
import Html

a = Html.Extra.nothing
"""
                                ]
                , describe "when `Html.Extra` is imported aliased and exposes"
                    [ test "`nothing`" <|
                        \() ->
                            """module A exposing (..)


import Html
import Html.Extra as Html exposing (nothing)

a = Html.text ""
"""
                                |> run
                                |> Review.Test.expectErrors
                                    [ Review.Test.error
                                        { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                        , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                        , under = "Html.text \"\""
                                        }
                                        |> Review.Test.whenFixed """module A exposing (..)


import Html
import Html.Extra as Html exposing (nothing)

a = nothing
"""
                                    ]
                    , test "exposes other things but not `nothing`" <|
                        \() ->
                            """module A exposing (..)


import Html
import Html.Extra as Html exposing (viewIf)

a = Html.text ""
"""
                                |> run
                                |> Review.Test.expectErrors
                                    [ Review.Test.error
                                        { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                        , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                        , under = "Html.text \"\""
                                        }
                                        |> Review.Test.whenFixed """module A exposing (..)


import Html
import Html.Extra as Html exposing (viewIf)

a = Html.nothing
"""
                                    ]
                    , test "∅" <|
                        \() ->
                            """module A exposing (..)


import Html
import Html.Extra as Html

a = Html.text ""
"""
                                |> run
                                |> Review.Test.expectErrors
                                    [ Review.Test.error
                                        { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                        , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                        , under = "Html.text \"\""
                                        }
                                        |> Review.Test.whenFixed """module A exposing (..)


import Html
import Html.Extra as Html

a = Html.nothing
"""
                                    ]
                    ]
                ]
            , describe "when `Html.Extra` is imported un-aliased and exposes"
                [ test "`nothing`" <|
                    \() ->
                        """module A exposing (..)


import Html
import Html.Extra exposing (nothing)

a = Html.text ""
"""
                            |> run
                            |> Review.Test.expectErrors
                                [ Review.Test.error
                                    { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                    , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                    , under = "Html.text \"\""
                                    }
                                    |> Review.Test.whenFixed """module A exposing (..)


import Html
import Html.Extra exposing (nothing)

a = nothing
"""
                                ]
                , test "exposes other things but not `nothing`" <|
                    \() ->
                        """module A exposing (..)


import Html
import Html.Extra exposing (viewIf)

a = Html.text ""
"""
                            |> run
                            |> Review.Test.expectErrors
                                [ Review.Test.error
                                    { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                    , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                    , under = "Html.text \"\""
                                    }
                                    |> Review.Test.whenFixed """module A exposing (..)


import Html
import Html.Extra exposing (viewIf)

a = Html.Extra.nothing
"""
                                ]
                , test "∅" <|
                    \() ->
                        """module A exposing (..)


import Html
import Html.Extra

a = Html.text ""
"""
                            |> run
                            |> Review.Test.expectErrors
                                [ Review.Test.error
                                    { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                    , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                    , under = "Html.text \"\""
                                    }
                                    |> Review.Test.whenFixed """module A exposing (..)


import Html
import Html.Extra

a = Html.Extra.nothing
"""
                                ]
                ]
            ]
        , describe "when importing Html aliased"
            [ test "and Html.Extra is not imported" <|
                \() ->
                    """module A exposing (..)


import Html as H

a = H.text ""
"""
                        |> run
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                , under = "H.text \"\""
                                }
                                |> Review.Test.whenFixed """module A exposing (..)


import Html.Extra
import Html as H

a = Html.Extra.nothing
"""
                            ]
            , describe "when `Html.Extra` is imported aliased and exposes"
                [ test "`nothing`" <|
                    \() ->
                        """module A exposing (..)


import Html as H
import Html.Extra as H exposing (nothing)

a = H.text ""
"""
                            |> run
                            |> Review.Test.expectErrors
                                [ Review.Test.error
                                    { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                    , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                    , under = "H.text \"\""
                                    }
                                    |> Review.Test.whenFixed """module A exposing (..)


import Html as H
import Html.Extra as H exposing (nothing)

a = nothing
"""
                                ]
                , test "exposes other things but not `nothing`" <|
                    \() ->
                        """module A exposing (..)


import Html as H
import Html.Extra as H exposing (viewIf)

a = H.text ""
"""
                            |> run
                            |> Review.Test.expectErrors
                                [ Review.Test.error
                                    { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                    , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                    , under = "H.text \"\""
                                    }
                                    |> Review.Test.whenFixed """module A exposing (..)


import Html as H
import Html.Extra as H exposing (viewIf)

a = H.nothing
"""
                                ]
                , test "∅" <|
                    \() ->
                        """module A exposing (..)


import Html as H
import Html.Extra as H

a = H.text ""
"""
                            |> run
                            |> Review.Test.expectErrors
                                [ Review.Test.error
                                    { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                    , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                    , under = "H.text \"\""
                                    }
                                    |> Review.Test.whenFixed """module A exposing (..)


import Html as H
import Html.Extra as H

a = H.nothing
"""
                                ]
                ]
            ]
        , describe "when `Html.Extra` is imported un-aliased and exposes"
            [ test "`nothing`" <|
                \() ->
                    """module A exposing (..)


import Html as H
import Html.Extra exposing (nothing)

a = H.text ""
"""
                        |> run
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                , under = "H.text \"\""
                                }
                                |> Review.Test.whenFixed """module A exposing (..)


import Html as H
import Html.Extra exposing (nothing)

a = nothing
"""
                            ]
            , test "exposes other things but not `nothing`" <|
                \() ->
                    """module A exposing (..)


import Html as H
import Html.Extra exposing (viewIf)

a = H.text ""
"""
                        |> run
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                , under = "H.text \"\""
                                }
                                |> Review.Test.whenFixed """module A exposing (..)


import Html as H
import Html.Extra exposing (viewIf)

a = Html.Extra.nothing
"""
                            ]
            , test "∅" <|
                \() ->
                    """module A exposing (..)


import Html as H
import Html.Extra

a = H.text ""
"""
                        |> run
                        |> Review.Test.expectErrors
                            [ Review.Test.error
                                { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                , under = "H.text \"\""
                                }
                                |> Review.Test.whenFixed """module A exposing (..)


import Html as H
import Html.Extra

a = Html.Extra.nothing
"""
                            ]
            ]
        ]

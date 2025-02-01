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
        [ test "should not report an error when calling Html.Extra.nothing" <|
            \() ->
                """module A exposing (..)


import Html.Extra

blank = Html.Extra.nothing
"""
                    |> run
                    |> Review.Test.expectNoErrors
        , test "should not report an error when calling Html.Styled.text \"\"" <|
            \() ->
                """module A exposing (..)


import Html.Styled as Html

blank = Html.text ""
                    """
                    |> run
                    |> Review.Test.expectNoErrors
        , test "should not report an error when calling aliased Html.Extra.nothing" <|
            \() ->
                """module A exposing (..)


import Html.Extra as Html

blank = Html.nothing
"""
                    |> run
                    |> Review.Test.expectNoErrors
        , test "should not report an error when calling exposed Html.Extra.nothing" <|
            \() ->
                """module A exposing (..)


import Html.Extra exposing (nothing)

blank = nothing
"""
                    |> run
                    |> Review.Test.expectNoErrors
        , test "should not report an error when calling everything-exposed Html.Extra.nothing" <|
            \() ->
                """module A exposing (..)


import Html.Extra exposing (..)

blank = nothing
"""
                    |> run
                    |> Review.Test.expectNoErrors
        , test "should report an error when calling `Html.text \"\"`" <|
            \() ->
                """module A exposing (..)


import Html

a = Html.text ""
"""
                    |> run
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                            , details = [ "We prefer Html.Extra.nothing" ]
                            , under = "Html.text \"\""
                            }
                        ]
        , test "should report an error when calling aliased `Html.text \"\"`" <|
            \() ->
                """module A exposing (..)


import Html as H


a = H.text ""
                """
                    |> run
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                            , details = [ "We prefer Html.Extra.nothing" ]
                            , under = "H.text \"\""
                            }
                        ]
        , test "should report an error when calling exposed `Html.text \"\"`" <|
            \() ->
                """module A exposing (..)


import Html as H exposing (text)


a = text ""
                """
                    |> run
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                            , details = [ "We prefer Html.Extra.nothing" ]
                            , under = "text \"\""
                            }
                        ]
        , test "should report an error when calling entirely exposed `Html.text \"\"`" <|
            \() ->
                """module A exposing (..)


import Html as H exposing (..)


a = text ""
                """
                    |> run
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                            , details = [ "We prefer Html.Extra.nothing" ]
                            , under = "text \"\""
                            }
                        ]
        ]

module UseHtmlExtraNothing exposing (rule)

{-|

@docs rule

-}

import Dict exposing (Dict)
import Elm.Syntax.Exposing
import Elm.Syntax.Expression as Expression exposing (Expression(..))
import Elm.Syntax.Import as Import exposing (Import)
import Elm.Syntax.Module exposing (Module(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Review.Fix as Fix exposing (Fix)
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)


{-| Reports... REPLACEME

    config =
        [ UseHtmlExtraNothing.rule
        ]


## Fail

    a =
        "REPLACEME example to replace"


## Success

    a =
        "REPLACEME example to replace"


## When (not) to enable this rule

This rule is useful when REPLACEME.
This rule is not useful when REPLACEME.


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template perkee/elm-review-prefer-html-extra/example --rules UseHtmlExtraNothing
```

-}
rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "UseHtmlExtraNothing" initialContext
        |> Rule.withImportVisitor importVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { lookupTable : ModuleNameLookupTable
    , importContext : Dict (List String) ImportContext
    , firstImport : Maybe Range
    }


type alias ImportContext =
    { moduleName : ModuleName
    , moduleAlias : Maybe ModuleName
    , exposedFunctions : Exposed
    }


type Exposed
    = AllExposed
    | SomeExposed (List String)


toImportContext : Import -> ImportContext
toImportContext import_ =
    { moduleName = import_.moduleName |> Node.value
    , moduleAlias = import_.moduleAlias |> Maybe.map Node.value
    , exposedFunctions =
        import_.exposingList
            |> Maybe.map Node.value
            |> Maybe.map
                (\exposingList ->
                    case exposingList of
                        Elm.Syntax.Exposing.All _ ->
                            AllExposed

                        Elm.Syntax.Exposing.Explicit nodes ->
                            List.filterMap
                                (\exposition ->
                                    case Node.value exposition of
                                        Elm.Syntax.Exposing.FunctionExpose s ->
                                            Just s

                                        _ ->
                                            -- we do not care about exposed types, aliases, or infixes.
                                            Nothing
                                )
                                nodes
                                |> SomeExposed
                )
            |> Maybe.withDefault (SomeExposed [])
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\lookupTable () ->
            { lookupTable = lookupTable
            , importContext = Dict.empty
            , firstImport = Nothing
            }
        )
        |> Rule.withModuleNameLookupTable


importVisitor : Node Import -> Context -> ( List (Rule.Error {}), Context )
importVisitor node context =
    let
        value =
            Node.value node

        moduleName =
            Node.value value.moduleName
    in
    if moduleName == [ "Html" ] || moduleName == [ "Html", "Extra" ] then
        ( []
        , { context
            | importContext =
                Dict.insert
                    moduleName
                    (toImportContext value)
                    context.importContext
            , firstImport =
                case ( context.firstImport, moduleName ) of
                    ( _, [ "Html" ] ) ->
                        Just (Node.range node)

                    ( Nothing, _ ) ->
                        Just (Node.range node)

                    ( Just _, _ ) ->
                        context.firstImport
          }
        )

    else
        ( [], context )


expressionVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor node context =
    case Node.value node of
        Application [ firstNode, secondNode ] ->
            case ( Node.value firstNode, Node.value secondNode ) of
                ( FunctionOrValue _ "text", Literal "" ) ->
                    if ModuleNameLookupTable.moduleNameFor context.lookupTable firstNode == Just [ "Html" ] then
                        ( [ Rule.errorWithFix
                                { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                }
                                (Node.range node)
                                (case
                                    Dict.get
                                        [ "Html", "Extra" ]
                                        context.importContext
                                 of
                                    Just { exposedFunctions, moduleAlias, moduleName } ->
                                        [ Fix.replaceRangeBy (Node.range node)
                                            (case exposedFunctions of
                                                AllExposed ->
                                                    "nothing"

                                                SomeExposed exposedFnNames ->
                                                    if List.member "nothing" exposedFnNames then
                                                        "nothing"

                                                    else
                                                        Maybe.withDefault moduleName
                                                            moduleAlias
                                                            ++ [ "nothing" ]
                                                            |> String.join "."
                                            )
                                        ]

                                    Nothing ->
                                        case context.firstImport of
                                            Just { start } ->
                                                [ Fix.replaceRangeBy (Node.range node) "Html.Extra.nothing"
                                                , Fix.insertAt start "import Html.Extra\n"
                                                ]

                                            Nothing ->
                                                []
                                )
                          ]
                        , context
                        )

                    else
                        ( [], context )

                _ ->
                    ( [], context )

        _ ->
            ( [], context )

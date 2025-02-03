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
        |> Rule.fromModuleRuleSchema


type alias Context =
    { lookupTable : ModuleNameLookupTable
    , importContext : Dict (List String) ImportContext
    , firstImport : Maybe Range
    }


type ImportReference
    = QualifiedReference
    | UnqualifiedReference (List String)


type alias ImportContext =
    { moduleName : ModuleName
    , moduleAlias : Maybe ModuleName
    , exposedFunctions : Exposed
    }


type Exposed
    = AllExposed
    | SomeExposed (List String)


toImportContext : Import -> ( List String, ImportContext )
toImportContext import_ =
    ( import_.moduleName |> Node.value
    , { moduleName = import_.moduleName |> Node.value
      , moduleAlias = import_.moduleAlias |> Maybe.map Node.value
      , exposedFunctions =
            import_.exposingList
                |> Maybe.map Node.value
                |> Maybe.map
                    (\exposingList ->
                        case exposingList of
                            Elm.Syntax.Exposing.All nodes ->
                                AllExposed

                            Elm.Syntax.Exposing.Explicit nodes ->
                                List.filterMap
                                    (\exposition ->
                                        case Node.value exposition of
                                            Elm.Syntax.Exposing.FunctionExpose s ->
                                                Just s

                                            _ ->
                                                Nothing
                                    )
                                    nodes
                                    |> SomeExposed
                     -- (Node.value nodes)
                    )
                |> Maybe.withDefault (SomeExposed [])
      }
    )


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
        ( key, value ) =
            Node.value node
                |> toImportContext
    in
    ( []
    , { context
        | importContext =
            context.importContext |> Dict.insert key value
        , firstImport = context.firstImport |> Maybe.withDefault (Node.range node) |> Just
      }
    )


expressionVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor node context =
    case Node.value node of
        Application [ firstNode, secondNode ] ->
            let
                _ =
                    Debug.log "context" context

                _ =
                    Debug.log "nodes" { firstNode = Node.value firstNode, secondNode = Node.value secondNode }
            in
            case ( Node.value firstNode, Node.value secondNode ) of
                ( FunctionOrValue _ "text", Literal "" ) ->
                    if ModuleNameLookupTable.moduleNameFor context.lookupTable firstNode == Just [ "Html" ] then
                        ( [ Rule.error
                                { message = "Replace `Html.text \"\" with Html.Extra.nothing"
                                , details = [ "We prefer Html.Extra.nothing when we must create an empty node." ]
                                }
                                (Node.range node)
                          ]
                        , context
                        )

                    else
                        let
                            _ =
                                Debug.log "uneq" <| ModuleNameLookupTable.moduleNameFor context.lookupTable firstNode
                        in
                        ( [], context )

                _ ->
                    ( [], context )

        _ ->
            ( [], context )

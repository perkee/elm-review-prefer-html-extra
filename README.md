# elm-review-prefer-html-extra

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to replace `Html.text ""` with
`Html.Extra.nothing`. Make sure you have installed `elm-community/html-extra` for this to work.

## Provided rules

- [`UseHtmlExtraNothing`](https://package.elm-lang.org/packages/perkee/elm-review-prefer-html-extra/1.0.0/UseHtmlExtraNothing) -
   Replaces `Html.text ""` with `Html.Extra.nothing`.

## Configuration

```elm
module ReviewConfig exposing (config)

import UseHtmlExtraNothing
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ UseHtmlExtraNothing.rule
    ]
```

## Try it out

You can try the example configuration above out by running the following command:

```bash
elm-review --template perkee/elm-review-prefer-html-extra/example
```

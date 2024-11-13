# elm-order-safe-json-object-decoders

Decode JSON objects into Elm records without the risk of field order errors

```elm
module Main exposing (main)

import Html exposing (Html)
import Json.Decode as JD
import Json.Decode.Safe as JDS



{- Let's say we want to decode this: -}

userJson : String
userJson =
    """
{
  "firstName": "Ed",
  "lastName": "Kelly",
  "pets": 0
}
"""



{- Into this: -}


type alias User =
    { firstName : String
    , lastName : String
    , pets : Int
    }



{- We can show our results here: -}

main : Html msg
main =
    Html.div []
        [ Html.strong [] 
            [ Html.text "Let's see if our user decoder works..." ]
        , Html.pre []
            [ Html.text <|
                case JD.decodeString userDecoder userJson of
                    Ok user ->
                        Debug.toString user

                    Err errs ->
                        JD.errorToString errs
            ]
        ]



{- The API for our decoders is slightly different from the API of the
   `NoRedInk/elm-json-decode-pipeline` package, which would be something
   like this:

   JD.succeed User
       |> JD.field "firstName" JD.string
       |> JD.field "lastName" JD.string
       |> JD.field "pets" JD.int

   Notably, we _don't_ use the `User` constructor in our decoder. Instead,
   we must define a constructor function ourselves as a top-level function.
   This is because we need the constructor to be polymorphic: for example,
   instead of being restricted to take a `String` for the `firstName` field
   and an `Int` for the `pets` field, each of its fields must be able to
   take _any_ type of value.

   Here's an example of a polymorphic constructor function:
-}


userConstructor : a -> b -> c -> { firstName : a, lastName : b, pets : c }
userConstructor firstName lastName pets =
    { firstName = firstName
    , lastName = lastName
    , pets = pets
    }



{- Here are the other API differences:

   * We open our decoding pipeline with a function called `record` instead
   of `succeed`. We pass our polymorphic constructor function into `record`
   _twice_, instead of passing it into `succeed` once.

   * Each time we call our `field` function, we pass in a record
   accessor function in addition to the JSON field name and decoder.

   * We end our pipeline with a function called `endRecord`.

   Here's an example of a decoder:
-}


userDecoder : JD.Decoder User
userDecoder =
    JDS.record userConstructor userConstructor
        |> JDS.field "firstName" .firstName JD.string
        |> JDS.field "lastName" .lastName JD.string
        |> JDS.field "pets" .pets JD.int
        |> JDS.endRecord



{- Here's an example of a decoder that will fail at compile time,
   because we've got the `firstName` and `lastName` fields in the wrong
   order.
-}


userDecoder : JD.Decoder User
brokenUserDecoder =
    JDS.record userConstructor userConstructor
        |> JDS.field "lastName" .lastName JD.string
        |> JDS.field "firstName" .firstName JD.string
        |> JDS.field "pets" .pets JD.int
        |> JDS.endRecord
            
```

# elm-order-safe-json-object-decoders

Decode JSON objects into Elm records without the risk of field order errors

Let's say we want to decode this:
```elm
userJson : String
userJson =
    """
{
  "firstName": "Ed",
  "lastName": "Kelly",
  "pets": 0
}
"""
```


Into this:


```elm
type alias User =
    { firstName : String
    , lastName : String
    , pets : Int
    }
```


The API for our decoders is slightly different from the API of the
`NoRedInk/elm-json-decode-pipeline` package, which would be something
like this:

```elm
import Json.Decode as JD
import Json.Decode.Pipeline as JDP

userDecoder = 
    JD.succeed User
        |> JDP.field "firstName" JD.string
        |> JDP.field "lastName" JD.string
        |> JDP.field "pets" JD.int
```

The biggest and most important difference is that we _don't_ use the `User` 
constructor in our decoder. Instead, we must define a constructor function 
ourselves as a top-level function.

This is because we need the constructor to be polymorphic. For example,
instead of being restricted to take a `String` for the `firstName` and 
`lastName` fields and an `Int` for the `pets` field, each of its fields 
must be able to take _any_ type of value.

Here's an example of a polymorphic constructor function:

```elm
userConstructor : a -> b -> c -> { firstName : a, lastName : b, pets : c }
userConstructor firstName lastName pets =
    { firstName = firstName
    , lastName = lastName
    , pets = pets
    }
```

Here are the other API differences:

* We open our decoding pipeline with a function called `record` instead
  of `succeed`. 
  
* We pass our polymorphic constructor function into `record`
  _twice_, instead of passing it into `succeed` once.

* Each time we call our `field` function, we pass in a record
  accessor function in addition to the JSON field name and decoder.

* We end our pipeline with a function called `endRecord`.

Here's an example of a decoder:

```elm
import Json.Decode as JD
import Json.Decode.Safe as JDS

userDecoder : JD.Decoder User
userDecoder =
    JDS.record userConstructor userConstructor
        |> JDS.field "firstName" .firstName JD.string
        |> JDS.field "lastName" .lastName JD.string
        |> JDS.field "pets" .pets JD.int
        |> JDS.endRecord
```


Here's an example of a decoder that will fail at compile time,
because we've got the `firstName` and `lastName` fields in the wrong
order.

```elm
userDecoder : JD.Decoder User
brokenUserDecoder =
    JDS.record userConstructor userConstructor
        |> JDS.field "lastName" .lastName JD.string
        |> JDS.field "firstName" .firstName JD.string
        |> JDS.field "pets" .pets JD.int
        |> JDS.endRecord
```

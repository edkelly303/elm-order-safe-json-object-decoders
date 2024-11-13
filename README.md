# elm-order-safe-json-object-decoders

## What does this do?

It decodes JSON objects into Elm records without the risk of field order errors.

## What's actually even the problem?

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

And we write a decoder using `elm/json` and `NoRedInk/elm-json-decode-pipeline` 
packages:

```elm
import Json.Decode as JD
import Json.Decode.Pipeline as JDP

userDecoder = 
    JD.succeed User
        |> JDP.field "lastName" JD.string
        |> JDP.field "firstName" JD.string
        |> JDP.field "pets" JD.int
```

Uh oh! Did you spot the mistake?

The implicit constructor `User` requires us to decode the `firstName` field first, and the `lastName` field second - but we've done it the wrong way around. Because both fields will decode successfully as `String`s,
there's no way for Elm to detect that we've blundered, so our user will be forever known by the stupid 
name "Kelly Ed", instead of his rightful and extremely cool name, "Ed Kelly".

## So there's no way for Elm to detect this... Ok, move along, nothing to see here.

Hang on, hold my beer.

Right, there actually is a way for Elm to detect this, and that's what this package does.

If you write a similarly broken decoder using this package, you'll get a compiler error like this:

```code
This function cannot handle the argument sent through the (|>) pipe:

118|     record userConstructor userConstructor
119|         |> field "lastName" .lastName JD.string
120|         |> field "firstName" .firstName JD.string
121|         |> field "pets" .pets JD.int
122|         |> end
                ^^^
The argument is:

    JD.Decoder
        { expectedFieldOrder :
              { firstName : Zero
              , lastName : OnePlus Zero
              , pets : OnePlus (OnePlus Zero)
              }
        , gotFieldOrder :
              { firstName : OnePlus Zero
              , lastName : Zero
              , pets : OnePlus (OnePlus Zero)
              }
              -> Bool
        , recordType : { firstName : String, lastName : String, pets : Int }
        , totalFieldCount : OnePlus (OnePlus (OnePlus Zero))
        }
```

If you know about [Peano numbers](https://en.wikipedia.org/wiki/Peano_axioms), this might be clear to you
already; if not, I can explain!

Look at the `expectedFieldOrder` field:
* `firstName` should be the first field we pass to our constructor function. As we are programmers, let's call it "field zero". So we expect it to have a field order of `Zero` = 0. 
* `lastName` should be "field one". So it should have a field order of `OnePlus Zero` = 1.
* `pets` should be "field two". So it should have a field order of `OnePlus (OnePlus Zero)` = 2.

Now look at the `gotFieldOrder` field. Due to mistake we made in writing the decoder:
* `firstName` actually got a field order of `OnePlus Zero` = 1.
* `lastName` actually got a field order of `Zero` = 0.
* Only `pets` got the field order we expected, `OnePlus (OnePlus Zero)` = 2.

## Sounds neat! How do I use it?

The API for our decoders is slightly different from the API of the
`NoRedInk/elm-json-decode-pipeline` package.

### Polymorphic constructors

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

### API differences 

Here are the other API differences from `NoRedInk/elm-json-decode-pipeline`:

* We open our decoding pipeline with a function called `record` instead
  of `succeed`. 
  
* We pass our polymorphic constructor function into `record`
  _twice_, instead of passing it into `succeed` once.

* Each time we call our `field` function, we pass in a record
  accessor function in addition to the JSON field name and decoder.

* We end our pipeline with a function called `endRecord`.

## And what does that look like in practice?

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
brokenUserDecoder : JD.Decoder User
brokenUserDecoder =
    JDS.record userConstructor userConstructor
        |> JDS.field "lastName" .lastName JD.string
        |> JDS.field "firstName" .firstName JD.string
        |> JDS.field "pets" .pets JD.int
        |> JDS.endRecord
```

## How does it work?

My friend, that is a story for another day! Suffice to say, it's completely 
type-safe, it doesn't rely on any evil JavaScript FFI or other weirdness, 
and it won't crash.
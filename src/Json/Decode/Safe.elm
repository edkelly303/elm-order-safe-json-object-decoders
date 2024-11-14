module Json.Decode.Safe exposing
    ( Builder
    , record, field, endRecord
    , Zero, OnePlus
    )

{-|

@docs record, field, endRecord
@docs Builder, Zero, OnePlus

-}

import Json.Decode as JD


{-| An intermediate data structure used to check that the decoders we are 
creating have their fields in the correct order. A `Builder` is created by the 
`record` function, updated by the `field` function, and finally converted into a 
`Json.Decode.Decoder` by the `endRecord` function.
-}
type Builder safety a
    = Builder (JD.Decoder a)


{-| Used for type safety. 
-}
type Zero
    = Zero Never


{-| Used for type safety.
-}
type OnePlus a
    = OnePlus Never


{-| Start constructing a record decoder.

**⚠️ You will need to supply a polymorphic record constructor function as both 
arguments to this function. ⚠️**

For example, if you want to decode a record like this:

    type alias User =
        { firstName : String
        , lastName : String
        , pets : Int
        }

You must **not** use the `User` constructor. Instead, you will need to write a 
constructor function as follows:

    userConstructor : a -> b -> c -> { firstName : a, lastName : b, pets : c }
    userConstructor firstName lastName pets =
        { firstName = firstName
        , lastName = lastName
        , pets = pets
        }

**Note:** it is _important_ that the type annotation does not constrain the 
types of the arguments passed into this constructor function. That is part of 
the secret of how this package works its magic!

Now, pass the polymorphic constructor function into `record` _twice_, like this:

    import Json.Decode.Safe exposing (record, field)

    userDecoder =
        record userConstructor userConstructor
            |> ...

-}
record :
    constructor
    -> validator
    ->
        Builder
            { expectedFieldOrder : validator
            , gotFieldOrder : a
            , totalFieldCount : Zero
            }
            constructor
record constructor _ =
    JD.succeed constructor
        |> Builder


{-| Add a field to a record decoder.

    import Json.Decode
    import Json.Decode.Safe exposing (record, field)

    userDecoder =
        record userConstructor userConstructor
            |> field "firstName" .firstName Json.Decode.string
            |> field "lastName" .lastName Json.Decode.string
            |> field "pets" .pets Json.Decode.int
            |> ...

-}
field :
    String
    -> (expectedFieldOrder -> totalFieldCount)
    -> JD.Decoder fieldValue
    ->
        Builder
            { expectedFieldOrder : totalFieldCount -> nextValidator
            , gotFieldOrder : expectedFieldOrder
            , totalFieldCount : totalFieldCount
            }
            (fieldValue -> nextConstructor)
    ->
        Builder
            { expectedFieldOrder : nextValidator
            , gotFieldOrder : expectedFieldOrder
            , totalFieldCount : OnePlus totalFieldCount
            }
            nextConstructor
field fieldName _ fieldValueDecoder (Builder builder) =
    JD.map2
        (\recordType fieldValue ->
            recordType fieldValue
        )
        builder
        (JD.field fieldName fieldValueDecoder)
        |> Builder


{-| Finalise the creation of a record decoder.

    import Json.Decode
    import Json.Decode.Safe exposing (endRecord, field, record)

    userDecoder =
        record userConstructor userConstructor
            |> field "firstName" .firstName Json.Decode.string
            |> field "lastName" .lastName Json.Decode.string
            |> field "pets" .pets Json.Decode.int
            |> endRecord

-}
endRecord :
    Builder
        { safety
            | expectedFieldOrder : expectedFieldOrder
            , gotFieldOrder : expectedFieldOrder
        }
        recordType
    -> JD.Decoder recordType
endRecord (Builder builder) =
    builder

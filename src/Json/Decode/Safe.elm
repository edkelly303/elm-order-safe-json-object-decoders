module Json.Decode.Safe exposing
    ( SafeDecoder
    , record, field, endRecord
    , Zero, OnePlus
    )

{-|

@docs SafeDecoder
@docs record, field, endRecord
@docs Zero, OnePlus

-}

import Json.Decode as JD


{-| -}
type SafeDecoder safety a
    = SafeDecoder (JD.Decoder a)


{-| Used for type safety.
-}
type Zero
    = Zero Never


{-| Used for type safety.
-}
type OnePlus a
    = OnePlus Never


{-| Start constructing a record decoder.

You will need to supply a polymorphic record constructor function as both arguments to this function.

For example, if you want to decode a record like this:

    type alias User =
        { firstName : String
        , lastName : String
        , pets : Int
        }

You will need to write a constructor function as follows:

    userConstructor : a -> b -> c -> { firstName : a, lastName : b, pets : c }
    userConstructor firstName lastName pets =
        { firstName = firstName
        , lastName = lastName
        , pets = pets
        }

**Note:** it is _important_ that the type annotation does not constrain the types of the arguments
passed into this constructor function. That is part of the secret of how this package works its
magic!

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
        SafeDecoder
            { recordType : constructor
            , expectedFieldOrder : validator
            , gotFieldOrder : a -> Bool
            , totalFieldCount : Zero
            }
            constructor
record constructor _ =
    JD.succeed constructor
        |> SafeDecoder


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
        SafeDecoder
            { expectedFieldOrder : totalFieldCount -> nextValidator
            , recordType : fieldValue -> nextConstructor
            , gotFieldOrder : expectedFieldOrder -> Bool
            , totalFieldCount : totalFieldCount
            }
            (fieldValue -> nextConstructor)
    ->
        SafeDecoder
            { expectedFieldOrder : nextValidator
            , recordType : nextConstructor
            , gotFieldOrder : expectedFieldOrder -> Bool
            , totalFieldCount : OnePlus totalFieldCount
            }
            nextConstructor
field fieldName _ fieldValueDecoder (SafeDecoder builder) =
    JD.map2
        (\recordType fieldValue ->
            recordType fieldValue
        )
        builder
        (JD.field fieldName fieldValueDecoder)
        |> SafeDecoder


{-| Finalise the definition of a record decoder.

    import Json.Decode
    import Json.Decode.Safe exposing (endRecord, field, record)

    userDecoder =
        record userConstructor userConstructor
            |> field "firstName" .firstName Json.Decode.string
            |> field "lastName" .lastName Json.Decode.string
            |> field "pets" .pets Json.Decode.int
            |> endRecord

-}
endRecord : SafeDecoder safety recordType -> JD.Decoder recordType
endRecord (SafeDecoder builder) =
    builder

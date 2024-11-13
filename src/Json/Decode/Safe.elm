module Json.Decode.Safe exposing (record, field, endRecord)

{-|

@docs record, field, endRecord

-}

import Json.Decode as JD


type Zero
    = Zero


type OnePlus a
    = OnePlus a


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

_Note:_ it is _important_ that the type annotation does not constrain the types of the arguments
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
        JD.Decoder
            { recordType : constructor
            , expectedFieldOrder : validator
            , totalFieldCount : Zero
            , gotFieldOrder : a -> Bool
            }
record constructor validator =
    JD.succeed
        { recordType = constructor
        , expectedFieldOrder = validator
        , totalFieldCount = Zero
        , gotFieldOrder = always True
        }


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
        JD.Decoder
            { expectedFieldOrder : totalFieldCount -> nextValidator
            , gotFieldOrder : expectedFieldOrder -> Bool
            , recordType : fieldValue -> nextConstructor
            , totalFieldCount : totalFieldCount
            }
    ->
        JD.Decoder
            { expectedFieldOrder : nextValidator
            , gotFieldOrder : expectedFieldOrder -> Bool
            , recordType : nextConstructor
            , totalFieldCount : OnePlus totalFieldCount
            }
field fieldName getField fieldValueDecoder builder =
    JD.map2
        (\{ recordType, expectedFieldOrder, totalFieldCount } fieldValue ->
            { recordType = recordType fieldValue
            , expectedFieldOrder = expectedFieldOrder totalFieldCount
            , totalFieldCount = OnePlus totalFieldCount
            , gotFieldOrder =
                \checkOutput ->
                    getField checkOutput == totalFieldCount
            }
        )
        builder
        (JD.field fieldName fieldValueDecoder)


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
endRecord :
    JD.Decoder
        { recordType : recordType
        , expectedFieldOrder : expectedFieldOrder
        , gotFieldOrder : expectedFieldOrder -> Bool
        , totalFieldCount : totalFieldCount
        }
    -> JD.Decoder recordType
endRecord builder =
    JD.map .recordType builder

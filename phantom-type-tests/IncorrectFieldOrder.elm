module IncorrectFieldOrder exposing (User, userDecoder)

import Json.Decode as JD
import Json.Decode.Safe as JDS


userDecoder : JD.Decoder User
userDecoder =
    JDS.record User userConstructor
        |> JDS.field "lastName" .lastName JD.string
        |> JDS.field "firstName" .firstName JD.string
        |> JDS.field "pets" .pets JD.int
        |> JDS.endRecord


userConstructor : a -> b -> c -> { firstName : a, lastName : b, pets : c }
userConstructor firstName lastName pets =
    { firstName = firstName
    , lastName = lastName
    , pets = pets
    }


type alias User =
    { firstName : String
    , lastName : String
    , pets : Int
    }

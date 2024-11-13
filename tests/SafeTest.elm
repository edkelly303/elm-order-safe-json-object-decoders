module SafeTest exposing (suite)

import Expect exposing (Expectation)
import Json.Decode as JD
import Json.Decode.Safe as JDS
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Json.Decode.Safe"
        [ test "should decode valid JSON" <|
            \() ->
                """
{
  "firstName": "Ed",
  "lastName": "Kelly",
  "pets": 0
}
"""
                    |> JD.decodeString userDecoder
                    |> Expect.equal
                        (Ok
                            { firstName = "Ed"
                            , lastName = "Kelly"
                            , pets = 0
                            }
                        )
        , test "should not decode invalid JSON" <|
            \() ->
                let
                    invalidJson : String
                    invalidJson =
                        """
{
  "firstName": "Ed",
  "pets": 0
}
"""
                in
                case JD.decodeString userDecoder invalidJson of
                    Ok _ ->
                        Expect.fail "Invalid JSON should not have been decoded successfully"

                    Err error ->
                        case error of
                            JD.Failure message _ ->
                                message
                                    |> Expect.equal "Expecting an OBJECT with a field named `lastName`"

                            _ ->
                                Expect.fail ("Expected JSON decoding Failure but got " ++ Debug.toString error)
        ]


userDecoder : JD.Decoder User
userDecoder =
    JDS.record User userConstructor
        |> JDS.field "firstName" .firstName JD.string
        |> JDS.field "lastName" .lastName JD.string
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

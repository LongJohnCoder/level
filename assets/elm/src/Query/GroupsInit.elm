module Query.GroupsInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import GraphQL exposing (Document)
import Route.Groups exposing (Params(..))
import Session exposing (Session)


type alias Response =
    { groups : Connection Group
    }


document : Params -> Document
document params =
    GraphQL.document (documentBody params)
        [ Connection.fragment "GroupConnection" Group.fragment
        ]


documentBody : Params -> String
documentBody params =
    case params of
        Root ->
            """
            query GroupsInit(
              $spaceId: ID!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                groups(first: $limit) {
                  ...GroupConnectionFields
                }
              }
            }
            """

        After cursor ->
            """
            query GroupsInit(
              $spaceId: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                groups(first: $limit, after: $cursor) {
                  ...GroupConnectionFields
                }
              }
            }
            """

        Before cursor ->
            """
            query GroupsInit(
              $spaceId: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                groups(last: $limit, before: $cursor) {
                  ...GroupConnectionFields
                }
              }
            }
            """


variables : String -> Params -> Int -> Maybe Encode.Value
variables spaceId params limit =
    let
        paramVariables =
            case params of
                After cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Before cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Root ->
                    []
    in
        Just <|
            Encode.object <|
                List.append paramVariables
                    [ ( "spaceId", Encode.string spaceId )
                    , ( "limit", Encode.int limit )
                    ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "space", "groups" ] <|
        Decode.map Response (Connection.decoder Group.decoder)


request : String -> Params -> Int -> Session -> Task Session.Error ( Session, Response )
request spaceId params limit session =
    Session.request session <|
        GraphQL.request (document params) (variables spaceId params limit) decoder

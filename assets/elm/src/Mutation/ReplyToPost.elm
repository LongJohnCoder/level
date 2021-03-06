module Mutation.ReplyToPost exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Reply exposing (Reply)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import GraphQL exposing (Document)
import Session exposing (Session)


type Response
    = Success Reply
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation ReplyToPost(
          $spaceId: ID!,
          $postId: ID!,
          $body: String!
        ) {
          replyToPost(
            spaceId: $spaceId,
            postId: $postId,
            body: $body
          ) {
            ...ValidationFields
            reply {
              ...ReplyFields
            }
          }
        }
        """
        [ Data.Reply.fragment
        , Data.ValidationFields.fragment
        ]


variables : String -> String -> String -> Maybe Encode.Value
variables spaceId postId body =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "postId", Encode.string postId )
            , ( "body", Encode.string body )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "replyToPost", "reply" ] Data.Reply.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "replyToPost", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "replyToPost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId postId body session =
    Session.request session <|
        GraphQL.request document (variables spaceId postId body) decoder

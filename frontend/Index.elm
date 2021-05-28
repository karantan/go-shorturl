module Index exposing (Model, Msg(..), init, main, update, view)

import Bootstrap.Alert as Alert
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Json.Decode as Decode exposing (Decoder, int, string)
import Json.Decode.Extra as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Loading exposing (LoaderType(..), defaultConfig, render)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { prefix : String
    , url : String
    , state : ModelState
    , serverMessage : String
    }


type ModelState
    = Failure
    | Loading
    | Success
    | Init


type alias Response =
    { message : String
    , status : Int
    }


decodeResponse : Decoder Response
decodeResponse =
    Decode.succeed Response
        |> Pipeline.required "message" string
        |> Pipeline.required "status" int


encodeModel : Model -> Encode.Value
encodeModel record =
    Encode.object
        [ ( "prefix", Encode.string <| record.prefix )
        , ( "url", Encode.string <| record.url )
        ]


init : () -> ( Model, Cmd Msg )
init _ =
    ( { prefix = ""
      , url = ""
      , state = Init
      , serverMessage = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = UpdatePrefix String
    | UpdateUrl String
    | SubmitPost
    | GotResponse (Result Http.Error Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdatePrefix prefix ->
            ( { model | prefix = prefix }, Cmd.none )

        UpdateUrl url ->
            ( { model | url = url }, Cmd.none )

        SubmitPost ->
            ( { model | state = Loading }, sendRequest model )

        GotResponse resp ->
            case resp of
                Ok serverResponse ->
                    ( { model
                        | state = Success
                        , serverMessage = serverResponse.message
                      }
                    , Cmd.none
                    )

                Err err ->
                    ( { model
                        | state = Failure
                        , serverMessage = errorToString err
                      }
                    , Cmd.none
                    )


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Http.Timeout ->
            "Unable to reach the server, try again"

        Http.NetworkError ->
            "Unable to reach the server, check your network connection"

        Http.BadStatus 500 ->
            "The server had a problem, try again later"

        Http.BadStatus 400 ->
            "Verify your information and try again"

        Http.BadStatus _ ->
            "Unknown error"

        Http.BadBody errorMessage ->
            errorMessage


sendRequest : Model -> Cmd Msg
sendRequest model =
    Http.post
        { body = Http.jsonBody <| encodeModel model
        , url = "/create"
        , expect = Http.expectJson GotResponse decodeResponse
        }


formDisabled : Model -> Bool
formDisabled { state } =
    if List.member state [ Failure, Success, Init ] then
        False

    else
        True



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Html.form [ Html.Attributes.class "form-signin" ]
        [ Html.h1 [] [ text "Go Small URL" ]
        , Html.div [] [ viewResult model ]
        , Html.label
            [ Html.Attributes.for "prefix"
            , Html.Attributes.class "sr-only"
            ]
            [ text "Prefix" ]
        , Html.input
            [ Html.Attributes.type_ "text"
            , Html.Attributes.id "prefix"
            , Html.Attributes.class "form-control"
            , Html.Attributes.placeholder "Prefix (e.g. sc2)"
            , onInput UpdatePrefix
            ]
            []
        , Html.label
            [ Html.Attributes.for "url"
            , Html.Attributes.class "sr-only"
            ]
            [ text "URL" ]
        , Html.input
            [ Html.Attributes.type_ "text"
            , Html.Attributes.id "url"
            , Html.Attributes.class "form-control"
            , Html.Attributes.placeholder "URL (e.g. https://google.com)"
            , Html.Attributes.required True
            , onInput UpdateUrl
            ]
            []
        , Html.button
            [ Html.Attributes.class "btn"
            , Html.Attributes.class "btn-lg"
            , Html.Attributes.class "btn-primary"
            , Html.Attributes.class "btn-block"
            , Html.Attributes.type_ "button"
            , Html.Attributes.disabled <| formDisabled model
            , Html.Events.onClick SubmitPost
            ]
            [ text "Submit" ]
        ]


viewResult : Model -> Html Msg
viewResult model =
    case model.state of
        Init ->
            div [] []

        Failure ->
            Alert.simpleDanger [] [ text model.serverMessage ]

        Loading ->
            div []
                [ p []
                    [ Loading.render
                        DoubleBounce
                        { defaultConfig | color = "#333" }
                        Loading.On
                    ]
                ]

        Success ->
            Alert.simpleSuccess [] [ text model.serverMessage ]

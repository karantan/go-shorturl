module Index exposing (Model, Msg(..), init, main, update, view)

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
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
                        , url = ""
                        , prefix = ""
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
formDisabled { state, url } =
    if url == "" then
        True

    else if List.member state [ Failure, Success, Init ] then
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
    Grid.container []
        [ Grid.row [] []
        , Grid.row [ Row.centerXs ]
            [ Grid.col [ Col.xs4 ]
                [ Card.config [ Card.outlineSecondary ]
                    |> Card.headerH4 [] [ text "Go-ShortURL" ]
                    |> Card.block []
                        [ Block.titleH4 [] [ viewResult model ]
                        , Block.custom <|
                            Form.form []
                                [ Form.group []
                                    [ Form.label [ for "prefix" ] [ text "Prefix" ]
                                    , Input.text
                                        [ Input.id "prefix"
                                        , Input.value model.prefix
                                        , Input.onInput UpdatePrefix
                                        ]
                                    , Form.help [] [ text "e.g. sc2" ]
                                    ]
                                , Form.group []
                                    [ Form.label [ for "url" ] [ text "URL" ]
                                    , Input.text
                                        [ Input.id "url"
                                        , Input.value model.url
                                        , Input.onInput UpdateUrl
                                        ]
                                    , Form.help [] [ text "e.g. https://mysite.com/best-article.html" ]
                                    ]
                                , Button.button
                                    [ Button.primary
                                    , Button.disabled <| formDisabled model
                                    , Button.onClick SubmitPost
                                    ]
                                    [ text "Submit" ]
                                ]
                        ]
                    |> Card.view
                ]
            ]
        ]


viewResult : Model -> Html Msg
viewResult model =
    case model.state of
        Init ->
            div [] []

        Failure ->
            Alert.simpleDanger [] [ text model.serverMessage ]

        Loading ->
            Loading.render
                Circle
                { defaultConfig | color = "#333" }
                Loading.On

        Success ->
            Alert.simpleSuccess [] [ text model.serverMessage ]

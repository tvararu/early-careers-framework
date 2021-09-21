# frozen_string_literal: true

require "swagger_helper"

require_relative "../shared/context/lead_provider_profiles_and_courses.rb"

describe "API", type: :request, swagger_doc: "v1/api_spec.json", with_feature_flags: { participant_data_api: "active" } do
  include_context "lead provider profiles and courses"

  let(:token) { LeadProviderApiToken.create_with_random_token!(cpd_lead_provider: cpd_lead_provider) }
  let(:bearer_token) { "Bearer #{token}" }
  let(:Authorization) { bearer_token }

  path "/api/v1/participants/ecf" do
    get "Retrieve multiple participants, replaces <code>/api/v1/participants</code>" do
      operationId :participants
      tags "ECF participants"
      security [bearerAuth: []]

      parameter name: :filter,
                in: :query,
                schema: {
                  "$ref": "#/components/schemas/ListFilter",
                },
                type: :object,
                style: :deepObject,
                explode: true,
                required: false,
                description: "Refine ECF participants to return.",
                example: { updated_since: "2020-11-13T11:21:55Z" }

      parameter name: :page,
                in: :query,
                schema: {
                  "$ref": "#/components/schemas/Pagination",
                },
                type: :object,
                style: :deepObject,
                explode: true,
                required: false,
                example: { page: 1, per_page: 5 },
                description: "Pagination options to navigate through the list of ECF participants."

      response "200", "A list of ECF participants" do
        schema({ "$ref": "#/components/schemas/MultipleECFParticipantsResponse" }, content_type: "application/vnd.api+json")

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" }, content_type: "application/vnd.api+json")

        run_test!
      end
    end
  end

  path "/api/v1/participants/ecf.csv" do
    get "Retrieve all participants in CSV format, replaces <code>/api/v1/participants.csv</code>" do
      operationId :ecf_participants_csv
      tags "ECF participants"
      security [bearerAuth: []]

      parameter name: :filter,
                in: :query,
                schema: {
                  "$ref": "#/components/schemas/ListFilter",
                },
                type: :object,
                style: :deepObject,
                explode: true,
                required: false,
                description: "Refine ECF participants to return.",
                example: { updated_since: "2020-11-13T11:21:55Z" }

      response "200", "A CSV file of ECF participants" do
        schema({ "$ref": "#/components/schemas/MultipleECFParticipantsCsvResponse" }, content_type: "text/csv")

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" }, content_type: "application/vnd.api+json")

        run_test!
      end
    end
  end
end
# frozen_string_literal: true

require "swagger_helper"

require_relative "../../shared/context/lead_provider_profiles_and_courses"

describe "API", type: :request, swagger_doc: "v2/api_spec.json" do
  include_context "lead provider profiles and courses"

  let(:token) { LeadProviderApiToken.create_with_random_token!(cpd_lead_provider: cpd_lead_provider) }
  let(:bearer_token) { "Bearer #{token}" }
  let(:Authorization) { bearer_token }

  path "/api/v2/participants/ecf" do
    get "Retrieve multiple participants, replaces <code>/api/v2/participants</code>" do
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
        schema({ "$ref": "#/components/schemas/MultipleECFParticipantsResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end

  path "/api/v2/participants/ecf.csv" do
    get "Retrieve all participants in CSV format, replaces <code>/api/v2/participants.csv</code>" do
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

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end

  it_behaves_like "JSON Participant Deferral documentation",
                  "/api/v2/participants/ecf/{id}/defer",
                  "#/components/schemas/ECFParticipantDeferRequest",
                  "#/components/schemas/ECFParticipantDeferResponse",
                  "ECF Participant" do
    let(:participant) { mentor_profile }
    let(:attributes) do
      {
        reason: "career-break",
        course_identifier: "ecf-mentor",
      }
    end
  end

  it_behaves_like "JSON Participant resume documentation",
                  "/api/v2/participants/ecf/{id}/resume",
                  "#/components/schemas/ECFParticipantResumeRequest",
                  "#/components/schemas/ECFParticipantResumeResponse",
                  "ECF Participant" do
    let(:participant) { mentor_profile }
    let(:attributes) { { course_identifier: "ecf-mentor" } }
  end

  path "/api/v2/participants/ecf/{id}/withdraw" do
    put "Notify that an ECF participant has withdrawn from their course" do
      operationId :participant
      tags "ECF Participant"
      security [bearerAuth: []]
      consumes "application/json"

      request_body content: {
        "application/json": {
          "schema": {
            "$ref": "#/components/schemas/ECFParticipantWithdrawRequest",
          },
        },
      }

      parameter name: :id,
                in: :path,
                type: :string,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the participant to withdraw"

      parameter name: :params,
                in: :body,
                type: :object,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/ECFParticipantWithdrawRequest",
                }

      response "200", "The ECF participant being withdrawn" do
        let(:id) { mentor_profile.user.id }
        let(:attributes) do
          {
            reason: "left-teaching-profession",
            course_identifier: "ecf-mentor",
          }
        end

        let(:params) do
          {
            "data": {
              "type": "participant",
              "attributes": attributes,
            },
          }
        end

        schema({ "$ref": "#/components/schemas/ECFParticipantWithdrawResponse" })
        run_test!
      end
    end
  end

  it_behaves_like "JSON Participant Change schedule documentation",
                  "/api/v2/participants/ecf/{id}/change-schedule",
                  "#/components/schemas/ECFParticipantChangeScheduleRequest",
                  "#/components/schemas/ECFParticipantResponse",
                  "ECF Participant",
                  :with_default_schedules do
    let(:participant) { mentor_profile }
    let(:attributes) do
      {
        schedule_identifier: "ecf-standard-september",
        course_identifier: "ecf-mentor",
      }
    end
  end
end
# frozen_string_literal: true

require "swagger_helper"

describe "API", :with_default_schedules, type: :request, swagger_doc: "v3/api_spec.json", api_v3: true do
  let(:cpd_lead_provider) { create(:cpd_lead_provider, npq_lead_provider:) }
  let(:npq_lead_provider) { create(:npq_lead_provider) }
  let(:token) { LeadProviderApiToken.create_with_random_token!(cpd_lead_provider:) }
  let(:Authorization) { "Bearer #{token}" }
  let!(:npq_application) { create(:npq_application, :accepted, npq_lead_provider:) }

  path "/api/v3/participants/npq" do
    get "Retrieve multiple NPQ participants" do
      operationId :npq_participants
      tags "NPQ participants"
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
                description: "Refine NPQ participants to return.",
                example: CGI.unescape({ updated_since: "2020-11-13T11:21:55Z" }.to_param)

      parameter name: :page,
                in: :query,
                schema: {
                  "$ref": "#/components/schemas/Pagination",
                },
                type: :object,
                style: :deepObject,
                explode: true,
                required: false,
                example: CGI.unescape({ page: { page: 1, per_page: 5 } }.to_param),
                description: "Pagination options to navigate through the list of NPQ participants."

      response "200", "A list of NPQ participants" do
        schema({ "$ref": "#/components/schemas/MultipleNPQParticipantsResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end

  path "/api/v3/participants/npq/{id}" do
    get "Get a single NPQ participant" do
      operationId :npq_participant
      tags "NPQ participants"
      security [bearerAuth: []]

      parameter name: :id,
                in: :path,
                type: :string,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the NPQ participant."

      response "200", "A single NPQ participant" do
        let(:id) { npq_application.participant_identity.external_identifier }

        schema({ "$ref": "#/components/schemas/NPQParticipantResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { npq_application.participant_identity.external_identifier }
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "404", "Not Found" do
        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end
    end
  end

  it_behaves_like "JSON Participant Change schedule documentation",
                  "/api/v3/participants/npq/{id}/change-schedule",
                  "#/components/schemas/NPQParticipantChangeScheduleRequest",
                  "#/components/schemas/NPQParticipantResponse",
                  "NPQ Participant",
                  :with_default_schedules do
    let(:participant) { npq_application }
    let(:profile)     { npq_application.profile }
    let(:new_schedule) do
      if Finance::Schedule::NPQLeadership::IDENTIFIERS.include?(profile.npq_course.identifier)
        create(:npq_leadership_schedule)
      elsif Finance::Schedule::NPQSpecialist::IDENTIFIERS.include?(profile.npq_course.identifier)
        create(:npq_specialist_schedule)
      else
        create(:npq_aso_schedule)
      end
    end

    let(:attributes) do
      {
        schedule_identifier: new_schedule.schedule_identifier,
        course_identifier: npq_application.npq_course.identifier,
        cohort: new_schedule.cohort.start_year,
      }
    end
  end

  it_behaves_like "JSON Participant Deferral documentation",
                  "/api/v3/participants/npq/{id}/defer",
                  "#/components/schemas/NPQParticipantDeferRequest",
                  "#/components/schemas/NPQParticipantResponse",
                  "NPQ Participant" do
    let(:participant) { npq_application }
    let(:attributes) do
      {
        reason: ParticipantProfile::DEFERRAL_REASONS.sample,
        course_identifier: npq_application.npq_course.identifier,
      }
    end
  end

  it_behaves_like "JSON Participant resume documentation",
                  "/api/v3/participants/npq/{id}/resume",
                  "#/components/schemas/NPQParticipantResumeRequest",
                  "#/components/schemas/NPQParticipantResponse",
                  "NPQ Participant" do
    let(:participant) { npq_application }
    let(:attributes) { { course_identifier: npq_application.npq_course.identifier } }
    before do
      DeferParticipant.new(
        participant_id: npq_application.participant_identity.external_identifier,
        reason: ParticipantProfile::DEFERRAL_REASONS.sample,
        course_identifier: npq_application.npq_course.identifier,
        cpd_lead_provider:,
      ).call
    end
  end

  path "/api/v3/participants/npq/{id}/withdraw" do
    put "Withdrawn a participant from a course" do
      operationId :npq_participants
      tags "NPQ Participant"
      security [bearerAuth: []]
      consumes "application/json"

      request_body content: {
        "application/json": {
          "schema": {
            "$ref": "#/components/schemas/NPQParticipantWithdrawRequest",
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
                  "$ref": "#/components/schemas/NPQParticipantWithdrawRequest",
                }

      response "200", "The NPQ participant being withdrawn" do
        let(:id) { npq_application.participant_identity.external_identifier }
        let(:attributes) do
          {
            reason: ParticipantProfile::NPQ::WITHDRAW_REASONS.sample,
            course_identifier: npq_application.npq_course.identifier,
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

        before do
          participant_profile = npq_application.profile
          user = npq_application.user
          course_identifier = npq_application.npq_course.identifier

          create(:npq_participant_declaration, participant_profile:, course_identifier:, user:)
        end

        schema({ "$ref": "#/components/schemas/NPQParticipantResponse" })

        run_test!
      end

      response "422", "Unprocessable entity" do
        let(:id) { npq_application.participant_identity.external_identifier }
        let(:attributes) do
          {
            reason: ParticipantProfile::NPQ::WITHDRAW_REASONS.sample,
            course_identifier: "bogus-course-identifier",
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

        schema({ "$ref": "#/components/schemas/ErrorResponse" })

        run_test!
      end
    end
  end
end

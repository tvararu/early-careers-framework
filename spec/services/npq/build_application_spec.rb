# frozen_string_literal: true

require "rails_helper"

RSpec.describe NPQ::BuildApplication do
  let!(:user)                      { create(:user) }
  let(:npq_lead_provider)          { create(:npq_lead_provider) }
  let(:npq_contract)               { create(:npq_contract, npq_lead_provider:, npq_course:) }
  let(:npq_course)                 { create(:npq_course) }
  let(:date_of_birth)              { Date.new(1980, 1, 1) }
  let(:npq_application_attributes) { attributes_for(:npq_application, npq_course:, npq_lead_provider:, date_of_birth:) }
  let(:nino)                       { SecureRandom.hex }
  let(:teacher_catchment_country)  { "France" }
  let(:teacher_catchment)          { "other" }
  let(:npq_application_params) do
    {
      active_alert: true,
      date_of_birth: npq_application_attributes[:date_of_birth],
      eligible_for_funding: true,
      funding_choice: npq_application_attributes[:funding_choice],
      headteacher_status: npq_application_attributes[:headteacher_status],
      nino:,
      works_in_school: npq_application_attributes[:works_in_school],
      school_urn: npq_application_attributes[:school_urn],
      school_ukprn: npq_application_attributes[:school_ukprn],
      teacher_reference_number: npq_application_attributes[:teacher_reference_number],
      teacher_reference_number_verified: true,
      teacher_catchment:,
      teacher_catchment_country:,
    }
  end

  subject(:service) { described_class }

  describe "call" do
    let(:npq_application) do
      service.call(
        npq_application_params:,
        npq_course_id: npq_course.id,
        npq_lead_provider_id: npq_lead_provider.id,
        user_id: user.id,
      )
    end

    it "creates an application" do
      expect(npq_application.save).to be true
      expect(npq_application)
        .to have_attributes(
          npq_application_params.merge(
            npq_course_id: npq_course.id,
            npq_lead_provider_id: npq_lead_provider.id,
            teacher_catchment_iso_country_code: "FRA",
          ),
        )
    end

    context "with teached catchement" do
      let(:teacher_catchment_country) { nil }

      context "when valid" do
        let(:teacher_catchment) { "england" }

        it "does store the iso alpha3 and catchment coutry for the UK", :aggregate_failures do
          expect(npq_application.save).to be true
          expect(npq_application.teacher_catchment_iso_country_code).to eq "GBR"
          expect(npq_application.teacher_catchment_country).to eq "United Kingdom of Great Britain and Northern Ireland"
        end
      end
    end

    context "with the teacher catchment country" do
      context "when not present" do
        let(:teacher_catchment_country) { "" }

        it "does not store the iso alpha3 country code", :aggregate_failures do
          expect(npq_application.save).to be true
          expect(npq_application.teacher_catchment_iso_country_code).to be nil
        end
      end

      context "when not found" do
        let(:teacher_catchment_country) { "wonderland" }
        before do
          allow(Sentry).to receive(:capture_message)
        end

        it "does not store the iso alpha3 country code", :aggregate_failures do
          expect(npq_application.save).to be true
          expect(npq_application.teacher_catchment_iso_country_code).to be nil
          expect(Sentry).to have_received(:capture_message).with("Could not find the ISO3166 alpha3 code for wonderland.", level: :warning)
        end
      end
    end

    it "adds a participant identity record" do
      expect { npq_application }.to change { ParticipantIdentity.count }.by(1)
    end

    context "when the user already has an identity record" do
      let!(:identity) { Identity::Create.call(user:) }

      it "sets the participant identity reference" do
        expect(npq_application.participant_identity.user).to eq user
      end
    end
  end
end

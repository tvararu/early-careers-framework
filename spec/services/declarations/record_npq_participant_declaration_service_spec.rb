# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::RecordNPQParticipantDeclaration do
  let(:cpd_lead_provider) { create(:cpd_lead_provider) }
  let(:another_lead_provider) { create(:cpd_lead_provider, name: "Unknown") }
  let(:npq_lead_provider) { create(:npq_lead_provider, cpd_lead_provider: cpd_lead_provider) }
  let(:npq_course) { create(:npq_course, identifier: "npq-leading-teaching") }
  let(:npq_profile) do
    create(:npq_validation_data,
           npq_lead_provider: npq_lead_provider,
           npq_course: npq_course)
  end
  let(:induction_coordinator_profile) { create(:induction_coordinator_profile) }
  let(:params) do
    {
      raw_event: "{\"participant_id\":\"37b300a8-4e99-49f1-ae16-0235672b6708\",\"declaration_type\":\"started\",\"declaration_date\":\"2021-06-21T08:57:31Z\",\"course_identifier\":\"npq-leading-teaching\"}",
      participant_id: npq_profile.user_id,
      declaration_date: "2021-06-21T08:46:29Z",
      declaration_type: "started",
      course_identifier: "npq-leading-teaching",
      cpd_lead_provider: another_lead_provider,
    }
  end

  let(:npq_params) do
    params.merge({ cpd_lead_provider: cpd_lead_provider })
  end
  let(:induction_coordinator_params) do
    npq_params.merge({ participant_id: induction_coordinator_profile.user_id })
  end

  it "creates a participant and profile declaration" do
    expect { described_class.call(npq_params) }.to change { ParticipantDeclaration.count }.by(1).and change { ProfileDeclaration.count }.by(1)
  end

  context "when user is not a participant" do
    it "does not create a declaration record and raises ParameterMissing for an invalid user_id" do
      expect { described_class.call(induction_coordinator_params) }.to raise_error(ActionController::ParameterMissing)
    end
  end
end

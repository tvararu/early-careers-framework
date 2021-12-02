# frozen_string_literal: true

require "rails_helper"

RSpec.describe NPQ::BuildApplication do
  let!(:user)                   { create(:user) }
  let(:npq_lead_provider)       { create(:npq_lead_provider) }
  let(:npq_contract)            { create(:npq_contract, npq_lead_provider: npq_lead_provider) }
  let(:npq_course)              { create(:npq_course, identifier: npq_contract.course_identifier) }
  let(:npq_application_attributes) { build(:npq_application, npq_course: npq_course, npq_lead_provider: npq_lead_provider) }
  let(:nino)                       { SecureRandom.hex }
  let(:npq_application_params) do
    {
      active_alert: true,
      date_of_birth: npq_application_attributes[:date_of_birth],
      eligible_for_funding: true,
      funding_choice: npq_application_attributes[:funding_choice],
      headteacher_status: npq_application_attributes[:headteacher_status],
      nino: nino,
      school_urn: npq_application_attributes[:school_urn],
      school_ukprn: npq_application_attributes[:school_ukprn],
      teacher_reference_number: npq_application_attributes[:teacher_reference_number],
      teacher_reference_number_verified: true,
    }
  end

  subject(:npq_application) do
    described_class.call(
      npq_application_params: npq_application_params,
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
          user_id: user.id,
        ),
      )
  end
end
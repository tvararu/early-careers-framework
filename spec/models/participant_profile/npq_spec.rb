# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantProfile::NPQ, type: :model do
  let(:profile) { create(:npq_participant_profile) }

  describe "#push_profile_to_big_query" do
    context "on create" do
      it "pushes profile to BigQuery" do
        allow(NPQ::StreamBigQueryProfileJob).to receive(:perform_later).and_call_original
        profile
        expect(NPQ::StreamBigQueryProfileJob).to have_received(:perform_later).with(profile_id: profile.id)
      end
    end

    context "on update" do
      it "pushes profile to BigQuery" do
        allow(NPQ::StreamBigQueryProfileJob).to receive(:perform_later).and_call_original
        profile
        profile.update!(school_urn: "123456")
        expect(NPQ::StreamBigQueryProfileJob).to have_received(:perform_later).with(profile_id: profile.id).twice
      end
    end
  end
end
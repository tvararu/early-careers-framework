# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantProfile::ECFPolicy, type: :policy do
  subject { described_class.new(user, participant_profile) }

  let(:participant_profile) { create(:participant_profile, :ecf) }

  context "being an admin" do
    let(:user) { create(:user, :admin) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:withdraw_record) }

    context "after the participant has provided validation data" do
      before do
        create(:ecf_participant_validation_data, participant_profile: participant_profile)
      end

      it { is_expected.to permit_action(:withdraw_record) }
    end

    context "when the participant is found to be ineligible" do
      before do
        create(:ecf_participant_validation_data, participant_profile: participant_profile)
        create(:ecf_participant_eligibility, :ineligible, participant_profile: participant_profile)
      end

      it { is_expected.to permit_action(:withdraw_record) }
    end

    context "with a declaration" do
      before do
        declaration_type = participant_profile.ect? ? :ect_participant_declaration : :mentor_participant_declaration
        create(declaration_type, participant_profile: participant_profile, user: participant_profile.user)
      end

      it { is_expected.to forbid_action(:withdraw_record) }
    end

    context "with only voided declarations" do
      before do
        declaration_type = participant_profile.ect? ? :ect_participant_declaration : :mentor_participant_declaration
        create(declaration_type, :voided, participant_profile: participant_profile, user: participant_profile.user)
      end

      it { is_expected.to permit_action(:withdraw_record) }
    end
  end

  context "induction tutor at the correct school" do
    let(:user) { create(:user, :induction_coordinator, schools: [participant_profile.school]) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:withdraw_record) }

    context "after the participant has provided validation data" do
      before do
        create(:ecf_participant_validation_data, participant_profile: participant_profile)
      end

      it { is_expected.to forbid_action(:withdraw_record) }
    end

    context "when the participant is found to be ineligible" do
      before do
        create(:ecf_participant_validation_data, participant_profile: participant_profile)
        create(:ecf_participant_eligibility, :ineligible, participant_profile: participant_profile)
      end

      it { is_expected.to permit_action(:withdraw_record) }
    end

    context "with a declaration" do
      before do
        declaration_type = participant_profile.ect? ? :ect_participant_declaration : :mentor_participant_declaration
        create(declaration_type, participant_profile: participant_profile, user: participant_profile.user)
      end

      it { is_expected.to forbid_action(:withdraw_record) }
    end

    context "with only voided declarations" do
      before do
        declaration_type = participant_profile.ect? ? :ect_participant_declaration : :mentor_participant_declaration
        create(declaration_type, :voided, participant_profile: participant_profile, user: participant_profile.user)
      end

      it { is_expected.to permit_action(:withdraw_record) }
    end
  end

  context "induction tutor at a different school" do
    let(:user) { create(:user, :induction_coordinator) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:withdraw_record) }
  end
end
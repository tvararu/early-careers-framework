# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Participants::Search, :with_default_schedules do
  let(:search) { Admin::Participants::Search }

  describe "searching" do
    let!(:user_1) { create(:user, full_name: "Andrew Armstrong", email: "aaaa@example.com") }
    let!(:user_2) { create(:user, full_name: "Bonnie Benson", email: "bbbb@example.com") }
    let!(:user_3) { create(:user, full_name: "Charles Cross", email: "cccc@example.com") }

    let!(:pp_1) { create(:ecf_participant_profile, user: user_1) }
    let!(:pp_2) { create(:ecf_participant_profile, user: user_2) }
    let!(:pp_3) { create(:npq_participant_profile, user: user_3) }

    context "when searching with a string" do
      describe "matching by name (case insensitively)" do
        let(:results) { search.call(ParticipantProfile, search_term: "ben") }

        it "returns matching participants" do
          expect(results).to include(pp_2)
        end

        it "doesn't return non-matching participants" do
          expect(results).not_to include(pp_1, pp_3)
        end
      end

      describe "matching by user email (case insensitively)" do
        let(:results) { search.call(ParticipantProfile, search_term: "ccc") }

        it "returns matching participants" do
          expect(results).to include(pp_3)
        end

        it "doesn't return non-matching participants" do
          expect(results).not_to include(pp_1, pp_2)
        end
      end

      describe "matching by participant identity email (case insensitively)" do
        before do
          pp_2.participant_identity.update(email: "dddd@example.com")
        end

        let(:results) { search.call(ParticipantProfile, search_term: "ddd") }

        it "returns matching participants" do
          expect(results).to include(pp_2)
        end

        it "doesn't return non-matching participants" do
          expect(results).not_to include(pp_1, pp_3)
        end
      end

      describe "matching by TRN" do
        before { pp_3.teacher_profile.update(trn: "123456") }

        let(:results) { search.call(ParticipantProfile, search_term: "1234") }

        it "returns matching participants" do
          expect(results).to include(pp_3)
        end

        it "doesn't return non-matching participants" do
          expect(results).not_to include(pp_1, pp_2)
        end
      end
    end
  end
end

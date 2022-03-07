# frozen_string_literal: true

RSpec.describe Schools::Participants::StatusTableRow, type: :view_component do
  let!(:school_cohort) { create :school_cohort, :fip }
  let!(:partnership) { create :partnership, school: school_cohort.school, cohort: school_cohort.cohort }
  let!(:ecf_participant_eligibility) { create :ecf_participant_eligibility, :eligible }
  let(:participant_profile) { create :ect_participant_profile, ecf_participant_eligibility: ecf_participant_eligibility, school_cohort: school_cohort }

  component { described_class.new profile: participant_profile }

  context "participant is on full induction programme" do
    context "participant is eligible" do
      it "renders the row" do
        with_request_url "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants" do
          expect(rendered).to have_link participant_profile.user.full_name, href: "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants/#{participant_profile.id}"
          expect(rendered).to have_content participant_profile.school_cohort.lead_provider.name
          expect(rendered).to have_content participant_profile.school_cohort.delivery_partner.name
          expect(rendered).to have_content participant_profile.start_term.humanize
        end
      end
    end

    context "participant is ineligible" do
      it "renders the row" do
        participant_profile.ecf_participant_eligibility.ineligible_status!

        with_request_url "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants" do
          expect(rendered).to have_link participant_profile.user.full_name, href: "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants/#{participant_profile.id}"
          expect(rendered).not_to have_content participant_profile.school_cohort.lead_provider.name
          expect(rendered).not_to have_content participant_profile.school_cohort.delivery_partner.name
          expect(rendered).to have_text "Remove"
        end
      end
    end
  end

  context "participant is on core induction programme" do
    before do
      school_cohort.core_induction_programme!
      school_cohort.update!(core_induction_programme: create(:core_induction_programme))
    end

    context "participant is eligible" do
      it "renders the row" do
        with_request_url "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants" do
          expect(rendered).to have_link participant_profile.user.full_name, href: "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants/#{participant_profile.id}"
          expect(rendered).to have_content school_cohort.core_induction_programme.name
          expect(rendered).to have_content participant_profile.start_term.humanize
        end
      end
    end

    context "participant is ineligible" do
      it "renders the row" do
        participant_profile.ecf_participant_eligibility.ineligible_status!

        with_request_url "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants" do
          expect(rendered).to have_link participant_profile.user.full_name, href: "/schools/#{school_cohort.school.slug}/cohorts/#{school_cohort.cohort.start_year}/participants/#{participant_profile.id}"
          expect(rendered).not_to have_content school_cohort.core_induction_programme.name
          expect(rendered).to have_text "Remove"
        end
      end
    end
  end
end
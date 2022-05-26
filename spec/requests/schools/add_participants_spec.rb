# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Schools::AddParticipant", type: :request do
  let(:user) { create(:user, :induction_coordinator) }
  let!(:school_cohort) { create(:school_cohort, :fip, school: school, cohort: cohort) }
  let(:school) { user.induction_coordinator_profile.schools.sample }
  let(:cohort) { create(:cohort, :current) }

  subject { response }

  before do
    sign_in user
  end

  describe "GET /schools/:school_id/cohorts/:cohort_id/participants/add" do
    before do
      get "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add", params: { type: :ect }
    end

    it "sets up the form in the session" do
      expect(session[:schools_add_participant_form]).to include("school_cohort_id" => school_cohort.id)
    end
  end

  describe "GET /schools/:school_id/cohorts/:cohort_id/participants/add/who", with_feature_flags: { change_of_circumstances: "active" } do
    context "when form has been set up in the session" do
      before do
        get "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/who"
      end

      it "renders the expected page" do
        expect(subject).to render_template(:who)
        expect(response.body).to include("A teacher transferring from another school")
        expect(response.body).to include("A new ECT")
      end
    end
  end

  describe "PUT /schools/:school_id/cohorts/:cohort_id/participants/add/who", with_feature_flags: { change_of_circumstances: "active", multiple_cohorts: "active" } do
    context "when transfer in the active_registration_cohort" do
      before do
        put "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/chosen-who-to-add", params: { schools_new_participant_or_transfer_form: { type: :transfer } }
      end

      it "redirects to the check transfers page" do
        expect(subject).to redirect_to check_transfer_schools_transferring_participant_path
      end
    end

    context "when transferring in the previous cohort" do
      before do
        create(:cohort, :next)
        put "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/chosen-who-to-add", params: { schools_new_participant_or_transfer_form: { type: :transfer } }
      end

      it "redirects to the what we need schools transferring page" do
        expect(subject).to redirect_to what_we_need_schools_transferring_participant_path
      end
    end
  end

  Schools::AddParticipantForm.steps.keys.without(:email_taken).each do |step|
    describe "GET /schools/:school_id/cohort/:cohort_id/participants/add/#{step.to_s.dasherize}" do
      context "when session has not been set up with the form" do
        before do
          get "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/#{step.to_s.dasherize}"
        end

        it { is_expected.to redirect_to schools_cohort_path(school.slug, cohort.start_year) }
      end

      context "when form has been set up in the session" do
        before do
          set_session(:schools_add_participant_form, {
            type: :ect,
            full_name: Faker::Name.name,
            email: Faker::Internet.email,
            date_of_birth: Date.new(1990, 1, 1),
            mentor_id: "later",
            school_cohort_id: school_cohort.id,
            current_user_id: user.id,
            start_date: Date.new(2022, 5, 5),
          })
          get "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/#{step.to_s.dasherize}"
        end

        it { is_expected.to render_template step }
      end
    end
  end

  describe "GET /schools/cohort/:cohort_id/participants/add/email_taken" do
    context "when session has not been set up with the form" do
      before do
        get "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/email-taken"
      end

      it { is_expected.to redirect_to schools_cohort_path(school_id: school.slug, cohort_id: cohort.start_year) }
    end

    context "when form has been set up in the session" do
      let(:email) { Faker::Internet.email }
      let!(:other_user) { create :user, email: email }

      before do
        set_session(:schools_add_participant_form,
                    type: :ect,
                    full_name: Faker::Name.name,
                    email: email,
                    date_of_birth: Date.new(1990, 1, 1),
                    mentor_id: "later",
                    school_cohort_id: school_cohort.id,
                    current_user_id: user.id)
        get "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/email-taken"
      end

      it { is_expected.to render_template :email_taken }
    end
  end

  describe "PUT /schools/cohort/:cohort_id/participants/add/transfer" do
    context "when form has been set up in the session" do
      let(:email) { Faker::Internet.email }
      let!(:other_user) { create :user, email: email }
      context "when participant is a transfer" do
        before do
          set_session(:schools_add_participant_form,
                      type: :ect,
                      full_name: Faker::Name.name,
                      email: email,
                      date_of_birth: Date.new(1990, 1, 1),
                      mentor_id: "later",
                      school_cohort_id: school_cohort.id,
                      current_user_id: user.id,
                      transfer: "true")
          put "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/transfer", params: { step: :transfer }
        end

        it { is_expected.to redirect_to teacher_start_date_schools_transferring_participant_path }
      end

      context "when participant is not a transfer" do
        before do
          set_session(:schools_add_participant_form,
                      type: :ect,
                      full_name: Faker::Name.name,
                      email: email,
                      date_of_birth: Date.new(1990, 1, 1),
                      mentor_id: "later",
                      school_cohort_id: school_cohort.id,
                      current_user_id: user.id,
                      transfer: "false")
          put "/schools/#{school.slug}/cohorts/#{cohort.start_year}/participants/add/transfer", params: { step: :transfer }
        end

        it { is_expected.to render_template :cannot_add }
      end
    end
  end
end

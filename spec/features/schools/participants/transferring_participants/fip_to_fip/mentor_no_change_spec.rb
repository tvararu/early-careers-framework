# frozen_string_literal: true

require "rails_helper"

RSpec.describe "transferring participants", with_feature_flags: { change_of_circumstances: "active" }, type: :feature, js: true do
  context "Transferring a Mentor to a school" do
    context "Mentor has matching lead provider and delivery partner" do
      before do
        allow_participant_transfer_mailers
        set_participant_data
        set_dqt_validation_result
        given_there_are_two_schools_that_have_chosen_fip_for_2021_and_partnered
        and_there_is_a_mentor_who_will_be_transferring
        and_i_am_signed_in_as_an_induction_coordinator
        when_i_click_on_view_your_early_career_teacher_and_mentor_details
        then_i_am_taken_to_your_ect_and_mentors_page
      end

      scenario "Induction tutor can transfer an Mentor to their school" do
        when_i_click_to_add_a_new_ect_or_mentor
        then_i_should_be_on_the_who_to_add_page

        when_i_select_transfer_teacher_option
        click_on "Continue"
        then_i_should_be_on_what_we_need_page

        click_on "Continue"
        then_i_should_be_on_full_name_page

        when_i_update_the_name_with(@participant_data[:full_name])
        click_on "Continue"
        then_i_should_be_on_trn_page

        when_i_add_a_valid_trn
        click_on "Continue"
        then_i_should_be_on_the_date_of_birth_page

        when_i_add_a_valid_date_of_birth
        click_on "Continue"

        when_i_add_a_valid_start_date
        click_on "Continue"

        then_i_should_be_on_the_add_email_page

        when_i_update_the_email_with("sally-mentor@example.com")
        click_on "Continue"

        then_i_should_be_taken_to_the_check_your_answers_page

        click_on "Confirm and add"
        then_i_should_be_on_the_complete_page
        and_the_participant_should_be_notified_with(:participant_transfer_in_notification)
        and_the_schools_current_provider_is_notified_with(:provider_existing_school_transfer_notification)

        click_on "View your ECTs and mentors"
        then_i_am_taken_to_your_ect_and_mentors_page

        click_on "Moving school"
        then_i_should_see_the_transferring_participant
      end

      # given

      def given_there_are_two_schools_that_have_chosen_fip_for_2021_and_partnered
        @cohort = create(:cohort, start_year: 2021)
        @school_one = create(:school, name: "Fip School 1")
        @school_two = create(:school, name: "Fip School 2")
        @school_cohort_one = create(:school_cohort, school: @school_one, cohort: @cohort, induction_programme_choice: "full_induction_programme")
        @school_cohort_two = create(:school_cohort, school: @school_two, cohort: @cohort, induction_programme_choice: "full_induction_programme")
        @lead_provider = create(:lead_provider, name: "Big Provider Ltd")
        @lead_provider_profile = create(:lead_provider_profile, lead_provider: @lead_provider)
        @delivery_partner = create(:delivery_partner, name: "Amazing Delivery Team")
        @mentor = create(:mentor_participant_profile, user: create(:user, full_name: "Billy Mentor"), school_cohort: @school_cohort_one)
        @partnership_one = create(:partnership, school: @school_one, lead_provider: @lead_provider, delivery_partner: @delivery_partner, cohort: @cohort)
        @partnership_two = create(:partnership, school: @school_two, lead_provider: @lead_provider, delivery_partner: @delivery_partner, cohort: @cohort)
        @induction_programme_one = create(:induction_programme, :fip, school_cohort: @school_cohort_one, partnership: @partnership_one)
        @induction_programme_two = create(:induction_programme, :fip, school_cohort: @school_cohort_two, partnership: @partnership_two)
        @school_cohort_one.update!(default_induction_programme: @induction_programme_one)
        @school_cohort_two.update!(default_induction_programme: @induction_programme_two)
      end

      # when

      def when_i_click_on_view_your_early_career_teacher_and_mentor_details
        click_on("View your early career teacher and mentor details")
      end

      def when_i_click_to_add_a_new_ect_or_mentor
        click_on "Add an ECT or mentor"
      end

      def when_i_select_transfer_teacher_option
        choose("A teacher transferring from another school where they’ve started ECF-based training or mentoring", allow_label_click: true)
      end

      def when_i_update_the_name_with(name)
        fill_in "Full_name", with: name
      end

      def when_i_update_the_email_with(email)
        fill_in "Email", with: email
      end

      def when_i_add_a_valid_trn
        fill_in "Teacher reference number (TRN)", with: "1001000"
      end

      def when_i_add_a_valid_date_of_birth
        fill_in "Day", with: "24"
        fill_in "Month", with: "10"
        fill_in "Year", with: "1990"
      end

      def when_i_add_a_valid_start_date
        fill_in "Day", with: "24"
        fill_in "Month", with: "10"
        fill_in "Year", with: "2023"
      end

      def when_i_select(option)
        choose(option)
      end

      # then

      def then_i_am_taken_to_your_ect_and_mentors_page
        expect(page).to have_selector("h1", text: "Your ECTs and mentors")
        expect(page).to have_text("Add an ECT or mentor")
        expect(page).to have_text("Add yourself as a mentor")
      end

      def then_i_should_be_on_what_we_need_page
        expect(page).to have_selector("h1", text: "What we need from you")
        expect(page).to have_text("To do this, you need to tell us their")
      end

      def then_i_should_be_on_full_name_page
        expect(page).to have_selector("h1", text: "What’s this person’s full name?")
      end

      def then_i_should_be_on_trn_page
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s teacher reference number (TRN)?")
      end

      def then_i_should_be_on_the_date_of_birth_page
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s date of birth?")
      end

      def then_i_should_be_on_the_teacher_start_date_page
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s start date at your school?")
      end

      def then_i_should_be_on_the_who_to_add_page
        expect(page).to have_selector("h1", text: "Who do you want to add?")
      end

      def then_i_should_be_on_the_add_email_page
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s email address?")
      end

      def then_i_should_be_taken_to_the_schools_current_programme_page
        expect(page).to have_selector("h1", text: "Will #{@participant_data[:full_name]} be training with your school's current providers?")
      end

      def then_i_should_be_taken_to_the_check_your_answers_page
        expect(page).to have_selector("h1", text: "Check your answers")
        expect(page).to have_selector("dd", text: @lead_provider.name)
        expect(page).to have_selector("dd", text: @delivery_partner.name)
      end

      def then_i_should_be_on_the_complete_page
        expect(page).to have_selector("h2", text: "What happens next")
        expect(page).to have_text("We’ll let #{@participant_data[:full_name]} know you’ve registered them for ECF-based training at your school")
      end

      def then_i_should_see_the_transferring_participant
        expect(page).to have_selector("h2", text: "Transferring to your school")
        within(:xpath, "//table[@data-test='transferring_in']/tbody/tr[1]") do
          expect(page).to have_xpath(".//td[1]", text: @participant_data[:full_name])
          expect(page).to have_xpath(".//td[2]", text: @lead_provider.name)
          expect(page).to have_xpath(".//td[3]", text: @delivery_partner.name)
        end
      end

      # and

      def and_i_am_signed_in_as_an_induction_coordinator
        @induction_coordinator_profile = create(:induction_coordinator_profile, schools: [@school_cohort_one.school], user: create(:user, full_name: "Carl Coordinator"))
        privacy_policy = create(:privacy_policy)
        privacy_policy.accept!(@induction_coordinator_profile.user)
        sign_in_as @induction_coordinator_profile.user
      end

      def and_there_is_a_mentor_who_will_be_transferring
        @participant_profile_mentor = create(:mentor_participant_profile, user: create(:user, full_name: "Sally Mentor"), school_cohort: @school_cohort_two)
        Induction::Enrol.call(participant_profile: @participant_profile_mentor, induction_programme: @induction_programme_two)

        create(:ecf_participant_validation_data, participant_profile: @participant_profile_mentor, full_name: "Sally Mentor", trn: "1001000", date_of_birth: Date.new(1990, 10, 24))
      end

      def and_the_participant_should_be_notified_with(notification_method)
        expect(ParticipantTransferMailer).to have_received(notification_method).with(induction_record: @participant_profile_mentor.induction_records.latest)
      end

      def and_the_schools_current_provider_is_notified_with(notification_method)
        expect(ParticipantTransferMailer).to have_received(notification_method)
                                               .with(hash_including(
                                                       induction_record: @participant_profile_mentor.induction_records.latest,
                                                       lead_provider_profile: @lead_provider_profile,
                                                     ))
      end

      def allow_participant_transfer_mailers
        allow(ParticipantTransferMailer).to receive(:participant_transfer_in_notification).and_call_original
        allow(ParticipantTransferMailer).to receive(:provider_existing_school_transfer_notification).and_call_original
      end

      def set_dqt_validation_result
        response = {
          trn: @participant_data[:trn],
          full_name: @participant_data[:full_name],
          nino: nil,
          dob: @participant_data[:date_of_birth],
          config: {},
        }
        allow_any_instance_of(ParticipantValidationService).to receive(:validate).and_return(response)
      end

      def set_participant_data
        @participant_data = {
          trn: "1001000",
          full_name: "Sally Mentor",
          date_of_birth: Date.new(1990, 10, 24),
          email: "sally-mentor@example.com",
        }
      end
    end
  end
end
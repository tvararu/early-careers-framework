# frozen_string_literal: true

require "rails_helper"

RSpec.describe "transferring participants", with_feature_flags: { change_of_circumstances: "active", multiple_cohorts: "active" }, type: :feature, js: true, rutabaga: false do
  context "Transferring an ECT to a school" do
    context "ECT has matching lead provider and delivery partner" do
      before do
        allow_participant_transfer_mailers
        set_participant_data
        set_dqt_validation_result
        given_there_are_two_schools_that_have_chosen_fip_for_2021_and_partnered
        and_there_is_an_ect_who_will_be_transferring
        and_i_am_signed_in_as_an_induction_coordinator
        and_select_the_most_recent_cohort
        when_i_click_to_view_ects_and_mentors
        then_i_am_taken_to_your_ect_and_mentors_page
      end

      scenario "Induction tutor can transfer an ECT to their school" do
        when_i_click_to_add_an_ect_or_mentor
        then_i_should_be_on_the_who_to_add_page

        when_i_select_transfer_teacher_option
        click_on "Continue"

        then_i_should_be_on_check_transfer_page
        when_i_choose_to_continue_the_transfer_journey

        then_i_should_be_on_what_we_need_page

        click_on "Continue"
        then_i_should_be_on_full_name_page

        when_i_update_the_name_with(@participant_data[:full_name])
        click_on "Continue"
        then_i_should_be_on_trn_page

        when_i_add_a_valid_trn
        click_on "Continue"

        when_i_add_a_valid_date_of_birth
        click_on "Continue"

        then_i_should_be_on_the_teacher_start_date_page
        when_i_add_a_valid_start_date
        click_on "Continue"

        then_i_should_be_on_the_add_email_page
        when_i_update_the_email_with("sally-teacher")
        click_on "Continue"

        when_i_update_the_email_with("sally-teacher@example.com")
        click_on "Continue"
        then_i_should_be_on_the_select_mentor_page

        when_i_assign_a_mentor
        click_on "Continue"

        click_on "Confirm and add"
        then_i_should_be_on_the_complete_page
        and_the_participant_should_be_notified_with(:participant_transfer_in_notification)
        and_the_schools_current_provider_is_notified_with(:provider_existing_school_transfer_notification)

        click_on "View your ECTs and mentors"
        then_i_am_taken_to_your_ect_and_mentors_page
        and_there_should_only_be_a_new_ect_in_the_previous_cohort

        # click_on "Moving school"
        # then_i_should_see_the_transferring_participant
      end

      # given

      def given_there_are_two_schools_that_have_chosen_fip_for_2021_and_partnered
        @cohort = create(:cohort, start_year: 2021)
        @school_one = create(:school, name: "Fip School 1")
        @school_two = create(:school, name: "Fip School 2")
        school_one_2022_cohort = create(:school_cohort, school: @school_one, cohort: create(:cohort, start_year: 2022), induction_programme_choice: "full_induction_programme")
        @school_cohort_one = create(:school_cohort, school: @school_one, cohort: @cohort, induction_programme_choice: "full_induction_programme")
        @school_cohort_two = create(:school_cohort, school: @school_two, cohort: @cohort, induction_programme_choice: "full_induction_programme")
        @lead_provider = create(:lead_provider, name: "Big Provider Ltd")
        @lead_provider_profile = create(:lead_provider_profile, lead_provider: @lead_provider)
        @delivery_partner = create(:delivery_partner, name: "Amazing Delivery Team")
        @mentor = create(:mentor_participant_profile, user: create(:user, full_name: "Billy Mentor"), school_cohort: @school_cohort_one)
        @partnership_1 = create(:partnership, school: @school_one, lead_provider: @lead_provider, delivery_partner: @delivery_partner, cohort: @cohort)
        @partnership_2 = create(:partnership, school: @school_two, lead_provider: @lead_provider, delivery_partner: @delivery_partner, cohort: @cohort)
        @induction_programme_one = create(:induction_programme, :fip, school_cohort: @school_cohort_one, partnership: @partnership_1)
        @induction_programme_two = create(:induction_programme, :fip, school_cohort: @school_cohort_two, partnership: @partnership_2)
        @school_one_2022_cohort_induction_programme = create(:induction_programme, :fip, school_cohort: school_one_2022_cohort, partnership: @partnership_1)
        @school_cohort_one.update!(default_induction_programme: @induction_programme_one)
        Induction::Enrol.call(participant_profile: @mentor, induction_programme: @school_one_2022_cohort_induction_programme)
        Mentors::AddToSchool.call(school: @school_one, mentor_profile: @mentor)
      end

      # when

      def when_i_click_to_view_ects_and_mentors
        click_on "Manage"
      end

      def when_i_click_to_add_an_ect_or_mentor
        click_on "Add an ECT or mentor"
      end

      def when_i_select_transfer_teacher_option
        choose("A teacher transferring from another school where they’ve started ECF-based training or mentoring", allow_label_click: true)
      end

      def when_i_choose_to_continue_the_transfer_journey
        click_on "Report a transferring ECT or mentor who started training in the #{Cohort.active_registration_cohort.previous.description} academic year"
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
        legend = "What’s #{@participant_data[:full_name]}’s date of birth?"

        fill_in_date(legend, with: "1990-10-24")
      end

      def when_i_add_a_valid_start_date
        legend = "#{@participant_data[:full_name]}’s start date"

        fill_in_date(legend, with: "2023-10-24")
      end

      def when_i_assign_a_mentor
        choose(@mentor.user.full_name)
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
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s teacher reference number (TRN)")
      end

      def then_i_should_be_on_the_date_of_birth_page
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s date of birth")
      end

      def then_i_should_be_on_the_teacher_start_date_page
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s start date at your school")
      end

      def then_i_should_be_on_the_who_to_add_page
        expect(page).to have_selector("h1", text: "Who do you want to add?")
      end

      def then_i_should_be_on_the_add_email_page
        expect(page).to have_selector("h1", text: "What’s #{@participant_data[:full_name]}’s email address?")
      end

      def then_i_should_be_on_the_select_mentor_page
        expect(page).to have_selector("h1", text: "Who will #{@participant_data[:full_name]}’s mentor be?")
      end

      def then_i_should_be_taken_to_the_check_your_answers_page
        expect(page).to have_selector("h1", text: "Check your answers")
        expect(page).to have_selector("dd", text: @mentor.user.full_name)
        expect(page).to have_selector("dd", text: @lead_provider.name)
        expect(page).to have_selector("dd", text: @delivery_partner.name)
      end

      def then_i_should_be_on_the_complete_page
        expect(page).to have_selector("h2", text: "What happens next")
        expect(page).to have_text("We’ll let #{@participant_profile_ect.user.full_name}")
      end

      def then_i_should_see_the_transferring_participant
        expect(page).to have_selector("h2", text: "Transferring to your school")
        within(:xpath, "//table[@data-test='transferring_in']/tbody/tr[1]") do
          expect(page).to have_xpath(".//td[1]", text: @participant_data[:full_name])
          expect(page).to have_xpath(".//td[2]", text: @lead_provider.name)
          expect(page).to have_xpath(".//td[3]", text: @delivery_partner.name)
        end
      end

      def then_i_should_be_on_check_transfer_page
        expect(page).to have_selector("h1", text: "Check you’re reporting this for the correct academic year")
      end

      # and

      def and_i_am_signed_in_as_an_induction_coordinator
        @induction_coordinator_profile = create(:induction_coordinator_profile, schools: [@school_cohort_one.school], user: create(:user, full_name: "Carl Coordinator"))
        privacy_policy = create(:privacy_policy)
        privacy_policy.accept!(@induction_coordinator_profile.user)
        sign_in_as @induction_coordinator_profile.user
      end

      def and_there_is_an_ect_who_will_be_transferring
        @participant_profile_ect = create(:ect_participant_profile, user: create(:user, full_name: "Sally Teacher"), school_cohort: @school_cohort_two)
        create(:ecf_participant_validation_data, participant_profile: @participant_profile_ect, full_name: "Sally Teacher", trn: "1001000", date_of_birth: Date.new(1990, 10, 24))
        Induction::Enrol.call(participant_profile: @participant_profile_ect, induction_programme: @induction_programme_two)
      end

      def and_it_should_list_the_schools_mentors
        expect(page).to have_text(@mentor.user.full_name)
      end

      def and_there_should_only_be_a_new_ect_in_the_previous_cohort
        expect(@school_one_2022_cohort_induction_programme.induction_records.count).to eq 1
        expect(@school_cohort_one.induction_records.count).to eq 1
      end

      def and_the_participant_should_be_notified_with(notification_method)
        expect(ParticipantTransferMailer).to have_received(notification_method)
                                               .with(hash_including(
                                                       induction_record: @participant_profile_ect.induction_records.latest,
                                                     ))
      end

      def and_the_schools_current_provider_is_notified_with(notification_method)
        induction_record = @participant_profile_ect.induction_records.latest
        expect(ParticipantTransferMailer).to have_received(notification_method)
                                               .with(hash_including(
                                                       induction_record:,
                                                       lead_provider_profile: @lead_provider_profile,
                                                     ))
      end

      def and_select_the_most_recent_cohort
        click_on Cohort.active_registration_cohort.description
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
          full_name: "Sally Teacher",
          date_of_birth: Date.new(1990, 10, 24),
          email: "sally-teacher@example.com",
        }
      end
    end
  end
end

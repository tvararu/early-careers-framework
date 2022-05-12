# frozen_string_literal: true

module ChooseProgrammeSteps
  include Capybara::DSL

  def freeze_time
    Timecop.freeze(Time.zone.local(2021, 5, 15, 16, 15, 0))
  end

  def reset_time
    Timecop.return
  end

  # Given steps

  def given_a_school_with_no_chosen_programme_for_next_academic_year
    @previous_cohort = create(:cohort, start_year: 2021)
    @cohort = create(:cohort, start_year: 2022)
    @school = create(:school, name: "NoECTsSchool")
    create(:school_cohort, :cip, school: @school, cohort: @previous_cohort)
  end

  def given_there_is_a_school_that_has_chosen_fip_for_2021_and_partnered
    given_there_is_a_school_that_has_chosen_fip_for_2021
    @lead_provider = create(:lead_provider, name: "Big Provider Ltd")
    @delivery_partner = create(:delivery_partner, name: "Amazing Delivery Team")
    create(:partnership, school: @school, lead_provider: @lead_provider, delivery_partner: @delivery_partner, cohort: @cohort, challenge_deadline: 2.weeks.ago)
  end

  def given_there_is_a_school_that_has_chosen_fip_for_2021_but_partnership_was_challenged
    given_there_is_a_school_that_has_chosen_fip_for_2021
    @lead_provider = create(:lead_provider, name: "Big Provider Ltd")
    @delivery_partner = create(:delivery_partner, name: "Amazing Delivery Team")
    create(:partnership, :challenged, school: @school, lead_provider: @lead_provider, delivery_partner: @delivery_partner, cohort: @cohort, challenge_deadline: 2.weeks.ago)
  end

  def given_there_is_a_school_that_has_chosen_fip_for_2021
    @cohort = @cohort_2022 = create(:cohort, start_year: 2021)
    @school = create(:school, name: "Fip School")
    @school_cohort = create(:school_cohort, school: @school, cohort: @cohort, induction_programme_choice: "full_induction_programme")
    @induction_programme = create(:induction_programme, :fip, school_cohort: @school_cohort)
    @school_cohort.update!(default_induction_programme: @induction_programme)
    @lead_provider_user = create(:user)
    @school_cohort.default_induction_programme.partnership.lead_provider.users << @lead_provider_user
  end

  # Then steps

  def then_i_am_taken_to_ects_expected_in_next_academic_year_page
    expect(page).to have_content(@school.name)
    expect(page).to have_content("Does your school expect any ECTs in the next academic year?")
  end

  def then_i_am_taken_to_the_submitted_page
    expect(page).to have_content("Your information has been saved")
  end

  def then_i_am_taken_to_the_manage_your_training_page
    expect(page).to have_content("Manage your training")
  end

  def then_i_am_taken_to_the_how_will_you_run_training_page
    expect(page).to have_content("How will you run training for new starters")
  end

  def then_i_am_taken_to_the_training_confirmation_page
    expect(page).to have_content("Are you sure this is how you want to run your training?")
  end

  def then_i_am_taken_to_the_training_submitted_page
    expect(page).to have_content("You’ve submitted your training information")
  end

  def then_i_am_taken_to_the_change_provider_page
    expect(page).to have_content("Are you planning to change your current training provider?")
  end

  def then_i_am_taken_to_the_complete_page
    expect(page).to have_content("You can now add ECTs and mentors when you’re ready")
  end

  def then_i_am_taken_to_what_changes_page
    expect(page).to have_content("What change do you plan to make?")
  end

  def then_i_am_taken_to_the_change_lead_provider_confirmation_page
    expect(page).to have_content("Are you sure you want to make this change?")
    expect(page).to have_content("#{@lead_provider.name} and #{@delivery_partner.name} will not be able to deliver training for ECTs and mentors starting in the 2022 to 2023 academic year.")
  end

  def then_i_am_taken_to_the_change_delivery_partner_confirmation_page
    expect(page).to have_content("Are you sure you want to make this change?")
    expect(page).to have_content("#{@delivery_partner.name} will not be able to deliver training for ECTs and mentors starting in the 2022 to 2023 academic year.")
  end

  def then_i_am_taken_to_the_change_to_design_own_programme_confirmation_page
    expect(page).to have_content("Confirm your training programme")
    expect(page).to have_content("You‘ve chosen to deliver your own programme using DfE accredited materials.")
  end

  def then_i_am_taken_to_the_change_to_design_and_deliver_own_programme_confirmation_page
    expect(page).to have_content("Confirm your training programme")
    expect(page).to have_content("You’re choosing to design and deliver your own programme based on the early career framework (ECF).")
  end

  def then_i_am_taken_to_the_training_change_submitted_page
    expect(page).to have_content("You’ve submitted your training information")
  end

  def then_a_notification_email_is_sent_to_the_lead_provider
    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued
      .with(
        "LeadProviderMailer",
        "programme_changed_email",
        "deliver_now",
        a_hash_including(:args),
      )
  end

  # And steps

  def and_i_am_signed_in_as_an_induction_coordinator
    @induction_coordinator_profile = create(:induction_coordinator_profile, schools: [@school], user: create(:user, full_name: "Carl Coordinator"))
    privacy_policy = create(:privacy_policy)
    privacy_policy.accept!(@induction_coordinator_profile.user)
    sign_in_as @induction_coordinator_profile.user
  end

  def and_i_click_continue
    click_on("Continue")
  end

  def and_cohort_2022_is_created
    @cohort_2022 = create(:cohort, start_year: 2022)
  end

  def and_the_next_cohort_is_open_for_registrations
    Timecop.freeze(Time.zone.local(2022, 5, 10, 16, 15, 0))
  end

  def and_the_dashboard_page_shows_the_no_ects_message
    expect(page).to have_content("Your school has told us you do not expect any ECTs")
  end

  def and_i_see_the_lead_provider
    expect(page).to have_content(@lead_provider.name)
  end

  def and_i_see_the_delivery_partner
    expect(page).to have_content(@delivery_partner.name)
  end

  def and_i_see_the_challenge_link
    expect(page).to have_link(text: "report that your school has been confirmed incorrectly")
  end

  def and_i_do_not_see_the_challenge_link
    expect(page).to_not have_link(text: "report that your school has been confirmed incorrectly")
  end

  def and_cohort_for_next_academic_year_is_created
    @cohort_2022 = create(:cohort, start_year: 2022)
  end

  def and_i_see_add_ects_link
    expect(page).to have_link("Add", href: schools_participants_path(cohort_id: @cohort.start_year, school_id: @school))
  end

  def and_i_see_training_provider_to_be_confirmed
    expect(page).to have_summary_row("Training provider", "To be confirmed")
  end

  def and_i_see_delivery_partner_to_be_confirmed
    expect(page).to have_summary_row("Delivery partner", "To be confirmed")
  end

  def and_i_see_programme_to_dfe_accredited_materials
    expect(page).to have_summary_row("Programme", "DfE accredited materials")
  end

  def and_i_see_programme_to_design_and_deliver_own_programme
    expect(page).to have_summary_row("Programme", "Design and deliver your own programme based on the Early Career Framework (ECF)")
  end

  def and_i_see_the_school_name
    expect(page).to have_content(@school.name)
  end

  def and_i_see_the_choose_training_material_content
    expect(page).to have_css("h2", text: "Choose your training materials")
    expect(page).to have_link("Tell us which materials you’ll use")
    expect(page).to have_link("compare materials")
  end

  def and_i_visit_the_school_manage_training
    visit(schools_dashboard_path(@school))
  end

  def and_i_choose_no
    when_i_choose_no
  end

  # When steps

  def when_i_start_programme_selection_for_next_cohort
    click_on("Start now")
  end

  def when_i_choose_no
    choose("No")
  end

  def when_i_choose_yes
    choose("Yes")
  end

  def when_i_choose_no_ects
    when_i_choose_no
  end

  def when_i_click_on_the_return_to_your_training_link
    click_on("Return to manage your training")
  end

  def when_i_choose_ects_expected
    choose("Yes")
  end

  def when_i_choose_dfe_funded_training
    choose("Use a training provider, funded by the DfE")
  end

  def when_i_click_the_confirm_button
    click_on("Confirm")
  end

  def when_i_choose_deliver_your_own_programme
    choose("Deliver your own programme using DfE-accredited materials")
  end

  def when_i_choose_design_and_deliver_your_own_material
    choose("Design and deliver you own programme based on the early career framework (ECF)")
  end

  def when_i_choose_to_leave_lead_provider
    choose("Leave #{@lead_provider.name} and use a different lead provider")
  end

  def when_i_choose_to_change_delivery_partner
    choose("Stay with #{@lead_provider.name} but change your delivery partner, #{@delivery_partner.name}")
  end

  def when_i_choose_to_deliver_own_programme
    choose("Deliver your own programme using DfE-accredited materials")
  end

  def when_i_choose_to_design_and_deliver_own_programme
    choose("Design and deliver you own programme based on the Early Career Framework (ECF)")
  end

  def when_i_challenge_the_new_cohort_partnership
    click_on("report that your school has been confirmed incorrectly")
    choose("This looks like a mistake")
    click_on("Submit")
  end

  def when_i_go_back_to_change_provider_page
    visit change_provider_schools_setup_school_cohort_path(@school, @cohort_2022)
  end

  def then_i_see_black_lp_and_dp_names
    expect(page).to have_summary_row("Training provider", "")
    expect(page).to have_summary_row("Delivery partner", "")
  end
end
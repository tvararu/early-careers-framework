# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Finance users payment breakdowns", :with_default_schedules, type: :feature, js: true do
  include FinanceHelper
  include ActionView::Helpers::NumberHelper

  let!(:lead_provider)    { create(:lead_provider, name: "Test provider", id: "cffd2237-c368-4044-8451-68e4a4f73369") }
  let(:cpd_lead_provider) { lead_provider.cpd_lead_provider }
  let!(:statement)        { create(:ecf_statement, cpd_lead_provider: cpd_lead_provider) }
  let!(:contract)         { create(:call_off_contract, lead_provider: lead_provider, version: "0.0.1") }
  let(:school)            { create(:school) }
  let(:cohort)            { contract.cohort }
  let!(:school_cohort)    { create(:school_cohort, school: school, cohort: cohort) }
  let!(:partnership)      { create(:partnership, school: school_cohort.school, lead_provider: lead_provider, cohort: cohort) }
  let(:induction_programme) { create(:induction_programme, partnership: partnership) }
  let(:nov_statement)     { Finance::Statement::ECF.find_by!(name: "November 2021", cpd_lead_provider: cpd_lead_provider) }
  let(:jan_statement)     { Finance::Statement::ECF.find_by!(name: "January 2022", cpd_lead_provider: cpd_lead_provider) }
  let(:voided_declarations) do
    participant_profiles = create_list(:ect_participant_profile, 2, school_cohort: school_cohort, cohort: contract.cohort, sparsity_uplift: true)
    participant_profiles.map { |participant| ParticipantProfileState.create!(participant_profile: participant) }
    participant_profiles.map { |participant| ECFParticipantEligibility.create!(participant_profile_id: participant.id).eligible_status! }
    participant_profiles.map { |participant| create_voided_declarations_nov(participant) }
  end
  let(:participant_aggregator_nov) do
    Finance::ECF::ParticipantAggregator.new(
      statement: nov_statement,
      recorder: ParticipantDeclaration::ECF.where(state: %w[paid payable eligible]),
    )
  end
  let(:participant_aggregator_jan) do
    Finance::ECF::ParticipantAggregator.new(
      statement: jan_statement,
      recorder: ParticipantDeclaration::ECF.where(state: %w[paid payable eligible]),
    )
  end

  before { Importers::SeedStatements.new.call }

  scenario "Can get to ECF payment breakdown page for a provider" do
    given_i_am_logged_in_as_a_finance_user
    and_multiple_declarations_are_submitted
    and_voided_payable_declarations_are_submitted
    and_breakdowns_are_calculated
    when_i_click_on_payment_breakdown_header
    then_the_page_should_be_accessible
    then_percy_should_be_sent_a_snapshot_named("Payment breakdown select programme")

    when_i_select_ecf
    and_i_click_the_continue_button
    then_the_page_should_be_accessible
    then_percy_should_be_sent_a_snapshot_named("Payment breakdown select ECF provider")

    when_i_select_a_provider
    and_i_click_the_continue_button
    then_i_should_see_correct_breakdown_summary
    then_i_should_see_the_correct_payment_summary
    then_i_should_see_the_correct_output_fees
    then_i_should_see_the_correct_uplift_fee
    and_the_page_should_be_accessible

    when_i_click_on_view_contract_link
    then_i_see_contract_information

    select("November 2021", from: "statement-field")
    click_button("View")
    then_i_should_see_the_total_voided
    click_link("View voided declarations")
    then_i_see_voided_declarations
    and_the_page_should_be_accessible
  end

private

  def then_i_should_see_the_total_voided
    expect(page.find("strong", text: "Total voided")).to have_sibling("div", text: voided_declarations.size)
  end

  def then_i_see_voided_declarations
    within first("table tbody") do
      voided_declarations.each do |participant_declaration|
        declaration_id_cell =  page.find("tr td", text: participant_declaration.id)
        expect(declaration_id_cell).to have_sibling("td", text: participant_declaration.user_id)
        expect(declaration_id_cell).to have_sibling("td", text: participant_declaration.declaration_type)
        expect(declaration_id_cell).to have_sibling("td", text: participant_declaration.course_identifier)
      end
    end
  end

  def multiple_start_declarations_are_submitted_nov_statement
    participant_profiles = create_list(:ect_participant_profile, 4, school_cohort: school_cohort, cohort: contract.cohort, sparsity_uplift: true)
    participant_profiles.map { |participant| ParticipantProfileState.create!(participant_profile: participant) }
    participant_profiles.map { |participant| ECFParticipantEligibility.create!(participant_profile_id: participant.id).eligible_status! }
    participant_profiles.map { |participant| create_start_declarations_nov(participant) }
  end

  def multiple_retained_declarations_are_submitted_nov_statement
    participant_profiles = create_list(:ect_participant_profile, 4, school_cohort: school_cohort, cohort: contract.cohort)
    participant_profiles.map { |participant| ParticipantProfileState.create!(participant_profile: participant) }
    participant_profiles.map { |participant| ECFParticipantEligibility.create!(participant_profile_id: participant.id).eligible_status! }
    participant_profiles.map { |participant| create_retained_declarations_nov(participant) }
  end

  def multiple_ineligible_declarations_are_submitted_jan_statement
    participant_profiles = create_list(:ect_participant_profile, 3, school_cohort: school_cohort, cohort: contract.cohort)
    participant_profiles.map { |participant| ParticipantProfileState.create!(participant_profile: participant) }
    participant_profiles.map { |participant| ECFParticipantEligibility.create!(participant_profile_id: participant.id).eligible_status! }
    participant_profiles.map { |participant| create_ineligible_declarations_jan(participant) }
  end

  def multiple_retained_declarations_are_submitted_jan_statement
    mentor_participant_profiles = create_list(:mentor_participant_profile, 5, school_cohort: school_cohort, cohort: contract.cohort, sparsity_uplift: true)
    mentor_participant_profiles.map { |participant| ParticipantProfileState.create!(participant_profile: participant) }
    mentor_participant_profiles.map { |participant| ECFParticipantEligibility.create!(participant_profile_id: participant.id).eligible_status! }
    mentor_participant_profiles.map { |participant| create_retained_declarations_jan_mentor(participant) }
    participant_profiles = create_list(:ect_participant_profile, 6, school_cohort: school_cohort, cohort: contract.cohort)
    participant_profiles.map { |participant| ParticipantProfileState.create!(participant_profile: participant) }
    participant_profiles.map { |participant| ECFParticipantEligibility.create!(participant_profile_id: participant.id).eligible_status! }
    participant_profiles.map { |participant| create_retained_declarations_jan_ect(participant) }
  end

  def and_multiple_declarations_are_submitted
    multiple_start_declarations_are_submitted_nov_statement
    multiple_retained_declarations_are_submitted_nov_statement
    multiple_retained_declarations_are_submitted_jan_statement
    multiple_ineligible_declarations_are_submitted_jan_statement
  end

  def and_voided_payable_declarations_are_submitted
    voided_declarations
  end

  def create_start_declarations_nov(participant)
    Induction::Enrol.call(participant_profile: participant, induction_programme: induction_programme)

    timestamp = participant.schedule.milestones.first.start_date + 1.day
    travel_to(timestamp) do
      serialized_started_declaration = RecordDeclarations::Started::EarlyCareerTeacher.call(
        params: {
          participant_id: participant.user.id,
          course_identifier: "ecf-induction",
          declaration_date: (participant.schedule.milestones.first.start_date + 1.day).rfc3339,
          created_at: participant.schedule.milestones.first.start_date + 1.day,
          cpd_lead_provider: lead_provider.cpd_lead_provider,
          declaration_type: "started",
          evidence_held: "other",
        },
      )

      started_declaration = ParticipantDeclaration.find(JSON.parse(serialized_started_declaration).dig("data", "id"))
      started_declaration.make_eligible!
      started_declaration.make_payable!
    end
  end

  def create_voided_declarations_nov(participant)
    Induction::Enrol.call(participant_profile: participant, induction_programme: induction_programme)

    timestamp = participant.schedule.milestones.first.start_date + 1.day
    travel_to(timestamp) do
      serialized_started_declaration = RecordDeclarations::Started::EarlyCareerTeacher.call(
        params: {
          participant_id: participant.user.id,
          course_identifier: "ecf-induction",
          declaration_date: (participant.schedule.milestones.first.start_date + 1.day).rfc3339,
          created_at: participant.schedule.milestones.first.start_date + 1.day,
          cpd_lead_provider: lead_provider.cpd_lead_provider,
          declaration_type: "started",
          evidence_held: "other",
        },
      )
      declaration = ParticipantDeclaration.find(JSON.parse(serialized_started_declaration).dig("data", "id"))
      declaration.make_eligible!
      declaration.make_payable!
      declaration.make_voided!

      declaration.statement_line_items.first.update!(statement: nov_statement, state: declaration.state)

      declaration
    end
  end

  def create_retained_declarations_nov(participant)
    Induction::Enrol.call(participant_profile: participant, induction_programme: induction_programme)

    timestamp = participant.schedule.milestones.second.start_date + 1.day
    travel_to(timestamp) do
      serialized_started_declaration = RecordDeclarations::Retained::EarlyCareerTeacher.call(
        params: {
          participant_id: participant.user.id,
          course_identifier: "ecf-induction",
          declaration_date: (participant.schedule.milestones.second.start_date + 1.day).rfc3339,
          created_at: participant.schedule.milestones.second.start_date + 1.day,
          cpd_lead_provider: lead_provider.cpd_lead_provider,
          declaration_type: "retained-1",
          evidence_held: "other",
        },
      )
      started_declaration = ParticipantDeclaration.find(JSON.parse(serialized_started_declaration).dig("data", "id"))
      started_declaration.make_eligible!
      started_declaration.make_payable!
    end
  end

  def create_retained_declarations_jan_mentor(participant)
    Induction::Enrol.call(participant_profile: participant, induction_programme: induction_programme)

    timestamp = participant.schedule.milestones.second.start_date + 1.day
    travel_to(timestamp) do
      serialized_started_declaration = RecordDeclarations::Retained::Mentor.call(
        params: {
          participant_id: participant.user.id,
          course_identifier: "ecf-mentor",
          declaration_date: (participant.schedule.milestones.second.start_date + 1.day).rfc3339,
          created_at: participant.schedule.milestones.second.start_date + 1.day,
          cpd_lead_provider: lead_provider.cpd_lead_provider,
          declaration_type: "retained-1",
          evidence_held: "other",
        },
      )
      retained_declaration = ParticipantDeclaration.find(JSON.parse(serialized_started_declaration).dig("data", "id"))
      retained_declaration.make_eligible!
      retained_declaration.make_payable!
    end
  end

  def create_retained_declarations_jan_ect(participant)
    Induction::Enrol.call(participant_profile: participant, induction_programme: induction_programme)

    timestamp = participant.schedule.milestones.second.start_date + 1.day
    travel_to(timestamp) do
      serialized_started_declaration = RecordDeclarations::Retained::EarlyCareerTeacher.call(
        params: {
          participant_id: participant.user.id,
          course_identifier: "ecf-induction",
          declaration_date: (participant.schedule.milestones.second.start_date + 1.day).rfc3339,
          created_at: participant.schedule.milestones.second.start_date + 1.day,
          cpd_lead_provider: lead_provider.cpd_lead_provider,
          declaration_type: "retained-1",
          evidence_held: "other",
        },
      )
      retained_declaration = ParticipantDeclaration.find(JSON.parse(serialized_started_declaration).dig("data", "id"))
      retained_declaration.make_eligible!
    end
  end

  def create_ineligible_declarations_jan(participant)
    Induction::Enrol.call(participant_profile: participant, induction_programme: induction_programme)

    timestamp = participant.schedule.milestones.first.start_date + 1.day
    travel_to(timestamp) do
      serialized_started_declaration = RecordDeclarations::Started::EarlyCareerTeacher.call(
        params: {
          participant_id: participant.user.id,
          course_identifier: "ecf-induction",
          declaration_date: (participant.schedule.milestones.first.start_date + 1.day).rfc3339,
          created_at: participant.schedule.milestones.first.start_date + 1.day,
          cpd_lead_provider: lead_provider.cpd_lead_provider,
          declaration_type: "started",
          evidence_held: "other",
        },
      )
      declaration = ParticipantDeclaration.find(JSON.parse(serialized_started_declaration).dig("data", "id"))
      declaration.update!(
        state: "ineligible",
      )
      declaration
    end
  end

  def nov_retained_breakdowns_are_calculated
    @nov_retained_1 = Finance::ECF::CalculationOrchestrator.new(
      statement: nov_statement,
      contract: lead_provider.call_off_contract,
      aggregator: participant_aggregator_nov,
      calculator: PaymentCalculator::ECF::PaymentCalculation,
    ).call(event_type: :retained_1)
  end

  def nov_starts_breakdowns_are_calculated
    @nov_starts = Finance::ECF::CalculationOrchestrator.new(
      statement: nov_statement,
      contract: lead_provider.call_off_contract,
      aggregator: participant_aggregator_nov,
      calculator: PaymentCalculator::ECF::PaymentCalculation,
    ).call(event_type: :started)
  end

  def jan_starts_breakdowns_are_calculated
    @jan_starts = Finance::ECF::CalculationOrchestrator.new(
      statement: jan_statement,
      contract: lead_provider.call_off_contract,
      aggregator: participant_aggregator_jan,
      calculator: PaymentCalculator::ECF::PaymentCalculation,
    ).call(event_type: :started)
  end

  def jan_retained_breakdowns_are_calculated
    @jan_retained_1 = Finance::ECF::CalculationOrchestrator.new(
      statement: jan_statement,
      contract: lead_provider.call_off_contract,
      aggregator: participant_aggregator_jan,
      calculator: PaymentCalculator::ECF::PaymentCalculation,
    ).call(event_type: :retained_1)
  end

  def and_breakdowns_are_calculated
    nov_starts_breakdowns_are_calculated
    nov_retained_breakdowns_are_calculated
    jan_starts_breakdowns_are_calculated
    jan_retained_breakdowns_are_calculated
  end

  def then_i_should_see_correct_breakdown_summary
    expect(page).to have_css(".govuk-caption-l", text: lead_provider.name)
    select("January 2022", from: "statement-field")
    click_button("View")

    within ".finance-panel__summary" do
      expect(page).to have_content("Milestone cut off date")
      expect(page).to have_content(jan_statement.deadline_date.to_s(:govuk))
    end
  end

  def then_i_should_see_the_correct_payment_summary
    within ".finance-panel__summary" do
      expect(page).to have_content(number_to_pounds(total_payment_with_vat_breakdown))

      expect(page).to have_content("Output payment")
      expect(page).to have_content(number_with_delimiter(output_payment_total))

      expect(page).to have_content("Service fee")
      expect(page).to have_content(number_to_pounds(service_fee_total))

      expect(page).to have_content("VAT")
      expect(page).to have_content(number_to_pounds(total_vat_breakdown))
    end
  end

  def then_i_should_see_the_correct_output_fees
    all(".finance-panel")[0] do
      expect(page).to have_content("Output payments")
      expect(page).to have_content(number_to_pounds(@jan_starts[:output_payments][0][:per_participant]))
      expect(page).to have_content(@jan_starts[:output_payments][0][:participants])
      expect(page).to have_content(number_to_pounds(@jan_starts[:output_payments][0][:subtotal]))
    end
  end

  def then_i_should_see_the_correct_uplift_fee
    all(".finance-panel")[1] do
      expect(page).to have_content("Uplift fee")
      expect(page).to have_content(number_to_pounds(@jan_starts[:other_fees][:uplift][:per_participant]))
      expect(page).to have_content(@jan_starts[:other_fees][:uplift][:participants])
      expect(page).to have_content(number_to_pounds(@jan_starts[:other_fees][:uplift][:subtotal]))
    end
  end

  def number_of_declarations
    @jan_starts[:output_payments].map { |params| params[:participants] }.inject(&:+) + @jan_retained_1[:output_payments].map { |params| params[:participants] }.inject(&:+)
  end

  def service_fee_total
    @jan_starts[:service_fees].map { |params| params[:monthly] }.inject(&:+)
  end

  def output_payment_total
    @jan_starts[:output_payments].map { |params| params[:subtotal] }.inject(&:+) + @jan_retained_1[:output_payments].map { |params| params[:subtotal] }.inject(&:+)
  end

  def total_vat_breakdown
    total_vat_combined(@jan_starts, @jan_retained_1, lead_provider)
  end

  def total_payment_with_vat_breakdown
    total_payment_with_vat_combined(@jan_starts, @jan_retained_1, lead_provider)
  end

  def total_payment_with_vat_combined(breakdown_started, breakdown_retained_1, lead_provider)
    total_payment_combined(breakdown_started, breakdown_retained_1) + total_vat_combined(breakdown_started, breakdown_retained_1, lead_provider)
  end

  def total_vat_combined(breakdown_started, breakdown_retained_1, lead_provider)
    total_payment_combined(breakdown_started, breakdown_retained_1) * (lead_provider.vat_chargeable ? 0.2 : 0.0)
  end

  def total_payment_combined(breakdown_started, breakdown_retained_1)
    service_fee = breakdown_started[:service_fees].map { |params| params[:monthly] }.sum
    output_payment = breakdown_started[:output_payments].map { |params| params[:subtotal] }.sum
    other_fees = breakdown_started[:other_fees].values.map { |other_fee| other_fee[:subtotal] }.sum
    retained_output_payment = breakdown_retained_1[:output_payments].map { |params| params[:subtotal] }.sum

    service_fee + output_payment + other_fees + retained_output_payment
  end

  def and_there_is_a_schedule
    create(:ecf_schedule)
  end

  def when_i_click_on_payment_breakdown_header
    find("h2", text: "Payment Breakdown").click
  end

  def when_i_select_ecf
    choose option: "ecf", allow_label_click: true
  end

  def when_i_select_a_provider
    choose option: "cffd2237-c368-4044-8451-68e4a4f73369", allow_label_click: true
  end

  def when_i_click_on_view_contract_link
    find("summary", text: I18n.t("finance.contract_information")).click
  end

  def then_i_see_contract_information
    expect(page).to have_content("Recruitment target #{contract.recruitment_target}")
  end
end

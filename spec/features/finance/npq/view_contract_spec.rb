# frozen_string_literal: true

require "rails_helper"

RSpec.feature "NPQ view contract" do
  include FinanceHelper

  scenario "see the contract information for all courses of an NPQ lead provider" do
    given_i_am_logged_in_as_a_finance_user
    and_there_is_an_npq_lead_provider_with_contracts
    when_i_visit_the_payment_breakdown_page
    and_choose_to_see_npq_payment_breakdown
    and_i_select_an_npq_lead_provider
    and_i_click_on_view_contract

    then_i_see_contract_information_for_each_course
  end

  def and_there_is_an_npq_lead_provider_with_contracts
    @npq_lt = create(:npq_contract, :npq_leading_teaching)
    @npq_lead_provider = @npq_lt.npq_lead_provider
    @npq_lbc = create(:npq_contract, :npq_leading_behaviour_culture, npq_lead_provider: @npq_lead_provider)
  end

  def when_i_visit_the_payment_breakdown_page
    click_on "Payment Breakdown"
  end

  def and_choose_to_see_npq_payment_breakdown
    choose "NPQ payments"
    click_on "Continue"
  end

  def and_i_select_an_npq_lead_provider
    choose @npq_lead_provider.name
    click_on "Continue"
  end

  def and_i_click_on_view_contract
    click_on "View contract information"
  end

  def then_i_see_contract_information_for_each_course
    within "#main-content > table > tbody" do
      within "tr:nth-child(1)" do
        expect(page)
          .to have_css("td:nth-child(1)", text: "npq-leading-teaching")
        expect(page)
          .to have_css("td:nth-child(2)", text: @npq_lt.recruitment_target)
        expect(page)
          .to have_css("td:nth-child(3)", text: number_to_pounds(@npq_lt.per_participant))
      end

      within "tr:nth-child(2)" do
        expect(page)
          .to have_css("td:nth-child(1)", text: "npq-leading-behaviour-culture")
        expect(page)
          .to have_css("td:nth-child(2)", text: @npq_lbc.recruitment_target)
        expect(page)
          .to have_css("td:nth-child(3)", text: number_to_pounds(@npq_lbc.per_participant))
      end
    end
  end
end
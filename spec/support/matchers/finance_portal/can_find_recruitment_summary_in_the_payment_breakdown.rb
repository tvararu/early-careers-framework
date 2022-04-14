# frozen_string_literal: true

module Support
  module FindingRecruitmentSummaryInPaymentBreakdown
    extend RSpec::Matchers::DSL

    RSpec::Matchers.define :be_able_to_see_recruitment_summary_for_lead_provider_in_payment_breakdown do |lead_provider_name, num_ects, num_mentors|
      match do |finance_user|
        sign_in_as finance_user

        portal = Pages::FinancePortal.new
        wizard = portal.view_payment_breakdown
        report = wizard.complete lead_provider_name

        @text = page.find("main .breakdown-summary-recruitment").text

        report.can_see_recruitment_summary?(num_ects, num_mentors)

        sign_out

        true
      rescue Capybara::ElementNotFound => e
        @error = e
        false
      end

      failure_message do |_sit|
        return @error unless @error.nil?

        "should #{with_description(@text, lead_provider_name, num_ects, num_mentors)}"
      end

      failure_message_when_negated do |_sit|
        "should not #{with_description(@text, lead_provider_name, num_ects, num_mentors)}"
      end

      description do
        "be able to find the recruitment summary in the payment breakdown for '#{lead_provider_name}' showing #{num_ects} ECTs and #{num_mentors} Mentors"
      end

    private

      def with_description(text, lead_provider_name, num_ects, num_mentors)
        "have been able to find the recruitment summary in the payment breakdown for '#{lead_provider_name}' showing #{num_ects} ECTs and #{num_mentors} Mentors within:\n===\n#{text}\n==="
      end
    end
  end
end
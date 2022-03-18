# frozen_string_literal: true

module Support
  module FindingPaymentSummaryInPaymentBreakdown
    extend RSpec::Matchers::DSL

    RSpec::Matchers.define :be_able_to_see_payment_summary_for_lead_provider_in_payment_breakdown do |lead_provider_name, num_declarations|
      match do |finance_user|
        sign_in_as finance_user
        @error = nil

        portal = Pages::FinancePortal.new
        wizard = portal.view_payment_breakdown
        report = wizard.complete lead_provider_name

        unless report.can_see_payment_summary?(num_declarations)
          @error = page.find("main .breakdown-summary-payment").text
        end

        sign_out

        @error.nil?
      end

      failure_message do |_sit|
        "should #{with_description(@error, lead_provider_name, num_declarations)}"
      end

      failure_message_when_negated do |_sit|
        "should not #{with_description(@error, lead_provider_name, num_declarations)}"
      end

      description do
        "be able to find the payment summary in the payment breakdown for '#{lead_provider_name}' showing #{num_declarations} Training Declarations"
      end

    private

      def with_description(error, lead_provider_name, num_declarations)
        "have been able to find the payment summary in the payment breakdown for '#{lead_provider_name}' showing #{num_declarations} Training Declarations within:\n===\n#{error}\n==="
      end
    end
  end
end

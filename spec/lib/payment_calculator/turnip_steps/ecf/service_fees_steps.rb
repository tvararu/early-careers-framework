# frozen_string_literal: true

module ServiceFeeSteps
  class DummyClass
    include PaymentCalculator::Ecf::Contract::ServiceFeeCalculations
    include PaymentCalculator::Ecf::Contract::OutputPaymentCalculations
  end

  step "I run the calculation" do
    band_a = double("Band Double", per_participant: @band_a)
    contract = double("Contract Double", recruitment_target: @recruitment_target, set_up_fee: @set_up_fee, band_a: band_a)
    @call_off_contract = DummyClass.new({ contract: contract })
    lead_provider = double("Lead Provider", call_off_contract: @call_off_contract)
    calculator = PaymentCalculator::Ecf::PaymentCalculation.new(lead_provider: lead_provider)
    @result = calculator.call
  end
end

RSpec.configure do |config|
  config.include ServiceFeeSteps, ecf: true
end

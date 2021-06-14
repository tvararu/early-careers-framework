# frozen_string_literal: true

require "payment_calculator/ecf/payment_calculation"
require "terminal-table"

include ActiveSupport::NumberHelper

namespace :payment_calculation do
  desc "run payment calculator for a given lead provider"
  task breakdown: :environment do
    logger = Logger.new($stdout)
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end

    begin
      lead_provider = LeadProvider.find(ARGV[1])
    rescue StandardError
      lead_provider = LeadProvider.find_by(name: ARGV[1])
    end

    total_participants = (ARGV[2] || 2000).to_i
    per_participant_in_bands = lead_provider.call_off_contract.bands.each_with_index.map { |b, i| "£#{b.per_participant.to_i} per participant in #{band_name_from_index(i)}" }.join(", ")

    breakdown = PaymentCalculator::Ecf::PaymentCalculation.call(
      {
        lead_provider: lead_provider,
      },
      total_participants: total_participants,
      event_type: :started,
    )

    service_fees = breakdown.dig(:service_fees).each_with_object([]) do |hash, bands|
      bands << [
        band_name_from_index(bands.length),
        "£#{number_to_delimited(hash[:service_fee_per_participant].to_i)}",
        "£#{number_to_delimited(hash[:service_fee_monthly].to_i)}",
      ]
    end
    output_payment = number_to_delimited(breakdown.dig(:output_payment, :started, :subtotal).to_i)

    table = Terminal::Table.new(
      title: "Breakdown Payments",
      headings: ["Banding", "Service fee (PP)", "Service fee (monthly)"],
      rows: service_fees,
    )
    table.style = { alignment: :center }

    output = <<~RESULT
      Output payment (started) £#{output_payment}
      Based on #{number_to_delimited(total_participants.to_i)} participants and #{per_participant_in_bands}
    RESULT

    logger.info table
    logger.info output
  rescue StandardError
    logger.info "Lead provider for '#{ARGV[1]}' not found"
  ensure
    exit(0)
  end
end

def band_name_from_index(index)
  "Band #{('A'..'Z').to_a[index]}"
end
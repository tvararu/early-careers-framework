# frozen_string_literal: true

module Support
  module FindingParticipantStatusInFinancePortal
    extend RSpec::Matchers::DSL

    RSpec::Matchers.define :be_able_to_find_the_status_of_the_participant_in_the_finance_portal do |participant_name, status|
      match do |finance_user|
        sign_in_as finance_user

        user = User.find_by(full_name: participant_name)
        raise "Could not find User for #{participant_name}" if user.nil?

        participant = user.participant_profiles.first
        raise "Could not find ParticipantProfile for #{participant_name}" if participant.nil?

        portal = Pages::FinancePortal.new
        search = portal.view_participant_drilldown
        drilldown = search.find participant_name

        @text = page.find("main").text

        drilldown.can_see_participant?(user.id)
        drilldown.can_see_status?(status)

        sign_out

        true
      rescue Capybara::ElementNotFound => e
        @error = e
        false
      end

      failure_message do |_sit|
        return @error unless @error.nil?

        "the status of '#{status}' for '#{participant_name}' cannot be found within:\n===\n#{@text}\n==="
      end

      failure_message_when_negated do |_sit|
        "the status of '#{status}' for '#{participant_name}' can be found within:\n===\n#{@text}\n==="
      end

      description do
        "be able to find the status of '#{status}' for '#{participant_name}' in the finance portal"
      end
    end
  end
end
# frozen_string_literal: true

module Support
  module FindingParticipantDetailsInSchoolsInductionPortal
    extend RSpec::Matchers::DSL

    RSpec::Matchers.define :find_participant_details_in_school_induction_portal do |participant_name, participant_status, is_being_trained: true|
      match do |sit_name|
        user = User.find_by(full_name: sit_name)
        raise "Could not find User for #{sit_name}" if user.nil?

        sign_in_as user

        induction_dashboard = Pages::SITInductionDashboard.new
        participants_dashboard = induction_dashboard.view_participant_dashboard

        participant_details = if is_being_trained
                                participants_dashboard.view_ects participant_name
                              else
                                participants_dashboard.view_not_training participant_name
                              end

        @text = page.find("main").text

        participant_details.can_see_email? email_for participant_name
        participant_details.can_see_full_name? participant_name
        participant_details.can_see_status? participant_status.to_s unless participant_status.nil?

        sign_out

        true
      rescue Capybara::ElementNotFound => e
        @error = e
        false
      end

      failure_message do |sit_name|
        return @error unless @error.nil?

        "the details of '#{participant_name}' cannot be found by '#{sit_name}' within:\n===\n#{@text}\n==="
      end

      failure_message_when_negated do |sit_name|
        "the details of '#{participant_name}' can be found by '#{sit_name}' within:\n===\n#{@text}\n==="
      end

      description do
        "be able to find the details of '#{participant_name}' in the school induction portal"
      end

    private

      def email_for(participant_name)
        user = User.find_by(full_name: participant_name)
        raise "Could not find User for #{participant_name}" if user.nil?

        user.email.to_s
      end
    end
  end
end

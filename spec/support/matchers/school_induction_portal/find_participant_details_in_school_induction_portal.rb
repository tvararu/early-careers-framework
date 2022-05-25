# frozen_string_literal: true

module Support
  module FindingParticipantDetailsInSchoolsInductionPortal
    extend RSpec::Matchers::DSL

    RSpec::Matchers.define :find_participant_details_in_school_induction_portal do |participant_name, participant_email, participant_type, participant_status, is_being_trained: true|
      match do |sit_name|
        given_i_sign_in_as_the_user_with_the_full_name sit_name

        induction_dashboard = Pages::SchoolDashboardPage.loaded
        participants_dashboard = induction_dashboard.view_participant_details

        if is_being_trained
          case participant_type
          when "ECT"
            participant_details = participants_dashboard.view_ects participant_name
          when "Mentor"
            participant_details = participants_dashboard.view_mentors participant_name
          else
            raise "unknown participant_type of #{participant_type}"
          end
        else
          participant_details = participants_dashboard.view_not_training participant_name
        end

        @text = page.find("main").text

        participant_details.has_full_name? participant_name
        participant_details.has_email? participant_email
        participant_details.has_status? participant_status.to_s unless participant_status.nil?

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
    end
  end
end

# frozen_string_literal: true

module APIs
  class ECFParticipantsEndpoint
    include Capybara::DSL
    include RSpec::Matchers

    attr_reader :response

    def initialize(token, experimental)
      @current_record = nil
      @current_id = nil
      call_participants_endpoint token, experimental
    end

    def get_participant(participant_id)
      @current_id = participant_id
      select_participant

      if @current_record.nil?
        raise Capybara::ElementNotFound, "Unable to find record for \"#{@current_id}\""
      end
    end

    def has_full_name?(expected_value)
      has_attribute_value? "full_name", expected_value
    end

    def has_email?(expected_value)
      has_attribute_value? "email", expected_value
    end

    def has_school_urn?(expected_value)
      has_attribute_value? "school_urn", expected_value
    end

    def has_participant_type?(expected_value)
      has_attribute_value? "participant_type", expected_value
    end

    def has_status?(expected_value)
      has_attribute_value? "status", expected_value
    end

    def has_training_status?(expected_value)
      has_attribute_value? "training_status", expected_value
    end

  private

    def call_participants_endpoint(token, experimental)
      url = experimental ? "/api/v1/test_ecf_participants" : "/api/v1/participants/ecf"
      session = ActionDispatch::Integration::Session.new Rails.application
      session.get url,
                  headers: {
                    "Authorization": "Bearer #{token}",
                  }

      @response = JSON.parse(session.response.body)["data"]
    end

    def select_participant
      @current_record = @response.select { |record| record["id"] == @current_id }.first
    end

    def has_attribute_value?(attribute_name, expected_value)
      if @current_record.nil?
        raise "No record selected, Must call <APIs::ECFParticipantsEndpoint::select_participant> with a valid \"participant_id\" first"
      end

      value = @current_record.dig("attributes", attribute_name)
      if value.nil?
        raise Capybara::ElementNotFound, "Unable to find attribute \"#{attribute_name}\" for \"#{@current_id}\""
      end

      unless value == expected_value.to_s
        raise Capybara::ElementNotFound, "Unable to find attribute \"#{attribute_name}\" for \"#{@current_id}\" with value of \"#{expected_value}\""
      end

      true
    end
  end
end

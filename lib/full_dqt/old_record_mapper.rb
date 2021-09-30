# frozen_string_literal: true

module FullDqt
  # Given a response from new full DQP api
  # map to old format for backwards compatability
  class OldRecordMapper
    def self.translate(response)
      return if response.nil?

      hash = {}

      hash["teacher_reference_number"] = response["trn"]
      hash["national_insurance_number"] = response["ni_number"]
      hash["full_name"] = response["name"]
      hash["date_of_birth"] = response["dob"]
      hash["active_alert"] = response["active_alert"]

      qts_date = response.dig("qualified_teacher_status", "qts_date")

      if qts_date
        hash["qts_date"] = qts_date
      end

      hash.with_indifferent_access
    end
  end
end

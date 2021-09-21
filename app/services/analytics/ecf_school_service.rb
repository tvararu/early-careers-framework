# frozen_string_literal: true

module Analytics
  class ECFSchoolService
    class << self
      def update_school_analytics
        return unless %w[test development production].include? Rails.env

        before_object_count = ObjectSpace.each_object(ActiveRecord::Base).count

        School.eligible_or_cip_only.includes(
          :nomination_emails,
          :induction_coordinators,
          :school_cohorts,
          :partnerships,
          active_partnerships: %i[lead_provider delivery_partner],
        ).find_in_batches do |schools|
          Analytics::ECFSchool.upsert_all(
            schools.map do |school|
              {
                name: school.name,
                urn: school.urn,
                school_type_name: school.school_type_name,
                school_phase_type: school.school_phase_type,
                school_phase_name: school.school_phase_name,
                school_status_code: school.school_status_code,
                school_status_name: school.school_status_name,
                postcode: school.postcode,
                administrative_district_code: school.administrative_district_code,
                administrative_district_name: school.administrative_district_name,
                nomination_email_opened_at: school.nomination_emails.first&.opened_at,
                induction_tutor_nominated: school.induction_tutor.present?,
                tutor_nominated_time: school.induction_tutor&.created_at,
                induction_tutor_signed_in: school.induction_tutor&.current_sign_in_at&.present?,
                induction_programme_choice: school.school_cohorts.first&.induction_programme_choice,
                in_partnership: school.active_partnerships.any?,
                partnership_time: school.active_partnerships.first&.created_at,
                partnership_challenge_reason: school.active_partnerships.any? ? nil : school.partnerships.first&.challenge_reason,
                partnership_challenge_time: school.active_partnerships.any? ? nil : school.partnerships.first&.challenged_at,
                lead_provider: school.active_partnerships.first&.lead_provider&.name,
                delivery_partner: school.active_partnerships.first&.delivery_partner&.name,
                chosen_cip: school.school_cohorts.first&.core_induction_programme&.name,
              }
            end,
            unique_by: :urn,
            returning: false,
          )
        end

        after_object_count = ObjectSpace.each_object(ActiveRecord::Base).count
        Sentry.capture_message("Run analytics. Before object count: #{before_object_count}, after object count: #{after_object_count}")
      end
    end
  end
end
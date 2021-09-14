# frozen_string_literal: true

class ParticipantMailer < ApplicationMailer
  PARTICIPANT_REMOVED_BY_STI = "ab8fb8b1-9f44-4d27-8e80-01d5d70d22f6"

  def participant_added(participant_profile:)
    template_mail(
      "50ee41e5-06b9-41cf-9afd-d5bc4db356c4",
      to: participant_profile.user.email,
      rails_mailer: mailer_name,
      rails_mail_template: action_name,
      personalisation: {
        subject: "We need information for your early career teacher training programme",
        name: participant_profile.user.full_name,
        school_name: participant_profile.school.name,
        participant_start: new_user_session_url,
      },
    )
  end

  def participant_removed_by_sti(participant_profile:, sti_profile:)
    template_mail(
      PARTICIPANT_REMOVED_BY_STI,
      to: participant_profile.user.email,
      rails_mailer: mailer_name,
      rails_mail_template: action_name,
      personalisation: {
        subject: "You have been removed from early career teacher training",
        name: participant_profile.user.full_name,
        school_name: participant_profile.school.name,
        sti_name: sti_profile.user.full_name,
      },
    )
  end

  def add_details_reminder(participant_profile:)
    template_mail(
      "0bf633c3-54c9-4150-b1fb-57748376aed1",
      to: participant_profile.user.email,
      rails_mailer: mailer_name,
      rails_mail_template: action_name,
      personalisation: {
        subject: "Reminder: add information to start your early career teacher training",
        name: participant_profile.user.full_name,
        school_name: participant_profile.school.name,
        participant_start: new_user_session_url,
      },
    )
  end
end

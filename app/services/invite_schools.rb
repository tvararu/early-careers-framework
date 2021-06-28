# frozen_string_literal: true

class InviteSchools
  EMAIL_LIMITS = [
    { max: 5, within: 24.hours },
    { max: 1, within: 5.minutes },
  ].freeze

  def run(school_urns)
    logger.info "Emailing schools"

    school_urns.each do |urn|
      school = find_eligible_school(urn)
      next if school.nil?

      nomination_email = NominationEmail.create_nomination_email(
        sent_at: Time.zone.now,
        sent_to: school.contact_email,
        school: school,
      )

      send_nomination_email(nomination_email)
    rescue Notifications::Client::RateLimitError
      sleep(1)
      send_nomination_email(nomination_email)
    rescue StandardError
      logger.info "Error emailing school, urn: #{urn} ... skipping"
    end
  end

  def reached_limit(school)
    EMAIL_LIMITS.find do |max:, within:|
      NominationEmail.where(school: school, sent_at: within.ago..Float::INFINITY).count >= max
    end
  end

  def send_chasers
    logger.info "Sending chaser emails"
    logger.info "Nomination email count before: #{NominationEmail.count}"
    School.eligible.not_opted_out.without_induction_coordinator.each do |school|
      additional_emails = school.additional_school_emails.pluck(:email_address)
      emails = [school.primary_contact_email, school.secondary_contact_email, *additional_emails]
                 .reject(&:blank?)
                 .map(&:downcase)
                 .uniq

      emails.each do |email|
        delay(queue: "mailers", priority: 1).create_and_send_nomination_email(email, school)
      rescue StandardError
        logger.info "Error emailing school, urn: #{school.urn}, email: #{email} ... skipping"
      end
    end

    logger.info "Chaser emails sent"
  end

  def send_ministerial_letters
    School.eligible.each do |school|
      recipient = school.contact_email
      delay(queue: "mailers", priority: 1).send_ministerial_letter(recipient) if recipient.present?
    end
  end

  def invite_to_beta(school_urns)
    school_urns.each do |urn|
      school = find_eligible_school(urn)
      next if school.nil?

      if FeatureFlag.active?(:induction_tutor_manage_participants, for: school)
        logger.info "School urn: #{urn} already added to beta ... skipping"
        next
      end

      induction_coordinator = school.induction_coordinators.first
      if induction_coordinator.nil?
        logger.info "Induction coordinator not found, urn: #{urn} ... skipping"
        next
      end

      FeatureFlag.activate(:induction_tutor_manage_participants, for: school)
      SchoolMailer.beta_invite_email(
        recipient: induction_coordinator.email,
        name: induction_coordinator.full_name,
        school_name: school.name,
        start_url: private_beta_start_url,
      ).deliver_later
    rescue StandardError
      logger.info "Error emailing school, urn: #{urn} ... skipping"
    end
  end

  def send_beta_chasers
    beta_school_ids = FeatureFlag.new(name: :induction_tutor_manage_participants).feature.selected_objects.pluck(:object_id)
    beta_schools = School.where(id: beta_school_ids)
    beta_schools_without_participants = beta_schools.left_outer_joins(:early_career_teacher_profiles)
                                                    .left_outer_joins(:mentor_profiles)
                                                    .where(
                                                      early_career_teacher_profiles: { id: nil },
                                                      mentor_profiles: { id: nil },
                                                    )

    beta_schools_without_participants.each do |school|
      induction_coordinator = school.induction_coordinators.first
      SchoolMailer.beta_invite_email(
        recipient: induction_coordinator.email,
        name: induction_coordinator.full_name,
        school_name: school.name,
        start_url: private_beta_start_url,
      ).deliver_later
    rescue StandardError
      logger.info "Error emailing school, urn: #{school.urn} ... skipping"
    end
  end

  def invite_mats(school_urns)
    invite_group(school_urns, :send_mat_invite_email)
  end

  def invite_federations(school_urns)
    invite_group(school_urns, :send_federation_invite_email)
  end

private

  def private_beta_start_url
    Rails.application.routes.url_helpers.root_url(
      host: Rails.application.config.domain,
      **UTMService.email(:june_private_beta, :private_beta),
    )
  end

  def find_eligible_school(urn)
    school = School.eligible.find_by(urn: urn)
    logger.info "School not found, urn: #{urn} ... skipping" if school.nil?
    school
  end

  def create_and_send_nomination_email(email, school)
    nomination_email = NominationEmail.create_nomination_email(
      sent_at: Time.zone.now,
      sent_to: email,
      school: school,
    )
    send_nomination_email(nomination_email)
  rescue Notifications::Client::RateLimitError
    sleep(1)
    send_nomination_email(nomination_email)
  end

  def send_nomination_email(nomination_email)
    notify_id = SchoolMailer.nomination_email(
      recipient: nomination_email.sent_to,
      school_name: nomination_email.school.name,
      nomination_url: nomination_email.nomination_url,
      expiry_date: email_expiry_date,
    ).deliver_now.delivery_method.response.id

    nomination_email.update!(notify_id: notify_id)
  end

  def send_ministerial_letter(recipient)
    SchoolMailer.ministerial_letter_email(recipient: recipient).deliver_now
  rescue Notifications::Client::RateLimitError
    sleep(1)
    SchoolMailer.ministerial_letter_email(recipient: recipient).deliver_now
  end

  def email_expiry_date
    NominationEmail::NOMINATION_EXPIRY_TIME.from_now.strftime("%d/%m/%Y")
  end

  def invite_group(school_urns, send_method)
    school_urns.each do |urn|
      school = find_eligible_school(urn)
      next if school.nil?

      if school.contact_email.blank?
        logger.info "No contact details for school urn: #{urn} ... skipping"
        next
      end

      nomination_email = NominationEmail.create_nomination_email(
        sent_at: Time.zone.now,
        sent_to: school.contact_email,
        school: school,
      )

      delay(queue: "mailers", priority: 1).__send__(send_method, nomination_email)
    rescue StandardError
      logger.info "Error emailing school, urn: #{urn} ... skipping"
    end
  end

  def send_mat_invite_email(nomination_email)
    notify_id = SchoolMailer.mat_invite_email(
      recipient: nomination_email.sent_to,
      school_name: nomination_email.school.name,
      nomination_url: nomination_email.nomination_url,
    ).deliver_now.delivery_method.response.id

    nomination_email.update!(notify_id: notify_id)
  end

  def send_federation_invite_email(nomination_email)
    notify_id = SchoolMailer.federation_invite_email(
      recipient: nomination_email.sent_to,
      school_name: nomination_email.school.name,
      nomination_url: nomination_email.nomination_url,
    ).deliver_now.delivery_method.response.id

    nomination_email.update!(notify_id: notify_id)
  end

  def logger
    @logger ||= Rails.logger
  end
end

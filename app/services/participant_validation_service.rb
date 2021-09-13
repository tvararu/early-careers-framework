# frozen_string_literal: true

class ParticipantValidationService
  attr_reader :trn, :nino, :full_name, :date_of_birth, :config

  def self.validate(trn:, full_name:, date_of_birth:, nino: nil, config: {})
    ParticipantValidationService.new(trn: trn, full_name: full_name, date_of_birth: date_of_birth, nino: nino, config: config).validate
  end

  def initialize(trn:, full_name:, date_of_birth:, nino: nil, config: {})
    @trn = trn
    @full_name = full_name
    @date_of_birth = date_of_birth
    @nino = nino
    @config = config
  end

  def validate
    validated_record = matching_record(trn: trn, nino: nino, full_name: full_name, dob: date_of_birth)
    return if validated_record.nil?

    validation_data = {
      trn: validated_record[:teacher_reference_number],
      qts: validated_record[:qts_date].present? && validated_record[:qts_date] != "null",
      active_alert: validated_record[:active_alert],
      previous_participation: false,
      previous_induction: false,
    }

    set_eligibility_flags(validation_data)
  end

private

  def set_eligibility_flags(validation_data)
    ineligibility_flag = CheckParticipantEligibility.call(trn: validation_data[:trn])

    validation_data[ineligibility_flag] = true if ineligibility_flag.present?
    validation_data
  end

  def check_first_name_only?
    config[:check_first_name_only]
  end

  def dqt_record(trn, nino)
    dqt_client.api.dqt_record.show(params: { teacher_reference_number: trn, national_insurance_number: nino })
  end

  def dqt_client
    @dqt_client ||= Dqt::Client.new
  end

  def matching_record(trn:, nino:, full_name:, dob:)
    dqt_record = dqt_record(trn, nino)
    return if dqt_record.nil?

    padded_trn = trn.rjust(7, "0")

    matches = 0
    trn_matches = padded_trn == dqt_record[:teacher_reference_number]
    matches += 1 if trn_matches

    name_matches = if check_first_name_only?
                     full_name.split(" ").first.downcase == dqt_record[:full_name].split(" ").first.downcase
                   else
                     full_name.downcase == dqt_record[:full_name].downcase
                   end

    matches += 1 if name_matches

    dob_matches = dob == dqt_record[:date_of_birth]
    matches += 1 if dob_matches
    nino_matches = nino.present? && nino.downcase == dqt_record[:national_insurance_number]&.downcase
    matches += 1 if nino_matches

    return dqt_record if matches >= 3

    # If a participant mistypes their TRN and enters someone else's, we should search by NINO instead
    # The API first matches by (mandatory) TRN, then by NINO if it finds no results. This works around that.
    if trn_matches && trn != "0"
      matching_record(trn: "0", nino: nino, full_name: full_name, dob: dob)
    end
  end
end

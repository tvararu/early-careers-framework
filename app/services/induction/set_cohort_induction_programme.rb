# frozen_string_literal: true

class Induction::SetCohortInductionProgramme < BaseService
  def call
    ActiveRecord::Base.transaction do
      school_cohort.induction_programme_choice = programme_choice
      school_cohort.opt_out_of_updates = opt_out_of_updates
      # need to save this first if it hasn't been persisted
      school_cohort.save! unless school_cohort.persisted?

      programme = nil

      if InductionProgramme.training_programmes.keys.include? programme_choice
        # NOTE: we could move any participants in the old default programme (if present)
        # over to the new one here but not sure that would always be required?
        programme = InductionProgramme.create!(programme_attrs)
      end

      school_cohort.default_induction_programme = programme
      school_cohort.save!
    end
  end

private

  attr_reader :school_cohort, :programme_choice, :opt_out_of_updates, :core_induction_programme

  def initialize(school_cohort:, programme_choice:, opt_out_of_updates: false, core_induction_programme: nil)
    # NOTE: this is mainly called during addition of a school_cohort and the model may not
    # be persisted as yet
    @school_cohort = school_cohort
    @programme_choice = programme_choice
    @opt_out_of_updates = opt_out_of_updates
    @core_induction_programme = core_induction_programme
  end

  def programme_attrs
    attrs = {
      training_programme: programme_choice,
      school_cohort: school_cohort,
    }

    case programme_choice.to_s
    when "full_induction_programme"
      attrs[:partnership] = school_cohort.school.partnerships.where(cohort: school_cohort.cohort,
                                                                    relationship: false).active.first
    when "core_induction_programme"
      attrs[:core_induction_programme] = core_induction_programme
    end

    attrs
  end
end
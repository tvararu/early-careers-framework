# frozen_string_literal: true

class Schools::BaseController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_school_user
  before_action :set_paper_trail_whodunnit
  after_action :verify_authorized
  after_action :verify_policy_scoped

  layout "school_cohort"

private

  def ensure_school_user
    raise Pundit::NotAuthorizedError, I18n.t(:forbidden) unless current_user.induction_coordinator?

    authorize(active_school, :show?) if active_school.present?
  end

  def active_school
    School.friendly.find(params[:school_id]) if params[:school_id].present?
  end

  def active_cohort
    Cohort.find_by(start_year: params[:cohort_id]) if params[:cohort_id].present?
  end

  def multiple_cohorts?
    FeatureFlag.active?(:multiple_cohorts)
  end

  def set_school_cohort(cohort: active_cohort)
    @cohort = cohort
    @school = active_school
    @school_cohort = policy_scope(SchoolCohort).find_by(cohort: @cohort, school: @school)

    redirect_to schools_choose_programme_path(cohort_id: start_year) unless @school_cohort
  end

  def start_year
    multiple_cohorts? ? Cohort.active_registration_cohort.start_year : Cohort.current.start_year
  end
end

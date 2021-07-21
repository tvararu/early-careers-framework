# frozen_string_literal: true

module Admin
  class ParticipantsController < Admin::BaseController
    skip_after_action :verify_policy_scoped, only: :show
    skip_after_action :verify_authorized, only: :index

    before_action :load_participant, only: :show

    def show; end

    def index
      school_cohort_ids = SchoolCohort.ransack(school_name_or_school_urn_cont: params[:query]).result.pluck(:id)
      query = "%#{(params[:query] || '').downcase}%"
      @participant_profiles = policy_scope(ParticipantProfile).joins(:user)
                                  .where("lower(users.full_name) LIKE ? OR school_cohort_id IN (?)", query, school_cohort_ids)
                                  .order("DATE(users.created_at) asc, users.full_name")
    end

  private

    def load_participant
      @participant_profile = ParticipantProfile.find(params[:id])
      authorize @participant_profile, policy_class: ParticipantProfilePolicy
    end
  end
end

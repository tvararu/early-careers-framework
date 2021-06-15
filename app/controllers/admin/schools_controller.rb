# frozen_string_literal: true

module Admin
  class SchoolsController < Admin::BaseController
    skip_after_action :verify_authorized, only: :index
    skip_after_action :verify_policy_scoped, only: :show

    before_action :load_school, only: :show

    def index
      @query = params[:query]
      @schools = policy_scope(School)
        .includes(:induction_coordinators, :local_authority)
        .order(:name)
        .ransack(name_or_urn_cont: @query).result
        .page(params[:page])
        .per(20)
    end

    def show
      authorize @school
      @induction_coordinator = @school.induction_coordinators&.first
    end

  private

    def load_school
      @school = School.eligible.find(params[:id])
    end
  end
end

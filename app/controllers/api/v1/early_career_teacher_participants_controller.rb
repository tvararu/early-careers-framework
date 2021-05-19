# frozen_string_literal: true

module Api
  module V1
    class EarlyCareerTeacherParticipantsController < Api::ApiController
      include ApiTokenAuthenticatable
      before_action :set_paper_trail_whodunnit

      def create
        return head :not_found unless params[:id]

        user = User.find(params[:id])

        return head :not_modified unless InductParticipant.call(user.early_career_teacher_profile)

        head :no_content
      end
    end
  end
end

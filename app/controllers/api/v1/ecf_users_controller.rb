# frozen_string_literal: true

module Api
  module V1
    class ECFUsersController < Api::ApiController
      include ApiTokenAuthenticatable
      include ApiPagination

      def index
        render json: ECFUserSerializer.new(paginate(users)).serializable_hash.to_json
      end

      def create
        user = User.find_by(email: params[:data][:attributes][:email])

        if user.present?
          user.errors.add(:email, :taken)

          hash = {
            errors: [{
              status: "409",
              title: user.errors.full_messages.join(", "),
            }],
          }

          render json: hash, status: :conflict and return
        end

        user = User.create!(
          email: params[:data][:attributes][:email],
          full_name: params[:data][:attributes][:full_name],
        )

        hash = UserSerializer.new(user).serializable_hash

        render json: hash, status: :created
      end

    private

      def access_scope
        ApiToken.where(private_api_access: true)
      end

      def updated_since
        params.dig(:filter, :updated_since)
      end

      def email
        params.dig(:filter, :email)
      end

      def users
        users = User.where(id: ParticipantProfile::ECF.joins(:teacher_profile).select("teacher_profiles.user_id"))
                    .includes(teacher_profile: {
                      ecf_profile: %i[school_cohort core_induction_programme],
                    })

        if updated_since.present?
          users = users.changed_since(updated_since)
        end

        if email.present?
          users = users.where(email: email)
        end

        users
      end
    end
  end
end

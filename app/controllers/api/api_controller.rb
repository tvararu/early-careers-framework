# frozen_string_literal: true

module Api
  class ApiController < ActionController::API
    include ActionController::MimeResponds
    before_action :remove_charset
    rescue_from ActionController::ParameterMissing, with: :missing_parameter_response
    rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
    rescue_from ActionController::BadRequest, with: :bad_request_response
    rescue_from ActiveRecord::StatementInvalid, with: :bad_request_response
    rescue_from ArgumentError, with: :bad_request_response
    rescue_from ActiveRecord::RecordNotUnique, with: :bad_request_response
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_transition
    rescue_from Api::Errors::InvalidTransitionError, with: :invalid_transition

    def append_info_to_payload(payload)
      super
      payload[:current_user_class] = current_user&.class&.name
      payload[:current_user_id] = current_user.is_a?(String) ? current_user : current_user&.id
    end

  private

    def render_from_service(service, serializer, params: {})
      if service.valid?
        render json: serializer.new(service.call, params:).serializable_hash
      else
        render json: Api::V1::ActiveModelErrorsSerializer.from(service), status: :unprocessable_entity
      end
    end

    def remove_charset
      ActionDispatch::Response.default_charset = nil
    end

    def missing_parameter_response(exception)
      render json: { errors: Api::ParamErrorFactory.new(error: I18n.t(:missing_parameters), params: exception.param).call }, status: :unprocessable_entity
    end

    def unpermitted_parameter_response(exception)
      render json: { errors: Api::ParamErrorFactory.new(error: I18n.t(:unpermitted_parameters), params: exception.params).call }, status: :unprocessable_entity
    end

    def bad_request_response(exception)
      Sentry.capture_exception(exception)
      render json: { errors: Api::ParamErrorFactory.new(error: I18n.t(:bad_request), params: exception.message).call }, status: :bad_request
    end

    def invalid_transition(exception)
      render json: { errors: Api::ParamErrorFactory.new(error: I18n.t(:invalid_transition), params: exception).call }, status: :unprocessable_entity
    end

    def log_schema_validation_results
      errors = SchemaValidator.call(raw_event: request.raw_post)

      if errors.blank?
        Rails.logger.info "Passed schema validation"
      else
        Rails.logger.info "Failed schema validation for #{request.raw_post}"
        Rails.logger.info errors
      end
    rescue StandardError => e
      Rails.logger.info "Error on schema validation, #{e}"
    end
  end
end

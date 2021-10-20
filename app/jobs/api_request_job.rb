# frozen_string_literal: true

class ApiRequestJob
  include ActionController::HttpAuthentication::Token

  def self.perform(request_data, response_data, status_code, created_at)
    new.delay.perform(request_data, response_data, status_code, created_at)
  end

  def perform(request_data, response_data, status_code, created_at)
    request_headers = request_data.fetch(:headers, {})
    token = auth_token(request_headers.delete("HTTP_AUTHORIZATION"))
    cpd_lead_provider = token.is_a?(LeadProviderApiToken) ? token.owner : nil

    response_headers = response_data[:headers]
    response_body = response_data[:body]

    ApiRequest.create!(
      request_path: request_data[:path],
      request_headers: request_headers,
      request_body: request_body(request_data),
      request_method: request_data[:method],
      response_headers: response_headers,
      response_body: response_hash(response_body, status_code),
      status_code: status_code,
      user_description: token&.owner_description,
      cpd_lead_provider: cpd_lead_provider,
      created_at: created_at,
    )
  end

private

  AuthorizationStruct = Struct.new(:authorization)

  def auth_token(auth_header)
    return if auth_header.blank?

    token, _options = token_and_options(AuthorizationStruct.new(auth_header))
    ApiToken.find_by_unhashed_token(token)
  end

  def response_hash(response_body, status)
    return {} unless status > 299
    return {} unless response_body

    JSON.parse(response_body)
  rescue JSON::ParserError
    { body: "#{status} did not respond with JSON" }
  end

  def request_body(request_data)
    if request_data[:method] == "POST"
      return if request_data[:body].blank?

      JSON.parse(request_data[:body])
    else
      request_data[:params]
    end
  rescue JSON::ParserError
    { error: "request data did not contain valid JSON" }
  end
end
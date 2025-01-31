# frozen_string_literal: true

require "jsonapi/serializer/instrumentation"

module Api
  module V3
    module ECF
      class PartnershipSerializer
        include JSONAPI::Serializer
        include JSONAPI::Serializer::Instrumentation

        set_id :id
        set_type :'partnership-confirmation'

        attribute :cohort do |partnership|
          partnership.cohort.start_year
        end

        attribute :urn do |partnership|
          partnership.school&.urn
        end

        attributes :delivery_partner_id

        attribute :delivery_partner_name do |partnership|
          partnership.delivery_partner&.name
        end

        attribute :status do |partnership|
          "active" if partnership.active?
          "challenged" if partnership.challenged?
        end

        attribute :challenged_reason, &:challenge_reason

        attribute :induction_tutor_name do |partnership|
          partnership.school&.induction_tutor&.full_name
        end

        attribute :induction_tutor_email do |partnership|
          partnership.school&.contact_email
        end

        attribute :updated_at do |partnership|
          partnership.updated_at.rfc3339
        end

        attribute :created_at do |partnership|
          partnership.created_at.rfc3339
        end
      end
    end
  end
end

# frozen_string_literal: true

module Finance
  module NPQ
    class ParticipantEligibleAndPayableAggregator < Finance::ParticipantAggregator
      def self.aggregation_types
        {
          started: {
            all: :neither_paid_nor_voided_lead_provider_and_course,
            eligible_or_payable: :eligible_or_payable_for_lead_provider_and_course,
            not_paid: :submitted_for_lead_provider_and_course,
          },
        }
      end

    private

      attr_accessor :cpd_lead_provider, :recorder, :course_identifier

      def initialize(statement:, course_identifier:, recorder: ParticipantDeclaration::NPQ)
        @statement = statement
        @cpd_lead_provider = statement.cpd_lead_provider
        @recorder          = recorder
        @course_identifier = course_identifier
      end

      def aggregate(aggregation_type:, event_type:)
        scope = recorder.public_send(self.class.aggregation_types[event_type][aggregation_type], cpd_lead_provider, course_identifier)
        scope = scope.where(statement_id: statement.id)
        scope.count
      end
    end
  end
end

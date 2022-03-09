# frozen_string_literal: true

module Finance
  module NPQ
    module PaymentOverviews
      class PaymentOverviewTableHeader < BaseComponent
        delegate :recruitment_target, to: :contract

        attr_accessor :contract, :statement, :npq_lead_provider

        def initialize(contract, statement, npq_lead_provider)
          self.contract = contract
          self.statement = statement
          self.npq_lead_provider = npq_lead_provider
        end

        def milestones
          NPQCourse.schedule_for(course).milestones
        end

        def current_trainees
          if statement.current?
            ParticipantDeclaration::NPQ
              .eligible_for_lead_provider(npq_lead_provider)
              .where(statement_id: nil)
              .count
          else
            statement
              .participant_declarations
              .for_course_identifier(contract.course_identifier)
              .paid_payable_or_eligible
              .unique_id
              .count
          end
        end

        def total_not_paid
          if statement.current?
            ParticipantDeclaration::NPQ
              .for_lead_provider(npq_lead_provider)
              .where(statement_id: nil)
              .ineligible
              .unique_id
              .count
          else
            statement
              .participant_declarations
              .for_course_identifier(contract.course_identifier)
              .ineligible
              .unique_id
              .count
          end
        end

        def total_participants_for(milestone)
          participant_per_declaration_type.fetch(milestone.declaration_type, 0)
        end

      private

        def course
          @course ||= NPQCourse.find_by!(identifier: contract.course_identifier)
        end

        def participant_per_declaration_type
          @participant_per_declaration_type ||= statement.participant_declarations
            .for_course_identifier(contract.course_identifier)
            .where.not(state: :voided)
            .group(:declaration_type)
            .count
        end
      end
    end
  end
end

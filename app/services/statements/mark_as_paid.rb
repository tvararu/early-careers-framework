# frozen_string_literal: true

module Statements
  class MarkAsPaid
    def initialize(statement)
      self.statement = statement
    end

    def call
      Finance::Statement.transaction do
        statement
          .participant_declarations
          .payable
          .each(&:make_paid!)

        statement
          .statement_line_items
          .payable
          .each(&:paid!)
      end
    end

  private

    attr_accessor :statement
  end
end

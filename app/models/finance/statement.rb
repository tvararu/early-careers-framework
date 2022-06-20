# frozen_string_literal: true

class Finance::Statement < ApplicationRecord
  include Finance::ECFPaymentsHelper

  self.table_name = "statements"

  belongs_to :cpd_lead_provider
  belongs_to :cohort

  has_many :statement_line_items, class_name: "Finance::StatementLineItem"
  has_many :participant_declarations, through: :statement_line_items

  has_many :billable_statement_line_items,
           -> { where(state: %w[eligible payable paid]) },
           class_name: "Finance::StatementLineItem"

  has_many :billable_participant_declarations,
           class_name: "ParticipantDeclaration",
           through: :billable_statement_line_items,
           source: :participant_declaration

  scope :payable,                   -> { where("deadline_date < DATE(NOW()) AND payment_date >= DATE(NOW())") }
  scope :closed,                    -> { where("payment_date < ?", Date.current) }
  scope :with_future_deadline_date, -> { where("deadline_date >= DATE(NOW())") }
  scope :upto_current,              -> { payable.or(closed) }
  scope :latest,                    -> { order(deadline_date: :asc).last }
  scope :upto,                      ->(statement) { where("deadline_date < ?", statement.deadline_date) }
  scope :output,                    -> { where(output_fee: true) }
  scope :next_output_fee_statements, lambda {
    output
      .where(type: name)
      .order(deadline_date: :asc)
      .where("deadline_date >= ?", Date.current)
  }

  class << self
    def find_by_humanised_name(humanised_name)
      find_by(name: humanised_name.humanize.gsub("-", " "))
    end

    def current
      with_future_deadline_date.order(deadline_date: :asc).first
    end

    def attach(participant_declaration)
      Finance::DeclarationStatementAttacher.new(participant_declaration:).call
    end
  end

  def open?
    true
  end

  def past_deadline_date?
    participant_declarations.any?
  end

  def current?
    payment_date > Time.current && deadline_date > Time.current
  end

  def to_param
    name.downcase.gsub(" ", "-")
  end
end

require "finance/statement/ecf"
require "finance/statement/npq"

# frozen_string_literal: true

require "has_di_parameters"

class ParticipantEventAggregator
  def self.call(*args)
    new(*args).call
  end

  def call
    recorder.send(scope, cpd_lead_provider).count
  end

private

  attr_accessor :cpd_lead_provider, :recorder, :scope

  def initialize(cpd_lead_provider:, recorder: ParticipantDeclaration::ECF, scope: :active_for_lead_provider)
    @cpd_lead_provider = cpd_lead_provider
    @recorder = recorder
    @scope = scope
  end
end

# frozen_string_literal: true

module Admin
  module Schools
    module Cohorts
      class NoEctsInfo < BaseComponent
        def initialize(cohort:)
          @cohort = cohort
        end

      private

        attr_reader :cohort
      end
    end
  end
end
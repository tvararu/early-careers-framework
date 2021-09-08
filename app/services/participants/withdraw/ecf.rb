# frozen_string_literal: true

module Participants
  module Withdraw
    class ECF < ::Participants::Base
      class << self
        def reasons
          %w[
            left-teaching-profession
            moved-school
            mentor-no-longer-being-mentor
            school-left-fip
            career-break
            passed-induction
            other
          ].freeze
        end
      end

      include Participants::ECF
      include ValidateAndChangeState
    end
  end
end

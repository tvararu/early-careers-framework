# frozen_string_literal: true

module ApiDocs
  class OperationComponent < ViewComponent::Base
    include MarkdownHelper
    include ApiDocsHelper

    attr_reader :operation

    def initialize(operation)
      super

      @operation = operation
    end
  end
end
# frozen_string_literal: true

module Admin
  module Gias
    class SchoolLinksController < Admin::BaseController
      before_action { authorize :gias }

      def index
        @closed_schools = school_links_scope.successor.joins(:school).order("schools.urn asc")
        @opened_schools = school_links_scope.predecessor.joins(:school).order("schools.urn asc")
      end

      def show
        @school = school_scope.find_by(urn: params[:id])
      end

    private

      def school_scope
        policy_scope(::School, policy_scope_class: GiasPolicy::Scope)
      end

      def school_links_scope
        policy_scope(::SchoolLink, policy_scope_class: GiasPolicy::Scope)
      end
    end
  end
end

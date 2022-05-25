# frozen_string_literal: true

require_relative "../base_page"

module Pages
  class SchoolParticipantDetailsPage < ::Pages::BasePage
    set_url "/schools/{slug}/cohorts/{cohort}/participants/{participant_id}"
    # this is a hack as the participants name is the page title
    set_primary_heading(/^.*$/)

    def has_participant_name?(participant_name)
      element_has_content? primary_heading, participant_name
    end

    def has_email?(email)
      element_has_content? self, "Email address #{email}"
    end

    def has_full_name?(full_name)
      element_has_content? self, "Name #{full_name}"
    end

    def has_status?(status)
      element_has_content? self, "Status\n#{status}"
    end
  end
end

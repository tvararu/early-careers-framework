# frozen_string_literal: true

require_relative "../base_page"

module Pages
  class SchoolAddParticipantStillCannotFindTheirDetailsPage < ::Pages::BasePage
    set_url "/schools/{slug}/cohorts/{cohort}/participants/{participant_id}/still-cannot-find-their-details"
    set_primary_heading(/\AWe still cannot find (.*)’s record\z/)

    def cant_add_participant
      element_has_content?(self, "This could be because the information does not match their Teaching Regulation Agency (TRA) record")
    end

    def can_view_my_etcs_and_mentors
      click_on "View your ECTs and mentors"

      element_has_content?(self, "Your ECTs and mentors")
    end
  end
end

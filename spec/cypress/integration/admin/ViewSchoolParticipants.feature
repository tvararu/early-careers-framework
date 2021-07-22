Feature: Admin users viewing school participants
  As a DfE Admin 
  I need to oversee the process of school induction tutors adding participant details
  So that I can view which schools have added their participants and

  Background:
    Given I am logged in as an "admin"
    And scenario "admin/school_participants" has been run
    And I am on "admin school participants" page with slug "test-school"
    And feature admin_delete_participants is active

  Scenario: Admin school participants page should list school participants
    Then "page body" should contain "ECT User 1"
    And "page body" should not contain "Unrelated user 1"
    Then the page should be accessible
    And percy should be sent snapshot called "Admin school participants index page"

  Scenario: Admins should be able to click through to individual participants
    When I click on "link" containing "ECT User 1"
    Then I should be on "admin participants participant" page
    And "page title" should contain "ECT User 1"

    # Once there is more participants functionality this should be moved to there
    And the page should be accessible
    And percy should be sent snapshot called "Admin view participant"

    # Move this to ParticipantManagement.feature once the links work
    When I click on "link" containing "Delete participant"
    Then I should be on "admin delete participant" page
    And the page should be accessible
    And percy should be sent snapshot called "Admin delete participant"

    When I click the submit button
    Then "page body" should contain "has been deleted"
    And the page should be accessible
    And percy should be sent snapshot called "Admin delete participant success"

    When I click on "link" containing "View participant listing"
    Then I should be on "admin participants" page
    And "page body" should not contain "ECT User 1"
# frozen_string_literal: true

cohort = Cohort.find_or_create_by!(start_year: 2021, registration_start_date: Date.new(2021, 5, 10), academic_year_start_date: Date.new(2021, 9, 1))

unconfirmed_school = FactoryBot.create(:school, name: "Test Town Primary", slug: "test-town-primary")
FactoryBot.create(:user, :induction_coordinator, email: "confirm-provider@example.com", school_ids: [unconfirmed_school.id])
SchoolCohort.find_or_create_by!(
  cohort:,
  school: unconfirmed_school,
  induction_programme_choice: "full_induction_programme",
)

confirmed_school = FactoryBot.create(:school, name: "Test Town Secondary", slug: "test-town-secondary")
FactoryBot.create(:user, :induction_coordinator, email: "signed-up-provider@example.com", school_ids: [confirmed_school.id])
SchoolCohort.find_or_create_by!(
  cohort:,
  school: confirmed_school,
  induction_programme_choice: "full_induction_programme",
)
delivery_partner = FactoryBot.create(:delivery_partner, name: "Test delivery partner")
lead_provider = FactoryBot.create(:lead_provider, name: "Test lead provider")

FactoryBot.create(
  :partnership,
  school: confirmed_school,
  cohort:,
  delivery_partner:,
  lead_provider:,
  created_at: Date.new(2021, 6, 7),
  challenge_deadline: Date.new(2025, 6, 7),
)

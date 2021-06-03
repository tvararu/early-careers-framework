# frozen_string_literal: true

SchoolDataImporter.new(Rails.logger).delay.run

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.update!(full_name: "Admin User")
  AdminProfile.find_or_create_by!(user: user)
end

User.find_or_create_by!(email: "lead-provider@example.com") do |user|
  user.update!(full_name: "LeadProvider User")
  LeadProviderProfile.find_or_create_by!(user: user, lead_provider: LeadProvider.first)
end

school = School.find_or_create_by!(
  name: "Example school",
  postcode: "BB1 1BB",
  address_line1: "3 Madeup Street",
  primary_contact_email: "school-info@example.com",
  school_status_code: 1,
  school_type_code: 1,
  administrative_district_code: "E123",
  urn: "999999",
)

User.find_or_create_by!(email: "school-leader@example.com") do |user|
  user.update!(full_name: "InductionTutor User")
  InductionCoordinatorProfile.find_or_create_by!(user: user) do |profile|
    profile.update!(schools: [school])
  end
end

User.find_or_create_by!(email: "rp-ect-ambition@example.com") do |user|
  user.update!(full_name: "Joe Bloggs")
  EarlyCareerTeacherProfile.find_or_create_by!(user: user) do |profile|
    profile.update!(school: school, core_induction_programme: CoreInductionProgramme.find_by(name: "Ambition Institute"))
  end
end

User.find_or_create_by!(email: "rp-ect-ucl@example.com") do |user|
  user.update!(full_name: "Dan Smith")
  EarlyCareerTeacherProfile.find_or_create_by!(user: user) do |profile|
    profile.update!(school: school, core_induction_programme: CoreInductionProgramme.find_by(name: "UCL Institute of Education"))
  end
end

# We clear the database on a regular basis, but we want a stable token that E&L can use in its dev environments
# Hashed token with the same unhashed version will be different between dev and deployed dev
# The tokens below have different unhashed version to avoid worrying about clever cryptographic attacks
if Rails.env.deployed_development?
  EngageAndLearnApiToken.find_or_create_by!(hashed_token: "dfce9a34c6f982e8adb4b903f8b6064682e6ad1f7858c41ed8a0a7468abc8896")
  NpqRegistrationApiToken.find_or_create_by!(hashed_token: "1dae3836ed90df4b796eff1f4a4713247ac5bc8a00352ea46eee621d74cd4fcf")
elsif Rails.env.development?
  EngageAndLearnApiToken.find_or_create_by!(hashed_token: "f4a16cd7fc10918fbc7d869d7a83df36059bb98fac7c82502d797b1f1dd73e86")
end

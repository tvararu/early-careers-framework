# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppropriateBody, type: :model do
  it "is valid with name and body type" do
    expect(create(:appropriate_body_local_authority)).to be_valid
    expect(create(:appropriate_body_national_organisation)).to be_valid
    expect(create(:appropriate_body_teaching_school_hub)).to be_valid
  end

  it "has name unique per body type" do
    create(:appropriate_body_local_authority, name: "not unique one")
    not_valid_ab = build(:appropriate_body_local_authority, name: "not unique one")
    expect(not_valid_ab).to_not be_valid
  end
end
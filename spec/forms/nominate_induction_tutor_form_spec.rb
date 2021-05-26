# frozen_string_literal: true

require "rails_helper"

RSpec.describe NominateInductionTutorForm, type: :model do
  let(:nomination_email) { create(:nomination_email) }
  let(:token) { nomination_email.token }
  let(:school) { nomination_email.school }
  let(:name) { Faker::Name.name }
  let(:email) { Faker::Internet.email }

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }
    it { is_expected.to validate_presence_of(:email).with_message("Enter an email") }

    it "validates that the email address is not in use" do
      create(:user, email: email)
      form = NominateInductionTutorForm.new(token: token, full_name: name, email: email)
      expect(form).not_to be_valid
      expect(form.errors[:email].first).to eq("This email address is already in use")
      expect(form.email_already_taken?).to be_truthy
    end
  end

  describe "#school" do
    context "from token accessor" do
      it "returns the correct school" do
        form = NominateInductionTutorForm.new(token: token)

        expect(form.school).to eql school
      end
    end

    context "from school_id accessor" do
      let(:school) { create(:school) }
      it "returns the correct school" do
        form = NominateInductionTutorForm.new(school_id: school.id)

        expect(form.school).to eql school
      end
    end
  end
end

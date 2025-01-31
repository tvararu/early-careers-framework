# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantDeclaration::NPQ, :with_default_schedules, type: :model do
  context "when declarations for a particular course are made" do
    before do
      create_list(:npq_participant_declaration, 20)
    end

    describe "associations" do
      let(:user) { create(:user) }
      subject { described_class.new(user:) }
      it {
        is_expected.to have_many(:outcomes)
          .class_name("ParticipantOutcome::NPQ")
          .with_foreign_key("participant_declaration_id")
      }
    end

    it "returns all records when not scoped" do
      expect(described_class.all.count).to eq(20)
    end

    it "can retrieve by npq courses attached" do
      expect(NPQCourse.identifiers.uniq.map { |course_identifier| described_class.for_course(course_identifier).count }.inject(:+)).to eq(20)
    end
  end
end

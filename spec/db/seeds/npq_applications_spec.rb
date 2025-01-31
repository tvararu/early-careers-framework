# frozen_string_literal: true

load "db/seeds/npq_applications.rb"

RSpec.describe Seeds::NPQApplication do
  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_npq_lead_provider) }

  before do
    create(:npq_course)
    Cohort.next || create(:cohort, :next)
  end

  subject { described_class.new(cpd_lead_provider:) }

  describe "#call" do
    it "persists an NPQ application" do
      expect { subject.call }.to change(NPQApplication, :count).by(1)
    end

    it "attaches a cohort to the application" do
      subject.call

      record = NPQApplication.last
      expect(record.cohort).to be_present
    end
  end
end

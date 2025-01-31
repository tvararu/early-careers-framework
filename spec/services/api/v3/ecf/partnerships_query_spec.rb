# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::ECF::PartnershipsQuery do
  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_lead_provider) }
  let(:lead_provider) { cpd_lead_provider.lead_provider }
  let(:cohort) { Cohort.current || create(:cohort, :current) }
  let!(:partnership) { create(:partnership, cohort:, lead_provider:) }

  let(:params) { {} }

  subject { described_class.new(lead_provider:, params:) }

  describe "#partnerships" do
    let(:another_cohort) { create(:cohort, start_year: "2050") }
    let!(:another_partnership) { create(:partnership, cohort: another_cohort, lead_provider:) }

    it "returns all partnerships" do
      expect(subject.partnerships).to match_array([partnership, another_partnership])
    end

    describe "cohort filter" do
      context "with correct value" do
        let(:params) { { filter: { cohort: "2021" } } }

        it "returns all partnerships for the specific cohort" do
          expect(subject.partnerships).to match_array([partnership])
        end
      end

      context "with multiple values" do
        let(:params) { { filter: { cohort: "2021,2050" } } }

        it "returns all partnerships for the specific cohort" do
          expect(subject.partnerships).to match_array([partnership, another_partnership])
        end
      end

      context "with incorrect value" do
        let(:params) { { filter: { cohort: "2017" } } }

        it "returns no partnerships" do
          expect(subject.partnerships).to be_empty
        end
      end
    end

    describe "updated_since filter" do
      context "with correct value" do
        let!(:another_partnership) { create(:partnership, cohort: another_cohort, lead_provider:, updated_at: 2.days.ago.iso8601) }

        let(:params) { { filter: { updated_since: 1.day.ago.iso8601 } } }

        it "returns all partnerships for the specific cohort" do
          expect(subject.partnerships).to match_array([partnership])
        end
      end
    end

    describe "delivery_partner_id filter" do
      context "with correct value" do
        let!(:another_partnership) { create(:partnership, cohort: another_cohort, lead_provider:, updated_at: 2.days.ago.iso8601) }

        let(:params) { { filter: { delivery_partner_id: partnership.delivery_partner_id } } }

        it "returns all partnerships for the specific delivery partner" do
          expect(subject.partnerships).to match_array([partnership])
        end
      end

      context "with multiple values" do
        let!(:another_partnership) { create(:partnership, cohort: another_cohort, lead_provider:, updated_at: 2.days.ago.iso8601) }

        let(:params) { { filter: { delivery_partner_id: "#{partnership.delivery_partner_id},#{another_partnership.delivery_partner_id}" } } }

        it "returns all partnerships for the specific delivery partner" do
          expect(subject.partnerships).to match_array([partnership, another_partnership])
        end
      end

      context "with incorrect value" do
        let!(:another_partnership) { create(:partnership, cohort: another_cohort, lead_provider:, updated_at: 2.days.ago.iso8601) }

        let(:params) { { filter: { delivery_partner_id: SecureRandom.uuid } } }

        it "returns no partnerships" do
          expect(subject.partnerships).to be_empty
        end
      end
    end
  end
end

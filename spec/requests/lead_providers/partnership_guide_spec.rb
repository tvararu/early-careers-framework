# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lead Provider partnership guide", type: :request do
  describe "GET /lead-providers/partnership-guide" do
    it "should show the Lead Provider partnership guide" do
      get lead_providers_partnership_guide_path

      expect(response).to render_template :rendered_markdown_template
      expect(response.body).to include("We’ve created an online service for training providers")
    end

    it "should explain how to confirm the schools you have recruited" do
      get lead_providers_partnership_guide_path

      expect(response.body).to include("How to confirm the schools you have recruited")
    end

    it "should explain how to check errors and update their CSV" do
      get lead_providers_partnership_guide_path

      expect(response.body).to include("Checking errors and updating your CSV")
    end

    it "should explain what to do when a school reports they have been confirmed incorrectly" do
      get lead_providers_partnership_guide_path

      expect(response.body).to include("When a school reports they have been confirmed incorrectly")
    end

    it "should explain how to check the schools they have recruited" do
      get lead_providers_partnership_guide_path

      expect(response.body).to include("When a school reports they have been confirmed incorrectly")
    end
  end
end
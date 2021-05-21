# frozen_string_literal: true

RSpec.describe SandboxController do
  describe "Based on rails environment routes" do
    context "when it is not sandbox environment" do
      before do
        Rails.env.stub(production?: true)
        Rails.application.reload_routes!
      end

      it "routes GET / to StartController#index" do
        expect(get: "/").to route_to(controller: "start", action: "index")
      end
    end

    context "when it is sandbox environment" do
      before do
        Rails.env.stub(sandbox?: true)
        Rails.application.reload_routes!
      end

      it "routes GET /sandbox to SandboxController#show" do
        expect(get: "/sandbox").to route_to(controller: "sandbox", action: "show")
      end
    end
  end
end

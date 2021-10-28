# frozen_string_literal: true

RSpec.shared_examples "a participant declaration with evidence held service" do
  it_behaves_like "a participant declaration service"

  context "when evidence held is invalid" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(params: given_params.merge(evidence_held: "invalid")) }.to raise_error(ActionController::ParameterMissing)
    end
  end
end
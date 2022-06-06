# frozen_string_literal: true

RSpec.describe LeadProviders::YourSchools::Table, type: :view_component do
  include Pagy::Backend

  let(:items) { 10 }
  let(:partnerships) { Array.new(rand(21..30)) { |i| double "Partnership #{i}" } }
  let(:page) { rand(1..2) }

  component { described_class.new partnerships:, page: }
  request_path "/lead-providers/your-schools"

  stub_component LeadProviders::YourSchools::TableRow

  it "renders table row for each school" do
    expected_partnerships = partnerships.each_slice(items).to_a[page - 1]

    expected_partnerships.each do |partnership|
      expect(rendered).to have_rendered(LeadProviders::YourSchools::TableRow).with(partnership:)
    end

    (partnerships - expected_partnerships).each do |other_page_partnership|
      expect(rendered).not_to have_rendered(LeadProviders::YourSchools::TableRow)
        .with(hash_including(partnership: other_page_partnership))
    end
  end
end

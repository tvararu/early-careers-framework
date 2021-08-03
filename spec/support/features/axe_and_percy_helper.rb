# frozen_string_literal: true

module AxeAndPercyHelper
  def and_the_page_should_be_accessible
    expect(page).to be_axe_clean.according_to :wcag2aa
  end

  def and_percy_should_be_sent_a_snapshot_named(name)
    page.percy_snapshot(name)
  end

  alias_method :then_the_page_should_be_accessible, :and_the_page_should_be_accessible
  alias_method :then_percy_should_be_sent_a_snapshot_named, :and_percy_should_be_sent_a_snapshot_named
end
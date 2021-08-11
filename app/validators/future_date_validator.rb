# frozen_string_literal: true

class FutureDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, I18n.t(:future_declaration_date)) if Time.zone.parse(value) > Time.zone.today
  end
end
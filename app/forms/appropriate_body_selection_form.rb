# frozen_string_literal: true

class AppropriateBodySelectionForm
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment
  include ActiveModel::Serialization

  attr_accessor :body_appointed, :body_type, :body_id

  validates :body_appointed, inclusion: { in: %w[yes no] }, on: :body_appointed
  validates :body_type, presence: true, on: :body_type,
                        inclusion: { in: %w[local_authority national teaching_school_hub unknown] }
  validates :body_id, presence: true, on: :body

  def attributes
    {
      body_appointed:,
      body_type:,
      body_id:,
    }
  end

  def body_appointed_choices
    [
      OpenStruct.new(id: "yes", name: "Yes"),
      OpenStruct.new(id: "no", name: "No"),
    ]
  end

  def body_type_choices
    [
      OpenStruct.new(id: "local_authority", name: "Local authority"),
      OpenStruct.new(id: "national", name: "National organisation"),
      OpenStruct.new(id: "teaching_school_hub", name: "Teaching school hub"),
    ]
  end

  def body_choices
    AppropriateBody.where(body_type:)
  end

  def body_appointed?
    body_appointed == "yes"
  end
end

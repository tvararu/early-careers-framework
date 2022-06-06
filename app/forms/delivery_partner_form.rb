# frozen_string_literal: true

class DeliveryPartnerForm
  include ActiveModel::Model
  include ActiveModel::Serialization

  attr_accessor :name, :lead_provider_ids, :provider_relationship_hashes

  validates :name, presence: { message: I18n.t("errors.name.blank") }, on: %i[name update]
  validate :lead_providers_validation, on: %i[lead_providers update]
  validate :cohorts_validation, on: %i[cohorts update]

  def attributes
    { name: nil, lead_provider_ids: nil, provider_relationship_hashes: nil }
  end

  # TODO: ECF-RP-328
  def self.provider_relationship_value(lead_provider, cohort)
    { "lead_provider_id" => lead_provider.id, "cohort_id" => cohort.id }.to_json
  end

  def self.from_delivery_partner(delivery_partner)
    new(
      name: delivery_partner.name,
      lead_provider_ids: delivery_partner.lead_providers.map(&:id),
      provider_relationship_hashes: delivery_partner.provider_relationships.map do |relationship|
        DeliveryPartnerForm.provider_relationship_value(relationship.lead_provider, relationship.cohort)
      end,
    )
  end

  def available_lead_providers
    LeadProvider.joins(:cohorts).includes(:cohorts).select { |lead_provider| lead_provider.cohorts.any? }
  end

  def chosen_lead_providers
    LeadProvider.where(id: lead_provider_ids).joins(:cohorts).includes(:cohorts)
  end

  def chosen_provider_relationships(delivery_partner = nil)
    filtered_provider_relationships = provider_relationships
                                        &.filter { |relationship_params| lead_provider_ids&.include?(relationship_params["lead_provider_id"]) }
    if delivery_partner.nil?
      filtered_provider_relationships
        &.map { |relationship_params| ProviderRelationship.new(relationship_params) }
    else
      filtered_provider_relationships
        &.map { |relationship_params| ProviderRelationship.find_or_initialize_by(delivery_partner:, **relationship_params) }
    end
  end

  def display_lead_provider_details
    chosen_provider_relationships.group_by(&:lead_provider).map do |lps_to_relationships|
      {
        name: lps_to_relationships.first.name,
        chosen_cohorts: lps_to_relationships.second.map { |relationship| relationship.cohort.display_name }.join(", "),
      }
    end
  end

  def provider_relationships
    provider_relationship_hashes
      &.filter { |hash| hash.present? }
      &.map { |provider_relationship_hash| JSON.parse(provider_relationship_hash) }
  end

  def save!(delivery_partner = nil)
    delivery_partner ||= DeliveryPartner.new
    if valid?(:update)
      ActiveRecord::Base.transaction do
        delivery_partner.name = name
        delivery_partner.provider_relationships.where.not(id: chosen_provider_relationships).discard_all!
        delivery_partner.provider_relationships = chosen_provider_relationships(delivery_partner)
        delivery_partner.save!
      end
    end
  end

  def current_lead_provider_ids
    lead_provider_ids&.filter(&:present?)
  end

  def chosen_provider_relationships_lead_provider_ids
    chosen_provider_relationships.pluck(:lead_provider_id)
  end

private

  def lead_providers_validation
    unless current_lead_provider_ids&.any?
      errors.add(:lead_provider_ids, :blank, message: I18n.t("errors.cohorts.blank"))
    end
  end

  def cohorts_validation
    # Ensure all selected lead providers have at least one selected cohort
    # This is indicated by the presence of a provider relationship for that lead provider
    if (current_lead_provider_ids - chosen_provider_relationships_lead_provider_ids).any?
      errors.add(:provider_relationship_hashes, :blank, message: I18n.t("errors.lead_providers.blank"))
    end
  end
end

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Enable paper trail for all models for HIPAA compliance
  has_paper_trail

  # Common Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where.not(status: 'inactive') if column_names.include?('status') } 
end

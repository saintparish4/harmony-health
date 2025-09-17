class AuditLog < ApplicationRecord
    belongs_to :user
    
    validates :action, :resource_type, :timestamp, presence: true
    
    scope :recent, -> { order(timestamp: :desc) }
    scope :by_user, ->(user) { where(user: user) }
    scope :by_action, ->(action) { where(action: action) }
  end
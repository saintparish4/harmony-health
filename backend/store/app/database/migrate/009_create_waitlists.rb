class CreateWaitlists < ActiveRecord::Migration[8.0]
    def change
      create_table :waitlists, id: :uuid do |t|
        t.references :patient, type: :uuid, null: false, foreign_key: true
        t.references :provider, type: :uuid, null: false, foreign_key: true
        t.references :appointment_type, type: :uuid, null: false, foreign_key: true
        
        # Preferences
        t.date :preferred_date_start
        t.date :preferred_date_end
        t.string :preferred_time_of_day, array: true # ['morning', 'afternoon', 'evening']
        t.integer :priority, default: 0 # Higher = more urgent
        
        # Status tracking
        t.string :status, default: 'active' # active, notified, claimed, expired
        t.datetime :notified_at
        t.datetime :expires_at
        
        # Metadata
        t.text :notes
        t.jsonb :metadata, default: {}
        
        t.timestamps
      end
  
      add_index :waitlists, :status
      add_index :waitlists, [:provider_id, :status]
      add_index :waitlists, :expires_at
    end
  end
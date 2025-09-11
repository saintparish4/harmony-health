class CreateAppointmentTypes < ActiveRecord::Migration[7.0]
    def change
      create_table :appointment_types, id: :uuid do |t|
        t.string :name, null: false
        t.text :description
        t.integer :duration_minutes, null: false
        t.decimal :base_price, precision: 8, scale: 2
        t.string :color, default: '#3498db'
        t.boolean :requires_preparation, default: false
        t.text :preparation_instructions
        t.jsonb :required_forms, default: []
        t.boolean :telemedicine_eligible, default: false
        t.timestamps null: false
      end
  
      add_index :appointment_types, :name
      add_index :appointment_types, :duration_minutes
      add_index :appointment_types, :telemedicine_eligible
    end
  end
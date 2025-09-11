class CreateAppointment < ActiveRecord::Migration[7.0]
    def change
        create_table :appointments, id: :uuid do |t|
            t.references :patient, null: false, foreign_key: true, type: uuid
            t.references :provider, null: false, foreign_key: true, type: uuid
            t.references :appointment_type, null: false, foreign_key: true, type: uuid
            t.datetime :scheduled_at, null: false
            t.datetime :ends_at, null: false
            t.string :status, null: false, default: "requested"
            t.text :reason_for_visit
            t.text :notes
            t.text :provider_notes
            t.boolean :is_telemedicine, default: false
            t.string :telemedicine_link
            t.decimal :copay_amount, precision: 8, scale: 2
            t.string :confirmation_number
            t.datetime :confirmed_at
            t.datetime :completed_at
            t.datetime :cancelled_at
            t.text :cancellation_reason
            t.string :cancelled_by
            t.jsonb :reminder_sent, default: {}
            t.timestamps null: false
        end

        add_index :appointments, :patient_id
        add_index :appointments, :provider_id
        add_index :appointments, :scheduled_at
        add_index :appointments, :status
        add_index :appointments, :confirmation_number, unique: true
        add_index :appointments, [:provider_id, :scheduled_at]
        add_index :appointments, [:patient_id, :status] 
    end
end


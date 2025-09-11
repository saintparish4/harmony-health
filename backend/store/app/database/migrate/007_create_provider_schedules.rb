class CreateProviderSchedules < ActiveRecord::Migration[7.0]
    def change
        create_table :provider_schedules, id: :uuid do |t|
            t.references :provider, null: false, foreign_key: true, type: uuid
            t.date :date, null: false
            t.time :start_time, null: false
            t.time :end_time, null: false
            t.integer :slot_duration_minutes, default: 30
            t.boolean :is_available, default: true
            t.text :notes
            t.timestamps null: false
        end

        add_index :provider_schedules, :provider_id
        add_index :provider_schedules, :date
        add_index :provider_schedules, [:provider_id, :date], unique: true
        add_index :provider_schedules, :is_available
    end
end



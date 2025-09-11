class CreateProviders < ActiveRecord::Migration[7.0]
    def change
        create_table :providers, id: :uuid do |t|
            t.references :user, null: false, foreign_key: true, type: uuid
            t.string :npi_number, null: false
            t.string :license_number, null: false
            t.string :license_state, null: false
            t.jsonb :specialties, null: false, default: []
            t.text :bio
            t.string :practice_name
            t.text :practice_address
            t.string :practice_city
            t.string :practice_state
            t.string :practice_zip
            t.point :practice_location, geographic: true
            t.decimal :rating, precision: 3, scale: 2, default: 0.0
            t.integer :total_reviews, default: 0
            t.jsonb :credentials, default: []
            t.boolean :accepting_new_patients, default: true
            t.jsonb :availability_patterns, default: {}
            t.integer :booking_buffer_minutes, default: 15
            t.timestamps null: false
        end

        add_index :providers, :user_id, unique: true
        add_index :providers, :npi_number, unique: true
        add_index :providers, :specialties, using: :gin
        add_index :providers, :accepted_insurances, using: :gin
        add_index :providers, :practice_location, using: :gist
        add_index :providers, :accepting_new_patients
        add_index :providers, :rating   

    end
end
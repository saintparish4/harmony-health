class CreatePatients < ActiveRecord::Migration[7.0]
    def change
        create_table :patients, id: :uuid do |t|
            t.references :user, null: false, foreign_key: true, type: uuid
            t.date :date_of_birth, null: false
            t.string :gender
            t.text :address
            t.string :city
            t.string :state
            t.string :zip_code
            t.point :location, geographic: true
            t.text :emergency_contact_name
            t.text :emergency_contact_phone
            t.text :medical_history
            t.text :allergies
            t.text :current_medications
            t.string :primary_language, default: "English"
            t.jsonb :preferences, default: {}
            t.timestamps null: false
        end

        add_index :patients, :user_id, unique: true
        add_index :patients, :location, using: :gist
        add_index :patients, :preferences, using: :gin 
    end
end
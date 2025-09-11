class CreateUsers < ActiveRecord::Migration[7.0]
    def change
        create_table :users, id: :uuid do |t|
            t.string :email, null: false, default: ""
            t.string :encrypted_password, null: false, default: ""
            t.string :first_name, null: false
            t.string :last_name, null: false
            t.string :phone_number, null: false
            t.string :role, null: false, default: 0
            t.integer :status, null: false, default: 0
            t.datetime :last_sign_in_at
            t.inet :last_sign_in_ip
            t.datetime :confirmed_at
            t.datetime :confirmation_sent_at
            t.string :confirmation_token
            t.string :reset_password_token
            t.datetime :reset_password_sent_at
            t.timestamps null: false
        end

        add_index :users, :email, unique: true
        add_index :users, :reset_password_token, unique: true
        add_index :users, :confirmation_token, unique: true
        add_index :users, :role
        add_index :users, :status
    end
end


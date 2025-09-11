class CreateInsurancePlans < ActiveRecord::Migration[7.0]
    def change
      create_table :insurance_plans, id: :uuid do |t|
        t.references :patient, null: false, foreign_key: true, type: :uuid
        t.string :insurance_company, null: false
        t.string :plan_name, null: false
        t.string :member_id, null: false
        t.string :group_number
        t.string :plan_type
        t.date :effective_date
        t.date :expiration_date
        t.decimal :copay_primary, precision: 8, scale: 2
        t.decimal :copay_specialist, precision: 8, scale: 2
        t.decimal :deductible, precision: 8, scale: 2
        t.boolean :is_primary, default: true
        t.timestamps null: false
      end
  
      add_index :insurance_plans, :patient_id
      add_index :insurance_plans, :member_id
      add_index :insurance_plans, :insurance_company
      add_index :insurance_plans, :is_primary
    end
  end
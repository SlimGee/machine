class CreateMaliciousDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :malicious_domains do |t|
      t.string :name

      t.timestamps
    end
    add_index :malicious_domains, :name, unique: true
  end
end

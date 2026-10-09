class CreateImpactReports < ActiveRecord::Migration[8.1]
  def change
    create_table :impact_reports do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :query, null: false
      t.jsonb :result_json, null: false, default: {}
      t.datetime :generated_at, null: false

      t.timestamps
    end

    add_index :impact_reports, [ :repository_id, :generated_at ]
    add_index :impact_reports, :query
  end
end

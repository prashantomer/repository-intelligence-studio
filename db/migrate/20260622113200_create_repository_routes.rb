class CreateRepositoryRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :repository_routes do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :http_method, null: false
      t.string :path, null: false
      t.string :controller_name
      t.string :action_name

      t.timestamps
    end

    add_index :repository_routes, [:repository_id, :path]
  end
end

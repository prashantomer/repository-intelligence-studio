class RepositoryRoute < ApplicationRecord
  belongs_to :repository

  validates :http_method, :path, presence: true
end

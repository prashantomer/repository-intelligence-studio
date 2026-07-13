class RepositoryDeletionLogsController < ApplicationController
  def index
    @repository_deletion_logs = current_user.repository_deletion_logs.includes(:user).recent_first.limit(250)
  end
end

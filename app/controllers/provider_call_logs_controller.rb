class ProviderCallLogsController < ApplicationController
  def index
    @repositories = current_user.repositories.recent_first
    @provider_call_logs = filtered_logs.includes(:repository).recent_first.limit(250)
  end

  private

  def filtered_logs
    logs = current_user.provider_call_logs

    logs = logs.where(repository_id: params[:repository_id]) if params[:repository_id].present?
    logs = logs.where(provider: params[:provider]) if params[:provider].present?
    logs = logs.where(operation_type: params[:operation_type]) if params[:operation_type].present?
    logs = logs.where(status: params[:status]) if params[:status].present?

    logs
  end
end

class RepositoriesController < ApplicationController
  before_action :set_repository, only: %i[show edit update resync search assistant ask]

  def index
    @repositories = current_user.repositories.recent_first
  end

  def show
    load_repository_dashboard_data
  end

  def new
    @repository = current_user.repositories.new(default_branch: "main")
  end

  def create
    result = Repositories::CreateService.call(attributes: repository_params, user: current_user)
    @repository = result.success? ? result.data : result.error

    if result.success?
      RepositoryIngestions::StartService.call(repository: @repository)
      redirect_to @repository, notice: "Repository created and initial ingestion queued."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @repository.update(repository_params)
      redirect_to @repository, notice: "Repository settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def resync
    result = RepositoryIngestions::StartService.call(repository: @repository, force: true)
    load_repository_dashboard_data

    respond_to do |format|
      if result.success?
        flash.now[:notice] = "Forced repository re-sync queued."
        format.turbo_stream
        format.html { redirect_to @repository, notice: "Forced repository re-sync queued." }
      else
        flash.now[:alert] = "An ingestion is already active for this repository."
        format.turbo_stream
        format.html { redirect_to @repository, alert: "An ingestion is already active for this repository." }
      end
    end
  end

  def search
    @query = params[:q].to_s.strip
    @results = []
    return if @query.blank?

    result = Retrieval::SemanticSearchService.call(repository: @repository, query: @query)
    if result.success?
      @results = result.data
    else
      flash.now[:alert] = result.error.to_s
    end
  end

  def assistant
    @conversation = @repository.conversations.order(created_at: :desc).first
    @messages = @conversation&.messages&.order(created_at: :asc) || []
  end

  def ask
    conversation = @repository.conversations.find_by(id: params[:conversation_id]) if params[:conversation_id].present?
    result = Assistant::QueueQuestionService.call(
      repository: @repository,
      question: params[:question],
      conversation: conversation
    )

    @conversation = result.success? ? result.data.fetch(:conversation) : conversation
    @messages = @conversation&.messages&.order(created_at: :asc) || []

    respond_to do |format|
      if result.success?
        format.turbo_stream
        format.html { redirect_to assistant_repository_path(@repository), notice: "Assistant response queued." }
      else
        format.turbo_stream do
          flash.now[:alert] = result.error.to_s
          render turbo_stream: turbo_stream.replace("flash-stack", partial: "shared/flash")
        end
        format.html { redirect_to assistant_repository_path(@repository), alert: result.error.to_s }
      end
    end
  end

  private

  def set_repository
    @repository = current_user.repositories.find(params[:id])
  end

  def load_repository_dashboard_data
    @latest_ingestion = @repository.latest_ingestion
    @recent_ingestions = @repository.repository_ingestions.recent_first.limit(5)
    @recent_audit_logs = @repository.audit_logs.order(created_at: :desc).limit(10)
    @code_files_count = @repository.code_files.count
    @code_chunks_count = @repository.code_chunks.count
    @entities_count = @repository.entities.count
    @routes_count = @repository.repository_routes.count
    @relationships_count = @repository.entity_relationships.count
  end

  def repository_params
    params.require(:repository).permit(
      :name,
      :github_url,
      :default_branch,
      :tracked_branch
    )
  end
end

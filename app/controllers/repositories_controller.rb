class RepositoriesController < ApplicationController
  before_action :set_repository, only: %i[show edit update destroy resync search impact assistant ask]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

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

  def destroy
    result = Repositories::DestroyService.call(repository: @repository)

    if result.success?
      redirect_to repositories_path, notice: "Repository deleted permanently."
    else
      redirect_to repositories_path, alert: result.error.to_s
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
    @search_hits = []
    if @query.present?
      result = Retrieval::SemanticSearchService.call(repository: @repository, query: @query)
      if result.success?
        @results = result.data
        @search_hits = build_search_hits(@results, @query)
      else
        flash.now[:alert] = result.error.to_s
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def impact
    load_impact_workspace_data
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

  def handle_record_not_found
    if action_name == "destroy"
      redirect_to repositories_path, alert: "Repository was already removed."
    else
      raise ActiveRecord::RecordNotFound
    end
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
    @dependency_edges_count = @repository.dependency_edges.count
    @dependency_edge_breakdown = @repository.dependency_edges.group(:edge_type).order(Arel.sql("count_all DESC")).limit(5).count
    @recent_impact_reports = ImpactReport.available? ? @repository.impact_reports.recent_first.limit(10) : []
    load_dependency_lookup
  end

  def load_impact_workspace_data
    @recent_impact_reports = ImpactReport.available? ? @repository.impact_reports.recent_first.limit(20) : []
    @impact_query = params[:dependency_entity].to_s.strip
    @dependency_lookup_query = @impact_query

    if @impact_query.present?
      load_dependency_lookup
      @selected_impact_report = @impact_analysis_result&.fetch(:impact_report, nil)
    elsif params[:report_id].present? && ImpactReport.available?
      @selected_impact_report = @repository.impact_reports.find_by(id: params[:report_id])
    else
      @selected_impact_report = @recent_impact_reports.first
    end
  end

  def load_dependency_lookup
    @impact_query = params[:dependency_entity].to_s.strip
    @dependency_lookup_query = @impact_query
    return if @impact_query.blank?

    interpreter_result = Analysis::ImpactQueryInterpreterService.call(repository: @repository, query: @impact_query)
    if interpreter_result.failure?
      @dependency_lookup_error = interpreter_result.error.to_s
      return
    end

    @resolved_impact_query = interpreter_result.data.fetch(:entity_identifier)

    result = DependencyGraph::TraversalQuery.call(repository: @repository, entity_identifier: @resolved_impact_query)

    if result.success?
      @dependency_lookup_result = result.data
      load_impact_analysis
    else
      @dependency_lookup_error = result.error.to_s
    end
  end

  def load_impact_analysis
    result = Analysis::ImpactAnalysisService.call(
      repository: @repository,
      entity_identifier: @resolved_impact_query || @dependency_lookup_query,
      query: @impact_query
    )

    if result.success?
      @impact_analysis_result = result.data
    else
      @impact_analysis_error = result.error.to_s
    end
  end

  def repository_params
    params.require(:repository).permit(
      :name,
      :github_url,
      :default_branch,
      :tracked_branch
    )
  end

  def build_search_hits(chunks, query)
    normalized_query = query.to_s.downcase.strip.sub(/\A`(.+)`\z/, "\\1")
    query_tokens = normalized_query.scan(/[a-z0-9_:-]+/).uniq

    chunks.flat_map do |chunk|
      lines = chunk.chunk_text.to_s.lines.map(&:chomp)
      matches = lines.each_with_index.filter_map do |line, index|
        normalized_line = line.downcase
        next unless normalized_line.include?(normalized_query) || query_tokens.any? { |token| normalized_line.include?(token) }

        {
          chunk:,
          match_line_index: index,
          match_line_number: chunk.start_line.to_i + index,
          score: search_hit_score(normalized_line, normalized_query, query_tokens)
        }
      end

      if matches.any?
        matches
      else
        [{
          chunk:,
          match_line_index: 0,
          match_line_number: chunk.start_line,
          score: 0
        }]
      end
    end.sort_by { |hit| [ -hit[:score], hit[:chunk].code_file.path.to_s, hit[:match_line_number].to_i ] }
  end

  def search_hit_score(normalized_line, normalized_query, query_tokens)
    score = 0
    score += 100 if normalized_line.include?(normalized_query)
    score + query_tokens.sum { |token| normalized_line.include?(token) ? token.length : 0 }
  end
end

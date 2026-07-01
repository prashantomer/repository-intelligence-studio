module ApplicationHelper
  def app_topbar_title
    return "Repositories" if current_page?(repositories_path)
    return "AI Settings" if current_page?(edit_settings_path)
    return "Provider Logs" if current_page?(provider_call_logs_path)
    return "Repository Deletion Logs" if current_page?(repository_deletion_logs_path)
    return "Add Repository" if current_page?(new_repository_path)

    if defined?(@repository) && @repository.present? && current_page?(edit_repository_path(@repository))
      return "Edit Repository"
    end

    return @repository.name if defined?(@repository) && @repository.present?

    "Repositories"
  end

  def app_topbar_eyebrow
    return "Repository Assistant" if defined?(@repository) && @repository.present? && current_page?(assistant_repository_path(@repository))
    return "Semantic Search" if defined?(@repository) && @repository.present? && current_page?(search_repository_path(@repository))
    return "Impact Analyzer" if defined?(@repository) && @repository.present? && current_page?(impact_repository_path(@repository))
    return "Repository Settings" if defined?(@repository) && @repository.present? && current_page?(edit_repository_path(@repository))
    return "Repository Workspace" if defined?(@repository) && @repository.present?
    "Workspace"
  end

  def app_topbar_meta_items
    if defined?(@repository) && @repository.present? && current_page?(impact_repository_path(@repository))
      [
        "Saved reports: #{@recent_impact_reports&.size || 0}",
        "Selected: #{@selected_impact_report&.entity_name || @impact_analysis_result&.dig(:entity)&.name || "None"}"
      ]
    elsif defined?(@repository) && @repository.present? && current_page?(assistant_repository_path(@repository))
      [
        @repository.assistant_provider,
        @repository.assistant_model,
        @conversation&.title || "New conversation"
      ]
    elsif defined?(@repository) && @repository.present? && current_page?(search_repository_path(@repository))
      [
        @repository.embedding_provider,
        @repository.embedding_model,
        "Results: #{@results&.size || 0}"
      ]
    elsif defined?(@repository) && @repository.present?
      [
        @repository.tracked_branch,
        @repository.status.to_s.humanize,
        @repository.provider.to_s
      ]
    else
      [
        current_user.name,
        current_user.assistant_provider.to_s.humanize,
        current_user.embedding_provider.to_s.humanize
      ]
    end
  end

  def app_topbar_actions
    actions = []

    if current_page?(repositories_path)
      actions << link_to("Add Repository", new_repository_path, class: "button button-primary")
    elsif defined?(@repository) && @repository.present? && current_page?(repository_path(@repository))
      actions << button_tag("Ingestion History", type: :button, class: "button button-secondary", data: { modal_open: "repository-ingestion-history-modal" })
      actions << button_tag("Audit Log", type: :button, class: "button button-secondary", data: { modal_open: "repository-audit-log-modal" })
      actions << link_to("Edit Repo Config", edit_repository_path(@repository), class: "button button-secondary")
      actions << button_to("Re-sync", resync_repository_path(@repository), method: :post, class: "button button-primary")
      actions << button_to("Delete Repository",
                           repository_path(@repository),
                           method: :delete,
                           class: "button button-danger",
                           form: {
                             data: {
                               turbo_confirm: "Delete this repository permanently? This removes ingestions, files, chunks, entities, chats, reports, provider logs, audit history, and temp workspaces."
                             }
                           })
    elsif defined?(@repository) && @repository.present? && current_page?(impact_repository_path(@repository))
      actions << button_tag("Help", type: :button, class: "button button-secondary", data: { modal_open: "impact-help-modal" })
      actions << button_tag("History", type: :button, class: "button button-secondary", data: { modal_open: "impact-history-modal" })
    end

    actions
  end

  def render_assistant_message(content)
    lines = content.to_s.gsub("\r\n", "\n").lines
    nodes = []
    paragraph_lines = []
    list_items = []
    list_type = nil
    blockquote_lines = []
    code_lines = []

    flush_paragraph = lambda do
      next if paragraph_lines.empty?

      nodes << content_tag(:p, inline_format(paragraph_lines.join(" ")).html_safe)
      paragraph_lines = []
    end

    flush_list = lambda do
      next if list_items.empty?

      items = list_items.map { |item| content_tag(:li, inline_format(item).html_safe) }
      nodes << content_tag(list_type, safe_join(items))
      list_items = []
      list_type = nil
    end

    flush_blockquote = lambda do
      next if blockquote_lines.empty?

      nodes << content_tag(:blockquote, inline_format(blockquote_lines.join(" ")).html_safe)
      blockquote_lines = []
    end

    flush_code = lambda do
      next if code_lines.empty?

      nodes << content_tag(:pre) { content_tag(:code, ERB::Util.html_escape(code_lines.join("\n"))) }
      code_lines = []
    end

    lines.each do |raw_line|
      line = raw_line.chomp
      stripped = line.strip

      if code_lines.any?
        if stripped.start_with?("```")
          flush_code.call
        else
          code_lines << line
        end
        next
      end

      if stripped.blank?
        flush_paragraph.call
        flush_list.call
        flush_blockquote.call
        next
      end

      if stripped.start_with?("```")
        flush_paragraph.call
        flush_list.call
        flush_blockquote.call
        next
      end

      if (heading_match = stripped.match(/\A(#+)\s+(.+)\z/))
        flush_paragraph.call
        flush_list.call
        flush_blockquote.call
        level = [ heading_match[1].length, 4 ].min
        nodes << content_tag(:"h#{level}", inline_format(heading_match[2]).html_safe)
        next
      end

      if (ordered_match = stripped.match(/\A\d+\.\s+(.+)\z/))
        flush_paragraph.call
        flush_blockquote.call
        if list_type.present? && list_type != :ol
          flush_list.call
        end
        list_type = :ol
        list_items << ordered_match[1]
        next
      end

      if (unordered_match = stripped.match(/\A[-*]\s+(.+)\z/))
        flush_paragraph.call
        flush_blockquote.call
        if list_type.present? && list_type != :ul
          flush_list.call
        end
        list_type = :ul
        list_items << unordered_match[1]
        next
      end

      if (blockquote_match = stripped.match(/\A>\s?(.*)\z/))
        flush_paragraph.call
        flush_list.call
        blockquote_lines << blockquote_match[1]
        next
      end

      flush_list.call
      flush_blockquote.call
      paragraph_lines << stripped
    end

    flush_paragraph.call
    flush_list.call
    flush_blockquote.call
    flush_code.call

    safe_join(nodes)
  end

  def assistant_model_catalog_json
    AiModelCatalog::ASSISTANT_MODELS.to_json
  end

  def embedding_model_catalog_json
    AiModelCatalog::EMBEDDING_MODELS.to_json
  end

  def repository_question_samples(repository)
    repo_name = repository.name.to_s.presence || "this repository"

    [
      "How is #{repo_name} structured at a high level?",
      "Which files are the main entry points in this repository?",
      "What are the most important modules, services, or packages here?",
      "If I change a core workflow in #{repo_name}, what areas should I review?"
    ]
  end

  def impact_input_examples(repository)
    existing = repository.entities.order(:entity_type, :name).limit(5).pluck(:name).uniq
    if existing.any?
      templates = [
        "What breaks if %<name>s changes?",
        "Which files depend on %<name>s?",
        "What APIs use %<name>s?",
        "Show me all routes that touch %<name>s",
        "What jobs depend on %<name>s?"
      ]

      return existing.first(5).each_with_index.map do |name, index|
        format(templates[index % templates.length], name: name)
      end
    end

    [
      "What breaks if OrderService changes?",
      "Which files depend on CheckoutFlow?",
      "What APIs use payment_worker?",
      "Show me all routes that touch UserSerializer",
      "What jobs depend on AppController?"
    ]
  end

  private

  def inline_format(text)
    escaped = ERB::Util.html_escape(text.to_s)
    with_links = escaped.gsub(/\[([^\]]+)\]\(([^)]+)\)/) do
      label = Regexp.last_match(1)
      href = Regexp.last_match(2)

      if href.start_with?("http://", "https://")
        %(<a href="#{ERB::Util.html_escape(href)}" target="_blank" rel="noopener noreferrer">#{label}</a>)
      else
        label
      end
    end
    with_code = with_links.gsub(/`([^`]+)`/, '<code>\1</code>')
    with_code.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
  end
end

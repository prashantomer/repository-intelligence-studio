module ApplicationHelper
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
    return existing if existing.any?

    %w[OrderService CheckoutFlow payment_worker UserSerializer AppController]
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

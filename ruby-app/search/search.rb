# frozen_string_literal: true

module SearchHelpers
  # FIX 3: Extracted shared search logic into a helper to avoid duplication
  # between the HTML route (GET /) and the API route (GET /api/search).
  # FIX 1: Added Postgres/SQLite fallback so tests running against SQLite don't crash.
  # FIX 2: ORDER BY uses expressions directly instead of aliases, so the order
  #         is not lost when .select() later drops the appended rank columns.
  def apply_search_filters(dataset, query, language)
    lang_map = { 'en' => 'english', 'da' => 'danish' }
    pg_language = lang_map[language] || 'english'

    rank_title = Sequel.case({ true => 2 }, 0, Sequel.function(:lower, :title) => query.downcase)

    if DB.database_type == :postgres
      ts_query = Sequel.function(:plainto_tsquery, pg_language, query)
      rank_fts = Sequel.function(:ts_rank, :search_vector, ts_query)
      dataset = dataset.where(Sequel.lit('search_vector @@ ?', ts_query))
      dataset = dataset.select_append(rank_title.as(:rank_title), rank_fts.as(:rank_fts))
      dataset = dataset.order(Sequel.desc(rank_title), Sequel.desc(rank_fts))
    else
      like_query = "%#{query.downcase}%"
      title_match = Sequel.function(:lower, :title).like(like_query)
      content_match = Sequel.function(:lower, :content).like(like_query)
      dataset = dataset.where(Sequel.|(title_match, content_match))
      dataset = dataset.select_append(rank_title.as(:rank_title))
      dataset = dataset.order(Sequel.desc(rank_title))
    end

    dataset
  end

  def language_label_for(query)
    return 'unknown' if query.to_s.strip.empty?

    query.to_s.ascii_only? ? 'latin' : 'non_latin'
  end
end

Sequel.migration do
  up do
    alter_table(:pages) do
      add_column :search_vector, :tsvector
    end

    run <<~SQL
      UPDATE pages
      SET search_vector = to_tsvector('english', coalesce(title, '') || ' ' || coalesce(content, ''));
    SQL

    run <<~SQL
      CREATE INDEX idx_pages_search ON pages USING GIN(search_vector);
    SQL

    run <<~SQL
      CREATE OR REPLACE FUNCTION pages_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector := to_tsvector('english', coalesce(NEW.title, '') || ' ' || coalesce(NEW.content, ''));
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER trg_pages_search_vector
        BEFORE INSERT OR UPDATE ON pages
        FOR EACH ROW
        EXECUTE FUNCTION pages_search_vector_update();
    SQL
  end

  down do
    run 'DROP TRIGGER IF EXISTS trg_pages_search_vector ON pages;'
    run 'DROP FUNCTION IF EXISTS pages_search_vector_update();'
    alter_table(:pages) { drop_column :search_vector }
  end
end

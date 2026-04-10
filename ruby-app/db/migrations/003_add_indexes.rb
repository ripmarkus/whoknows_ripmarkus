Sequel.migration do
  up do
    add_index :pages, %i[language title], name: :idx_pages_language_title
  end

  down do
    drop_index :pages, nil, name: :idx_pages_language_title
  end
end

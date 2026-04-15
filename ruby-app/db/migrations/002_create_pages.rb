require 'sequel'

Sequel.migration do
  up do
    create_table(:pages) do
      String :title, primary_key: true
      String :url,      null: false, unique: true
      String :language, null: false, default: 'en'
      constraint(:language_check) { Sequel.lit("language IN ('en', 'da')") }
      DateTime :last_updated
      String :content, null: false, text: true
    end
  end

  down { drop_table(:pages) }
end

require 'sequel'

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
Sequel.extension :migration
Sequel::Migrator.run(DB, File.join(__dir__, 'migrations'))
puts 'Migrations complete.'

Sequel.migration do
  up do
    alter_table(:users) do
      add_column :password_reset_required, TrueClass, null: false, default: true
    end
    from(:users).update(password_reset_required: true)
  end

  down do
    alter_table(:users) do
      drop_column :password_reset_required
    end
  end
end

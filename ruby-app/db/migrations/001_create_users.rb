Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String :username, null: false, unique: true
      String :email,    null: false, unique: true
      String :password, null: false
    end
    from(:users).insert(
      username: 'admin',
      email: 'keamonk1@stud.kea.dk',
      password: '5f4dcc3b5aa765d61d8327deb882cf99'
    )
  end

  down { drop_table(:users) }
end

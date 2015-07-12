Sequel.migration do
  change do
    create_table(:baby_names) do
      primary_key :id
      String :name
      TrueClass :boy
      index [:boy, :name]
    end
    
    create_table(:baby_lists) do
      primary_key :id
      String :name
      TrueClass :boys
      index :name
    end
    
    create_table(:baby_ratings) do
      primary_key :id
      foreign_key :baby_name_id, :baby_names
      foreign_key :baby_list_id, :baby_lists
      Fixnum :rating
      Fixnum :count
      index [:baby_list_id, :rating]
    end
  end
end
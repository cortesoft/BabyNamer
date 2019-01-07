Sequel.migration do
  change do
    create_table(:baby_names) do
      primary_key :id
      String :name
      TrueClass :boy
      index [:boy, :name]
    end
    
    create_table(:users) do
      primary_key :id
      String :email
      String :hashed_password
      TrueClass :active
    end
  
    create_table(:baby_lists) do
      primary_key :id
      foreign_key :user_id, :users
      String :name
      TrueClass :boys
      TrueClass :cloneable
      index :name
      index :user_id
    end
    
    create_table(:baby_lists_users) do
      foreign_key :user_id, :users
      foreign_key :baby_list_id, :baby_lists
    end
  
    create_table(:baby_ratings) do
      primary_key :id
      foreign_key :baby_name_id, :baby_names
      foreign_key :baby_list_id, :baby_lists
      Fixnum :rating, :default => 1500
      Fixnum :count, :default => 0
      index [:baby_list_id, :rating]
    end

    create_table(:votes) do
      primary_key :id
      foreign_key :baby_list_id, :baby_lists
      foreign_key :name_1_id, :baby_names
      foreign_key :name_2_id, :baby_names
      foreign_key :user_id, :users
      Fixnum :chosen_name
      index [:user_id, :baby_list_id, :name_1_id, :name_2_id]
    end
  end
end
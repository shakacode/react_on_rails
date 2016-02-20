require 'active_record'

# Required to use the column support
module Rails
  def self.env
    {}
  end
end

# Establish connection to in-memory SQLite DB
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

# Create the users table
ActiveRecord::Migration.verbose = false
ActiveRecord::Migration.create_table :users do |t|
  t.string :name
  t.integer :rank
  t.boolean :admin
  t.datetime :created_at
end

# Create models
class User < ActiveRecord::Base; end
class SubUser < User; end


# Helper methods
# ##############

# we only work with ActiveRecord 2+
def is_usable_activerecord?
  defined?(ActiveRecord::VERSION::MAJOR) && ActiveRecord::VERSION::MAJOR >= 2
end


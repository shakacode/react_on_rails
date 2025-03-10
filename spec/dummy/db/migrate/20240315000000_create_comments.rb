# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.belongs_to :post, foreign_key: true
      t.belongs_to :user, foreign_key: true
      t.text :body

      t.timestamps
    end
  end
end

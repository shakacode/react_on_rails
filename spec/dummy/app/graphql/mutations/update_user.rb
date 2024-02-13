# frozen_string_literal: true

module Mutations
  class UpdateUser < BaseMutation
    # Return Type
    field :user, Types::UserType, null: false

    # Arguments
    argument :user_id, ID, required: true
    argument :new_name, String, required: true

    def resolve(user_id:, new_name:)
      user = User.find(user_id)
      user.update!(name: new_name)
      { user: user }
    end
  end
end

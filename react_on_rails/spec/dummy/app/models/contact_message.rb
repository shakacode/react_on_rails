# frozen_string_literal: true

# Plain ActiveModel (no database) backing the useRailsForm dummy example.
# Validations live here — the React form does not duplicate them client side;
# it renders whatever per-field errors the 422 response carries.
class ContactMessage
  include ActiveModel::Model

  attr_accessor :name, :email, :message

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :message, presence: true, length: { minimum: 10, allow_blank: true }
end

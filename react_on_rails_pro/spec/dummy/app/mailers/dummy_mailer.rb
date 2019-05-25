# frozen_string_literal: true

class DummyMailer < ActionMailer::Base
  add_template_helper(ReactOnRailsHelper)
  default from: "nobody@nope.com"

  def hello_email
    mail(to: "otherperson@nope.com", subject: "you've got mail")
  end
end

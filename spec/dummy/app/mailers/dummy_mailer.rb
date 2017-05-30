class DummyMailer < ActionMailer::Base
  add_template_helper(ReactOnRailsHelper)
  default from: "nobody@nope.com"

  def main_page_email
    mail(to: "otherperson@nope.com", subject: "you've got mail")
  end
end

class Notifier < ActionMailer::Base
  default from: "somewhere@something.edu"

  def send_link_checker_report(report_file_path)
    @message = "wooooo"
    attachments['report_file'] = File.read(report_file_path)
    mail(to: 'henry_neels@wgbh.org', subject: 'Link Checka', from: 'nobody@wgbh.org', template_name: 'link_checker_report')
  end
end
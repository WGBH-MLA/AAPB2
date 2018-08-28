class AAPBMailer < ActionMailer::Base
  def send_link_checker_report(report_file_path)
    attachments['report_file'] = File.read(report_file_path)
    mail(to: 'henry_neels@wgbh.org', subject: 'Link Checka', from: 'nobody@wgbh.org', template_name: 'link_checker_report')
  end
end
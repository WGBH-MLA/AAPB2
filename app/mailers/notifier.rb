class Notifier < ActionMailer::Base
  default from: "jason_corum@wgbh.org"

  def send_link_checker_report(report_file_path)
    @message = "wooooo"
    attachments['report_file'] = File.read(report_file_path)
    mail(to: 'henry_neels@wgbh.org', subject: 'Link Checka', template_name: 'link_checker_report')
  end


  def send_link_checker_clear
    @message = "No bad links were detected."
    mail(to: 'henry_neels@wgbh.org', subject: 'Link Checka', template_name: 'link_checker_report')
  end
  
end
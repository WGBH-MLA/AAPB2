class Notifier < ActionMailer::Base
  default from: "jason_corum@wgbh.org"

  def send_link_checker_report(report_file_path, num_links)
    @today = Time.now.strftime('%m.%d.%Y')
    @message = %(#{num_links} bad links were detected.)
    report_name = %(LC-Report-#{@today}.csv)
    attachments[report_name] = File.read(report_file_path)
    mail(to: 'henry_neels@wgbh.org', subject: %(Link Checker Report (#{@today})), template_name: 'link_checker_report')
  end

  def send_link_checker_clear
    @today = Time.now.strftime('%m.%d.%Y')
    @message = "No bad links were detected."
    mail(to: 'henry_neels@wgbh.org', subject: %(Link Checker Report (#{@today})), template_name: 'link_checker_report')
  end
  
end
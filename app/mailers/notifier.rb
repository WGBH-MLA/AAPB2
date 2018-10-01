class Notifier < ActionMailer::Base
  default from: 'aapb_notifications@wgbh.org'

  def link_checker_report
    @today = Time.now.strftime('%m.%d.%Y')
    filename = "link_checker_result_#{Time.now.strftime('%m.%d.%Y')}.csv"

    found_file = File.exist?(filename)

    if found_file
      num_links = CSV.read(Rails.root + filename).length
      @message = %(#{num_links} bad links were detected.)
      report_name = %(LC-Report-#{@today}.csv)
      attachments[report_name] = File.read(report_file_path)
    else
      @message = 'No bad links were detected.'
    end

    mail(to: 'henry_neels@wgbh.org', subject: %(Link Checker Report (#{@today})), template_name: 'link_checker_report')
    deliver
    File.delete(filename) if found_file
  end
end

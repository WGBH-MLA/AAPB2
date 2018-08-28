module ApplicationHelper

  # linkchecker fails
  $lc_fails = {}

  def current_page(path)
    return 'current-page' if current_page?(path)
  end

  class AAPBMailer < ActionMailer::Base

    def send_link_checker_report(report_file)
      attachments['report_file'] = report_file
      mail(to: 'henry_neels@wgbh.org', subject: 'Link Checka', from: 'nobody@wgbh.org', template_name: 'link_checker_report')
    end
  end
end

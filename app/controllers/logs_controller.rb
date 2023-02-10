require_relative '../../lib/solr'

class LogsController < ApplicationController
  def index
    if !log_file_index_html.empty?
      render html: log_file_index_html.html_safe
    else
      render plain: no_log_files_found_msg
    end
  end

  def show
    if !log_exists?
      render(status: :not_found, plain: "Log file '#{log_file_name}' not found")
    elsif !log_accessible?
      render(status: :forbidden, plain: "Log file '#{log_file_name}' is inaccessible") unless log_file_names.include?(log_file_name)
    elsif log_file_text.empty?
      render plain: "(Log file '#{log_file_name}' is empty)"
    else
      render html: "<pre>#{log_file_text}</pre>".html_safe
    end
  end

  private

  def log_exists?
    log_file_path && File.exist?(log_file_path)
  end

  def log_accessible?
    log_exists? && !ignored?(log_file_name)
  end

  def log_file_index_html
    log_file_names.map do |log_file|
      "<a href='/logs/#{log_file}'>#{log_file}</a>"
    end.join("\n<br>\n")
  end

  def log_file_text
    File.read(log_file_path)
  end

  def log_file_path
    "#{log_dir}/#{log_file_name}"
  end

  def log_file_name
    params[:log_file_name]
  end

  # Delegate a bunch of class-level methods to the instance for convenience of
  # not having to call `self.class` when invoking them.
  delegate :log_file_names, :ignored?, :ignored_log_files, :ignore, :log_dir,
           :no_log_files_found_msg, to: :class

  class << self
    # Add writer methods for configurable attributes.
    attr_writer :ignore, :log_dir

    def log_file_names
      Dir.chdir(log_dir) do
        Dir.glob("**/*")
      end.reject do |filename|
        ignored? filename
      end.sort
    end

    # Accessor for list of files and/or glob patterns to ignore, defaulting to a
    # list of Rails logs for test, development, and production environments.
    # @return [Array<string>]
    def ignore
      @ignore ||= ['test.log*', 'development.log*', 'production.log*']
    end

    def ignored?(filename)
      ignored_log_files.detect { |ignored_file| ignored_file == filename }
    end

    def ignored_log_files
      Dir.chdir(log_dir) do
        ignore.map { |glob| Dir.glob(glob) }.flatten.uniq
      end
    end

    def log_dir
      @log_dir ||= './log'
    end

    def no_log_files_found_msg
      "No accessible log files were found."
    end
  end
end

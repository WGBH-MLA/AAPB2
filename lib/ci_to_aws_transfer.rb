require_relative './rails_stub'
require_relative './solr'
require_relative '../app/models/pb_core_presenter'
require 'aws-sdk'
require 'open-uri'
require 'fileutils'

class CiToAWSTransfer
  attr_reader :solr_docs, :ci, :aws_client, :path

  def initialize(query:nil)
    raise 'query cannot be nil' if query.nil?
    @solr_docs = Solr.instance.connect.get('select', params: { fq: query.to_s, rows: 5_000 })['response']['docs']
    @ci = SonyCiBasic.new(credentials_path: Rails.root + 'config/ci.yml')
    @aws_client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
    @path = "tmp/downloads/#{DateTime.now.strftime('%F')}_sony_ci_downloads"
  end

  def run!
    mkdir_and_cd
    records_to_download.each do |record|
      download_from_ci(record)
    end
    upload_files_to_aws
    delete_download_dir
  end

  private

  def mkdir_and_cd
    Dir.chdir(Rails.root)
    FileUtils.mkdir_p(@path)
    Dir.chdir(@path)
  end

  def delete_download_dir
    Dir.chdir(Rails.root)
    FileUtils.rm_rf(@path)
  end

  def records_to_download
    records = []
    solr_docs.each do |doc|
      pbc = PBCorePresenter.new(doc['xml'])
      records << { id: pbc.id, media_type: pbc.media_type, ci_ids: pbc.ci_ids.uniq }
    end
    records
  end

  def download_from_ci(record)
    iteration = 1
    record[:ci_ids].each do |id|
      filename = record[:media_type] == "Moving Image" ? "#{record[:id]}-#{iteration}.mp4" : "#{record[:id]}-#{iteration}.mp3"
      FileUtils.mv open(ci.download(id)), filename
    end
  rescue => e
    msg = e.class.to_s
    msg += ": #{e.message}" unless e.message.empty?
    puts "Error downloading media file from Sony Ci '#{record[:id]}'. #{msg}"
  end

  def upload_files_to_aws
    files = Dir[Rails.root.to_path + '/' + path + '/*']
    files.each do |file|
      upload_file_to_s3(file)
    end
  end

  def upload_file_to_s3(file)
    s3 = Aws::S3::Resource.new(client: aws_client)
    s3.bucket('americanarchive.org').object(path.split('/').last + '/' + file.split('/')[-1]).upload_file(file)
  rescue => e
    msg = e.class.to_s
    msg += ": #{e.message}" unless e.message.empty?
    puts "Error uploading media file to S3 '#{file}'. #{msg}"
  end
end

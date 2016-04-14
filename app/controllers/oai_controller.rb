class OaiController < ApplicationController
  Record = Struct.new(:id, :date, :pbcore)
  ROWS = 100

  def index
    @verb = params.delete(:verb)
    raise("Unsupported verb: #{@verb}") unless @verb == 'ListRecords'

    @metadata_prefix = params.delete(:metadataPrefix) || 'mods'
    raise("Unsupported metadataPrefix: #{@metadata_prefix}") unless @metadata_prefix == 'mods'

    resumption_token = params.delete(:resumptionToken) || '0'
    raise("Unsupported resumptionToken: #{resumption_token}") unless resumption_token =~ /^\d*$/
    start = resumption_token.to_i

    unsupported = params.keys - %w(action controller format)
    raise("Unsupported params: #{unsupported}") unless unsupported.empty?

    @response_date = Time.now.strftime('%FT%T')

    @records =
      RSolr.connect(url: 'http://localhost:8983/solr/')
           .get('select', params: {
                  'q' => 'access_types:"' + PBCore::PUBLIC_ACCESS + '"',
                  'fl' => 'id,timestamp,xml',
                  'rows' => ROWS,
                  'start' => start
                })['response']['docs'].map do |d|
        Record.new(
          d['id'],
          d['timestamp'],
          PBCore.new(d['xml'])
        )
      end

    # Not ideal: they'll need to go past the end.
    @next_resumption_token = start + ROWS unless @records.empty?

    respond_to do |format|
      format.xml do
        render
      end
    end
  end
end

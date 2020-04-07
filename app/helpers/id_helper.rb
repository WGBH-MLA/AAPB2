module IdHelper
  def normalize_guid(guid)
    guid.gsub(/cpb-aacip./, 'cpb-aacip-')
  end

  def id_styles(guid)
    guidstem = guid.gsub(/cpb-aacip./, '')
    ['cpb-aacip-','cpb-aacip_','cpb-aacip/'].map {|style| style + guidstem }
  end

  def find_from_all_id_styles(guid)
    id_styles(guid).each do |style|
      begin
        puts style
        resp, docs = fetch(style)
        return [resp, docs] if resp && docs
      rescue Blacklight::Exceptions::RecordNotFound => e
        nil
      end
    end
  end
end
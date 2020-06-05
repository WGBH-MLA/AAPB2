module IdHelper
  def normalize_guid(guid)
    guid.gsub(/cpb-aacip./, 'cpb-aacip-')
  end

  def id_styles(guid)
    guidstem = guid.gsub(/cpb-aacip./, '')
    ['cpb-aacip-', 'cpb-aacip_', 'cpb-aacip/'].map { |style| style + guidstem }
  end
end

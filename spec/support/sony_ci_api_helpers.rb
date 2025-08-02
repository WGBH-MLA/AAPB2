require 'sony_ci_api'

# This module provides helper methods for interacting with the Sony Ci API
# Use it in specs that need to test interactions with the Sony Ci API.
# Usage example:
#   require 'sony_ci_api_helpers'
#
#   before do
#     result = sony_ci.upload('path/to/file.txt', 'text/plain')
#     raise 'Sony Ci Failed to upload to test workspace' unless result['assetId']
#     @asset_id = result['assetId']
#   end
#
#   after do
#     # Clean up the asset created in the test workspace, otherwise we'll accumulate a lot of cruft
#     sony_ci.delete(@asset_id) if @asset_id
#   end
#
#   it 'can now test the sony ci api in a test workspace only' do
#     expect(sony_ci.workspace['name']).to eq 'My Workspace'
#     # Show that the asset was uploaded.
#     exepct(sony_ci.asset(@asset_id)['id']).to eq @asset_id
#   end
module SonyCiApiHelpers
  # Default config path is config/ci.yml
  CONFIG_PATH = Rails.root.join('config', 'ci.yml').freeze

  # IMPORTANT! This is the workspace ID for the workspace named "My Workspace" for the Sony Ci API user.
  # Always use the "My Workspace" workspace for tests.
  TEST_SONY_CI_WORKSPACE_ID = "f44132c2393d470c88b9884f45877ebb".freeze

  # Returns an instance of Sony Ci set to the test workspace.
  # Raises an error via ensure_test_workspace! if the workspace is not set or
  # does not match the expected test workspace.
  def sony_ci
    @sony_ci ||= SonyCiApi::Client.new(sony_ci_config)
    ensure_test_workspace!
    @sony_ci
  end

  def sony_ci_config
    YAML.safe_load(File.read(CONFIG_PATH)).with_indifferent_access
  end

  # Raises an error if we're not dealing with test workspace.
  # Returns true if nothing is raised
  def ensure_test_workspace!
    # Ensure we are using the test workspace
    if @sony_ci.nil?
      raise "Sony Ci client is not initialized. Please call sony_ci before using this method."
    elsif @sony_ci.workspace.nil?
      raise "No workspace found for workspace_id '#{@sony_ci.workspace_id}'"
    elsif @sony_ci.workspace['id'] != TEST_SONY_CI_WORKSPACE_ID
      raise "Expected workspace ID '#{TEST_SONY_CI_WORKSPACE_ID}', but got '#{@sony_ci.workspace['id']}'"
    elsif @sony_ci.workspace['name'] != 'My Workspace'
      raise "Expected workspace name 'My Workspace', but got '#{@sony_ci.workspace['name']}'"
    end

    true
  end

  # Simple pbcore factory method for returning test pbcore record for a given
  # AAPB ID and Sony Ci ID
  def pbcore_xml_with_sony_ci_id(aapb_id, sony_ci_id)
    <<-PBCORE_TEST_XML
      <pbcoreDescriptionDocument xsi:schemaLocation='http://www.pbcore.org/PBCore/PBCoreNamespace.html http://www.pbcore.org/xsd/pbcore-2.0.xsd' xmlns='http://www.pbcore.org/PBCore/PBCoreNamespace.html' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
        <pbcoreAssetType>Program</pbcoreAssetType>
        <pbcoreIdentifier source='Sony Ci'>#{sony_ci_id}</pbcoreIdentifier>
        <pbcoreIdentifier source='http://americanarchiveinventory.org'>#{aapb_id}</pbcoreIdentifier>
        <pbcoreTitle titleType='Program'>Test Program Title</pbcoreTitle>
        <pbcoreDescription descriptionType='Program'>Test Program Description</pbcoreDescription>
        <pbcoreInstantiation>
          <instantiationIdentifier source="filename">#{aapb_id}.mp4</instantiationIdentifier>
          <instantiationDigital>video/mp4</instantiationDigital>
          <instantiationStandard>QuickTime</instantiationStandard>
          <instantiationLocation>test instantiation location</instantiationLocation>
          <instantiationMediaType>Moving Image</instantiationMediaType>
        </pbcoreInstantiation>
        <pbcoreAnnotation annotationType='Level of User Access'>Online Reading Room</pbcoreAnnotation>
      </pbcoreDescriptionDocument>
    PBCORE_TEST_XML
  end
end

# Include it in the RSpec configuration so it can be used in specs that reau
RSpec.configure do |c|
  c.include SonyCiApiHelpers
end

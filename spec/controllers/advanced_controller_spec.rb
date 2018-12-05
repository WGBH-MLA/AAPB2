require 'rails_helper'

describe AdvancedController do
  describe 'redirection' do
    assertions = [
      [{ all: 'all of these' }, '+all +of +these'],
      [{ title: 'some title' }, '+titles:"some title"'],
      # rubocop:disable LineLength
      [{ exact: 'exactly these' }, '+(captions_unstemmed:"exactly these" OR text_unstemmed:"exactly these" OR titles_unstemmed:"exactly these" OR contribs_unstemmed:"exactly these" OR title_unstemmed:"exactly these" OR contributing_organizations_unstemmed:"exactly these" OR producing_organizations_unstemmed:"exactly these" OR genres_unstemmed:"exactly these" OR topics_unstemmed:"exactly these") '],
      # rubocop:enable LineLength
      [{ any: 'any of these' }, 'any OR of OR these'],
      [{ none: 'none of these' }, '-none -of -these'],
      # rubocop:disable LineLength
      [{ all: 'all', title: 'title', exact: 'exact', any: 'any', none: 'none' }, '+(captions_unstemmed:"exact" OR text_unstemmed:"exact" OR titles_unstemmed:"exact" OR contribs_unstemmed:"exact" OR title_unstemmed:"exact" OR contributing_organizations_unstemmed:"exact" OR producing_organizations_unstemmed:"exact" OR genres_unstemmed:"exact" OR topics_unstemmed:"exact") +all +titles:"title" any -none']
      # rubocop:enable LineLength
    ]
    assertions.each do |params, query|
      it "handles #{params}" do
        # Form submission from browser will include all fields.
        post 'create', { all: '', title: '', exact: '', any: '', none: '' }.merge(params)
        expect(CGI.unescape(response.redirect_url.split('=')[1])).to eq(query)
      end
    end
  end
end

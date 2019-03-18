require 'rails_helper'

describe AdvancedController do
  describe 'redirection' do
    assertions = [
      [{ all: 'all of these' }, '+all +of +these'],
      [{ title: 'some title' }, '+titles:"some title"'],
      # rubocop:disable LineLength
      [{ exact: 'exactly these' }, '"exactly these"'],
      # rubocop:enable LineLength
      [{ any: 'any of these' }, 'any OR of OR these'],
      [{ none: 'none of these' }, '-none -of -these'],
      # rubocop:disable LineLength
      [{ all: 'all', title: 'title', exact: 'exact', any: 'any', none: 'none' }, '+all +titles:"title" any -none "exact"']
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

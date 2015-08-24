require 'rails_helper'
describe AdvancedController do
  describe 'redirection' do
    assertions = [
      [{ all: 'all of these' }, 'all%20of%20these'],
      [{ title: 'some title' }, 'titles:%22some%20title%22'],
      [{ exact: 'exactly these' }, '%22exactly%20these%22'],
      [{ any: 'any of these' }, '(any%20OR%20of%20OR%20these)'],
      [{ none: 'none of these' }, '-none%20-of%20-these'],
      [{ all: 'all', title: 'title', exact: 'exact', any: 'any', none: 'none' },
       'all%20titles:%22title%22%20%22exact%22%20(any)%20-none']
    ]
    assertions.each do |params, encoded|
      it "handles #{params}" do
        post 'create', params
        expect(response).to redirect_to(
          "/catalog?q=#{encoded}"
        )
      end
    end
  end
end

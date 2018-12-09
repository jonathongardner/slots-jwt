# frozen_string_literal: true

module Slots
  module Tests
    def authorized_get(current_user, url, params: {}, headers: {})
      get url, params: params, headers: headers.merge(token_header(current_user.create_token))
    end
    def authorized_post(current_user, url, params: {}, headers: {})
      post url, params: params, headers: headers.merge(token_header(current_user.create_token))
    end
    def authorized_patch(current_user, url, params: {}, headers: {})
      patch url, params: params, headers: headers.merge(token_header(current_user.create_token))
    end
    def authorized_put(current_user, url, params: {}, headers: {})
      put url, params: params, headers: headers.merge(token_header(current_user.create_token))
    end
    def authorized_delete(current_user, url, params: {}, headers: {})
      delete url, params: params, headers: headers.merge(token_header(current_user.create_token))
    end

    def token_header(token)
      {'authorization' => %{Bearer token="#{token}"}}
    end
  end
end

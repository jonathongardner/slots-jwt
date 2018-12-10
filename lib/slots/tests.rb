# frozen_string_literal: true

module Slots
  module Tests
    def authorized_get(current_user, url, params: {}, headers: {})
      authorized_protocal :get, current_user, url, params: params, headers: headers
    end
    def authorized_post(current_user, url, params: {}, headers: {})
      authorized_protocal :post, current_user, url, params: params, headers: headers
    end
    def authorized_patch(current_user, url, params: {}, headers: {})
      authorized_protocal :patch, current_user, url, params: params, headers: headers
    end
    def authorized_put(current_user, url, params: {}, headers: {})
      authorized_protocal :put, current_user, url, params: params, headers: headers
    end
    def authorized_delete(current_user, url, params: {}, headers: {})
      authorized_protocal :delete, current_user, url, params: params, headers: headers
    end

    def authorized_protocal(type, current_user, url, params: {}, headers: {}, session: false)
      @token = current_user.create_token(session)
      send(type, url, params: params, headers: headers.merge(token_header(@token)))
    end

    def current_token
      @token
    end

    def token_header(token)
      {'authorization' => %{Bearer token="#{token}"}}
    end
  end
end

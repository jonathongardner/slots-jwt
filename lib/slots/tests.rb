# frozen_string_literal: true

module Slots
  module Tests
    def authorized_get(current_user, url, headers: {}, **options)
      authorized_protocal :get, current_user, url, headers: headers, **options
    end
    def authorized_post(current_user, url, headers: {}, **options)
      authorized_protocal :post, current_user, url, headers: headers, **options
    end
    def authorized_patch(current_user, url, headers: {}, **options)
      authorized_protocal :patch, current_user, url, headers: headers, **options
    end
    def authorized_put(current_user, url, headers: {}, **options)
      authorized_protocal :put, current_user, url, headers: headers, **options
    end
    def authorized_delete(current_user, url, headers: {}, **options)
      authorized_protocal :delete, current_user, url, headers: headers, **options
    end

    def authorized_protocal(type, current_user, url, headers: {}, session: false, **options)
      @token = current_user&.create_token(session)
      headers = headers.merge(token_header(@token)) if @token
      send(type, url, headers: headers, **options)
    end

    def current_token
      @token
    end

    def token_header(token)
      {'authorization' => %{Bearer token="#{token}"}}
    end
  end
end

require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/json'

# Doc placeholder
module ZimbraRestApi
  class App < Sinatra::Base
    helpers Sinatra::Cookies, ZimbraRestApi::Helpers

    RESOURCES = %w(domain account distribution_list)

    before do
      ZimbraRestApi.authenticate!
    end

    configure :production, :development do
      enable :logging
      enable :session
    end

    RESOURCES.each do |resource|
      # Index route
      get "/#{resource}s/?" do
        resource_index(resource, params)
      end

      # Show route
      get "/#{resource}s/:id/?" do
        resource_show(resource, params['id'])
      end

      # Create route
      post "/#{resource}s/?" do
        resource_create(resource, params)
      end

      # Update route
      put "/#{resource}s/:id/?" do
        resource_update(resource, params[:id], request.params)
      end

      # Delete route
      delete "/#{resource}s/:id/?" do
        resource_delete(resource, params[:id])
      end

      # Add grants
      post "/#{resource}s/:id/grants/add/?" do
        resource_add_grant(resource, params[:id], request.params)
      end

      # Revoke grants
      post "/#{resource}s/:id/grants/revoke/?" do
        resource_revoke_grant(resource, params[:id], request.params)
      end

    end

    # Domains nested routes

    # Domain count_accounts
    get '/domains/:id/count_accounts' do
      domain = Domain.find(params['id'])
      json domain.count_accounts
    end

    # Domain accounts
    get '/domains/:id/accounts' do
      domain = Domain.find(params['id'])
      accounts = Account.all(domain: domain.name)
      json accounts
    end

    # Domain Distribution Lists
    get '/domains/:id/distribution_lists' do
      domain = Domain.find(params['id'])
      distribution_lists = DistributionList.all(domain: domain.name)
      json distribution_lists
    end

    run! if app_file == $PROGRAM_NAME
  end
end

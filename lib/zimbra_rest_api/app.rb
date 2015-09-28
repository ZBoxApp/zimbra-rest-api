require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/json'
require 'logger'

# Doc placeholder
module ZimbraRestApi
  class App < Sinatra::Base
    helpers Sinatra::Cookies, ZimbraRestApi::Helpers

    RESOURCES = %w(domain account distribution_list cos)

    before do
      if ZimbraRestApi.api_id
        error 401 unless env['HTTP_X_API_TOKEN'] == ZimbraRestApi.api_id
      end
      ZimbraRestApi.authenticate!
    end

    configure :production, :development do
      enable :logging
      enable :session
    end

    RESOURCES.each do |resource|
      # Index route
      get "/#{resource.plural}/?" do
        resource_index(resource, params)
      end

      # Show route
      get "/#{resource.plural}/:id/?" do
        resource_show(resource, params['id'])
      end

      # Create route
      post "/#{resource.plural}/?" do
        resource_create(resource, params)
      end

      # Update route
      put "/#{resource.plural}/:id/?" do
        resource_update(resource, params[:id], request.params)
      end

      # Delete route
      delete "/#{resource.plural}/:id/?" do
        resource_delete(resource, params[:id])
      end

      # Add grants
      post "/#{resource.plural}/:id/grants/add/?" do
        resource_add_grant(resource, params[:id], request.params)
      end

      # Revoke grants
      post "/#{resource.plural}/:id/grants/revoke/?" do
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
      query = request.params.merge({ domain: domain.name })
      distribution_lists = DistributionList.all(query)
      json distribution_lists
    end

    run! if app_file == $PROGRAM_NAME
  end
end

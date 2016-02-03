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

      # Count route
      get "/#{resource.plural}/count" do
        resource_count(resource, request.params)
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
      # We need the id, so we lookup the domain if we do not get an UUID
      if UUID.validate(params['id'])
        json Domain.count_accounts(params['id'])
      else
        domain = Domain.find(params['id'])
        json domain.count_accounts
      end
    end

    # Domain accounts
    get '/domains/:id/accounts' do
      # Only lookup domain if id is an UUID
      domain = params['id']
      domain = Domain.find(params['id']) if UUID.validate(params['id'])
      query = request.params.merge(domain: domain.to_s)
      resource_index('account', query)
    end

    # Domain Distribution Lists
    get '/domains/:id/distribution_lists' do
      # Only lookup domain if id is an UUID
      domain = params['id']
      domain = Domain.find(params['id']) if UUID.validate(params['id'])
      query = request.params.merge(domain: domain.to_s)
      resource_index('distribution_list', query)
    end

    # Accounts custom routes
    # Account mailbox info
    get '/accounts/:id/mailbox' do
      # We need the id, so we lookup the account if we do not get an UUID
      if UUID.validate(params['id'])
        json Account.mailbox(params['id'])
      else
        account = Account.find(params['id'])
        json account.mailbox
      end
    end

    post '/accounts/:id/add_alias' do
      account = Account.find(params['id'])
      alias_name = request.params['alias_name']
      if account.add_alias(alias_name)
        json alias_name: alias_name
      else
        json errors: ["Alias not added for #{account.name}"]
      end
    end

    post '/accounts/:id/remove_alias' do
      account = Account.find(params['id'])
      alias_name = request.params['alias_name']
      if account.remove_alias(alias_name)
        json alias_name: alias_name
      else
        json errors: ["Alias no removed for #{account.name}"]
      end
    end

    get '/accounts/:id/delegated_token' do
      account = Account.find(params['id'])
      token = account.delegated_auth_token
      json delegated_token: token
    end

    # DistributionList

    # add_members
    post '/distribution_lists/:id/add_members' do
      dl = DistributionList.find params['id']
      members = request.params['members']
      begin
        json DistributionList.new(dl.add_members members)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    # add_members
    post '/distribution_lists/:id/remove_members' do
      dl = DistributionList.find params['id']
      members = request.params['members']
      begin
        json DistributionList.new(dl.remove_members members)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    run! if app_file == $PROGRAM_NAME
  end
end

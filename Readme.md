# ZimbraRestApi

This is a [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) Proxy to the
[Zimbra SOAP API](https://wiki.zimbra.com/wiki/SOAP_API_Reference_Material_Beginning_with_ZCS_8). In
other words it make possible to do this:

```bash
$ curl 'http://localhost:9292/accounts/?domain=itlinux.cl' | jq '[.[] | { email: .name, name: .zimbra_attrs.givenName, lastname: .zimbra_attrs.sn, aliases: .zimbra_attrs.zimbraMailAlias}] '

```

**Note**: The example use `jq`, [a command-line JSON processor](https://stedolan.github.io/jq/)

You get as result something like this:

```json
{
    "email": "jpugenin@itlinux.cl",
    "name": "Juan",
    "lastname": "Pugenin",
    "aliases": [
      "juan@itlinux.cl",
      "j.pugenin@itlinux.cl",
    ]
  },
  {
    "email": "krriagada@itlinux.cl",
    "name": "Karen",
    "lastname": "Riagada",
    "aliases": [
      "karen@itlinux.cl",
      "karen@zboxapp.com",
    ]
  },

```

# Documentation

Only tested with Ruby **version 2 or greater**

## Standalone Installation

Just clone the repo and run bundle

```bash
$ git clone https://github.com/ZBoxApp/zimbra-rest-api.git
$ cd zimbra-rest-api
$ bundle
```

## Usage

### Enviroment Variables

This Gem expects the following ENV Variables to work properly:

* `zimbra_soap_url`: 'https://ZIMBRA_SERVER:7071/service/admin/soap',
* `zimbra_admin_user`: Admin user email to use,
* `zimbra_admin_password`: The password of the admin user

The following are optional, and you can past a list separated by ','

* `zimbra_account_attrs`: Account attributes to load when doing a search
* `zimbra_domain_attrs`: Domain attributes to load when doing a search
* `zimbra_dl_attrs`: DistributionList attributes to load when doing a search

### Running the server

This example export the ENV variables and then run the server

```bash
$ export zimbra_soap_url=https://127.0.0.1:7071/service/admin/soap
$ export zimbra_admin_user=admin@zboxapp.dev
$ export zimbra_admin_password=12345678
$ export zimbra_account_attrs='sn,givenName,displayName,zimbraMailAlias'
```

Now Run the server:

```bash
$ rackup
------------------------------------------------
Starting server with the following configuration
SOAP URL: https://127.0.0.1:7071/service/admin/soap
ADMIN USER: admin@zboxapp.dev
------------------------------------------------
[2016-02-26 13:11:48] INFO  WEBrick 1.3.1
[2016-02-26 13:11:48] INFO  ruby 2.0.0 (2013-05-14) [x86_64-darwin12.3.0]
[2016-02-26 13:11:48] INFO  WEBrick::HTTPServer#start: pid=52894 port=9292
```

And now you can query it at port 9292

### REST Routes

You have the following `routes`: `/accounts/`, `/domains/` and `/distribution_lists/`. For all
of them you have the same next actions:

* `POST`: For create
* `GET`: Without `ID` returns all the objects, with an `ID` return the requested object
* `PUT`: For update
* `DELETE`: For... yes, delete

Some examples:

```
 # Create a new Account
 $ curl -X POST -d "name='tmp@zbox.cl', password='12345678', displayName='tmp user'" http://localhost:9292/accounts/

 # Get All Domains
 $ curl http://localhost:9292/domains/

 # Get Domain using the name zboxapp.com
 $ curl http://localhost:9292/domains/zboxapp.com/

 # get Distribuition List using the zimbraId
 $ curl http://localhost:9292/distribution_lists/79a627c7-0ead-4cd3-b809-1e1f71ef373d/

 # Delete an Account using the zimbraId
 $ curl -X DELETE http://localhost:9292/accounts/c3525317-7172-420a-8d78-7f5ce1d195e5/

 # Update an Account
 $ curl -X PUT -d "'displayName'='Patricio Bruna'" http://localhost:9292/accounts/pbruna@zboxapp.com/

```

### Searching
By default if you make a GET call without an ID, the server makes a `DirectorySearch`, so
you can pass search parameters, like

```
 # Search all Admins Accounts
 $ curl -X GET -d 'zimbraIsAdminAccount='TRUE'' http://localhost:9292/accounts/

 # Search all Distribuition List for a given Domain
 $ curl -X GET -d 'domain=example.com' http://localhost:9292/distribution_lists/

 # Search with a RAW LDAP Filter
 $ export ldap_filter = '(&(|(zimbraMailDeliveryAddress=*@customer1.dev))(!(zimbraIsSystemAccount=TRUE)))'
 $ curl -X GET -d "raw_ldap_filter=$ldap_filter" http://localhost:9292/distribution_lists/

```

### Especial Requests

#### Count Accounts by Domain
Return the accounts grouped by `COS` for a given domain:

```
$ curl http://localhost:9292/domains/itlinux.cl/count_accounts
{"0bdd20b6-9fca-4f3c-a0e3-b8aa045c2ae0":3,"0ae7404d-4851-5ea4-a2d5-620a19b32b72":9}
```

#### Add Domain Accounts Limits
Limit the amount of accounts a Domain can have, in total and by `COS`

```
 # 20 accounts for the COS with ID 0bdd20b6-9fca-4f3c-a0e3-b8aa045c2ae0
 $ limit_by_cos = "0bdd20b6-9fca-4f3c-a0e3-b8aa045c2ae0:20"
 $ curl -X POST -d "total=30, cos=$limit_by_cos" http://localhost:9292/domains/itlinux.cl/accounts_quota
```

#### Account Mailbox Info
Storage (in bytes) and ID of the account mailbox:

```
$ curl http://localhost:9292/accounts/pbruna@example.com/mailbox
{"size":14755669972,"store_id":4640}
```

#### Add and Remove Account Alias

```
 # Add alias
 $ curl -X POST -d 'alias_name="pato@example.com"' http://localhost:9292/accounts/pbruna@example.com/add_alias

 # Remove alias
 $ curl -X POST -d 'alias_name="pato@example.com"' http://localhost:9292/accounts/pbruna@example.com/remove_alias
```

#### Token for view other account webmail

```
$ curl http://localhost:9292/accounts/pbruna@example.com/delegated_token
{"delegated_token":"0_9eca5cf3ec47480c1a216d9978d42e89b76fecab_69643d33363a63666436653931342d346630302d343430632d396135372d6531613933323731323862393b6578703d31333a313435363530393237333033393b6169643d33363a63666436653931342d346630302d343430632d396135372d6531613933323731323862393b76763d323a31373b747970653d363a7a696d6272613b7469643d31303a313930303734343336343b76657273696f6e3d31333a382e362e305f47415f313135333b"}
```

#### Account Archiving (Only Zimbra Network)
This let you enable the mail archiving. If the archiving mailbox doest not exists, it creates it.
You always must pass the Archiving `COS ID`


```
 # Enable archiving
 $ curl -X POST -d 'cos_id=cos_id' "/accounts/pbruna@example.com/archive/enable"

 # Disable archiving
 $ curl -X POST "/accounts/pbruna@example.com/archive/disable"
```

Disabling does not delete the archiving mailbox, only disable further mail archiving.

#### Account Distribution List Memberships
Get a list of `DLs` to which an account belongs to. The `via` attribute indicates if
the account belongs to other DL that belongs to this DL.

```
$ curl http://localhost:9292/accounts/pbruna@example.com/memberships | jq '.'
[
  {
    "id": "0253aa7e-7f05-4a15-88a2-4e1493fa5ce3",
    "name": "alertas@example.com",
    "via": null
  },
  {
    "id": "fe968179-5868-4fe1-a765-0c2d9431f328",
    "name": "comercial@example.com",
    "via": null
  },
  {
    "id": "baab2e9f-0ce3-41db-8643-ac0a7567a582",
    "name": "consultas@example.com",
    "via": null
  },
  {
    "id": "53506b58-ea1b-4f61-a8ff-c5fd61b14aca",
    "name": "devops@example.com",
    "via": 'alertas@example.com'
  }...
```

#### Add and Remove Members to Distribution Lists

```ruby
 # Add members
 post "/distribution_lists/sales@example.com/add_members", {'members' => ['pp@gmail.com', 'pa@gmail.com']}

 # Remove members
 post "/distribution_lists/sales@example.com/remove_members", {'members' => ['pbruna@gmail.com']}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/zimbra_rest_api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### v 0.1.9

#### Get DLs memberships for an Account

```
 get /accounts/:id/memberships
```

Returns an Array of DLs Hashes:

```
[{"id"=>"747972ab-a410-4f17-8d5e-db7be21d75e9",
  "name"=>"abierta@customer.dev",
  "via"=>nil},
 {"id"=>"e92f0d3d-1733-45a2-8e05-967f2d5a0cbe",
  "name"=>"restringida@customer.dev",
  "via"=>nil},
 {"id"=>"8b788848-e670-48b4-a72c-c9097b32a066",
  "name"=>"restringida@zbox.cl",
  "via"=>nil}]
```


### v 0.1.8

#### Enable and Disable Archiving for Accounts

```
 post /accounts/:id/archive/disable
 post /accounts/:id/archive/enable, { cos_id: cos_id, archive_name: archive_name}
```


### v 0.1.4

#### new endpoint `/distribution_lists/:id/add_members`

```json
members: { [email1, email2] }
```

#### new endpoint `/distribution_lists/:id/remove_members`

```json
members: { [email1, email2] }
```

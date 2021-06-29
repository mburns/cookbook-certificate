# Certificate cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/rsync.svg)](https://supermarket.chef.io/cookbooks/certificate)
[![CI State](https://github.com/sous-chefs/rsync/workflows/ci/badge.svg)](https://github.com/sous-chefs/certificate/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

## Description

This recipe automates the common task of managing x509 certificates and keys from encrypted Data Bags.  This cookbook
provides a flexible and re-usable LWRP which can be plugged into other recipes, such as the postfix or apache2
cookbooks.

### Warning about Vault mode

Vault mode is not supported in chef-solo, and will result in a failure condition.  One needs to select either encrypted,
or unencrypted, `data_bag_type` for use with chef-solo.

### Testing with encrypted data_bags

The KITCHEN.md is a reference document for testing encrypted data_bags with test-kitchen. The stub files
in`test/integration` are used to validate the `certificate_manage` library. These stub files in `test/integration`
should not be used in production.  These files include self-signed "snake oil" certificate/key and an
`encrypted_data_bag_secret` file which are not secure to use beyond testing.

## Requirements

You do need to prepare an encrypted data bag, containing the certificates, private keys, and CA bundles you wish to
deploy to servers with the LWRP. I used Joshua Timberman's [blog
post](http://jtimberman.housepub.org/blog/2011/08/06/encrypted-data-bag-for-postfix-sasl-authentication/), and the
Opscode [Wiki documentation](https://wiki.opscode.com/display/chef10/Encrypted+Data+Bags) as a reference in creating
this cookbook.

First, create a **data bag secret** as follows.  You need to manually copy the *encrypted_data_bag_secret* to
-/etc/chef* on your servers, or place it there as part of your bootstrap process.  For example, you may choose to do
deploy the secret file with kickstart or preseed as part of the OS install process.

```console
openssl rand -base64 512 > ~/.chef/encrypted_data_bag_secret
```

Second, create a data bag, the default data bag within the LWRP is named *certificates*.  However, you may override this
with the *data_bag* LWRP attribute.

```console
knife data bag create certificates
```

You need to convert your certificate, private keys, and CA bundles into single-line blobs with literal `\n` characters.
This is so it may be copy/pasted into your data bag. You can use `sed`, Perl, Ruby one-liners for this conversion.

```console
cat <filename> | sed s/$/\\\\n/ | tr -d '\n'
ruby -e 'p ARGF.read' <filename>
perl -pe 's!(\x0d)?\x0a!\\n!g' <filename>
```

What we're trying to accomplish is converting this:

```
-----BEGIN CERTIFICATE-----
MIIEEDCCA3mgAwIBAgIJAO4rOcmpIFmPMA0GCSqGSIb3DQEBBQUAMIG3MQswCQYD
-----END CERTIFICATE-----
```

Into this:

```
-----BEGIN CERTIFICATE-----\nMIIEEDCCA3mgAwIBAgIJAO4rOcmpIFmPMA0GCSqGSIb3DQEBBQUAMIG3MQswCQYD\n-----END CERTIFICATE-----
```

Finally, you'll want to create the data bag object to contain your certs, keys, and optionally your CA root chain
bundle.  The default recipe uses the OHAI attribute *hostname* as a *search_id*.  One can use an *fqdn* as the
-search_id*. Older versions of Knife have a strict character filter list which prevents the use of `.` separators in
data bag IDs.

The cookbook also contains an example *wildcard* recipe to use with wildcard certificates (\*.example.com) certificates.

Hostname mail as data bag search_id:

```console
knife data bag create certificates mail --secret-file ~/.chef/encrypted_data_bag_secret
```

The resulting encrypted data bag for a hostname should be structured like so. The *chain* id may be optional if your
CA's root chain is already trusted by the server.

```json
{
  "id": "mail",
  "cert": "-----BEGIN CERTIFICATE-----\nMail Certificate Here...",
  "key": "-----BEGIN PRIVATE KEY\nMail Private Key Here...",
  "chain": "-----BEGIN CERTIFICATE-----\nCA Root Chain Here..."
}
```

Wildcard certificate as data bag search_id:

```conosle
knife data bag create certificates wildcard --secret-file ~/.chef/encrypted_data_bag_secret
```

The resulting encrypted data bag should be structured like so for a wildcard certificate.  The *chain* id may be
optional if your CA's root chain is already trusted by the server.

```json
{
  "id": "wildcard",
  "cert": "-----BEGIN CERTIFICATE-----\nWildcard Certificate Here...",
  "key": "-----BEGIN PRIVATE KEY\nWildcard Private Key Here...",
  "chain": "-----BEGIN CERTIFICATE-----\nCA Root Chain Here..."
}
```

## Recipes

This cookbook comes with three simple example recipes for using the *certificate_manage* LWRP.

### default

Searches the data bag, *certificates*, for an object with an *id* matching *node.hostname*.  Then the recipe places the
decrypted certificates and keys in either */etc/pki/tls* (RHEL family), or */etc/ssl* (Debian family).  The default
owner and group owner of the resulting files are *root*.

The resulting files will be named {node.fqdn}.pem (cert), {node.fqdn}.key (key), and {node.hostname}-bundle.crt (CA Root
chain).

### wildcard

Same as the default recipe, except for the search *id* is *wildcard*. The resulting files will be named wildcard.pem
(cert), wildcard.key (key), and wildcard-bundle.crt (CA Root chain)

### manage_by_attributes

Retrieve search keys from attributes "certificate". Set ID and LWRP attributes to node attribute following...

```json
"certificate": [
  {"self": null},
  {"mail": {
    "cert_path": "/etc/postfix/ssl",
      "owner": "postfix",
      "group": "postfix"
    }
  },
]
```

## Resources

The resource properties are as follows:

- `data_bag` - Data bag index to search, defaults to certificates
- `data_bag_secret` - Path to the file with the data bag secret
- `data_bag_type` - encrypted, unencrypted, vault, none
  - vault type data bags are not supported with chef-solo
  - none type is used to provide values directly to the resource using plaintext_ parameters
- `search_id` - Data bag id to search for, defaults to provider name
- `plaintext_cert`: for data_bag_type 'none', should be formatted just like a data bag item
- `plaintext_key`: for data_bag_type 'none', should be formatted just like a data bag item
- `plaintext_chain`: for data_bag_type 'none', should be formatted just like a data bag item
- `cert_path` - Top-level SSL directory, defaults to vendor specific location
- `cert_file` - The basename of the x509 certificate, defaults to {node.fqdn}.pem
- `key_file` - The basename of the private key file, defaults to {node.fqdn}.key
- `chain_file` - The basename of the x509 certificate, defaults to {node.hostname}-bundle.crt
- `nginx_cert` - If `true`, combines server and CA certificates for nginx. Default `false`
- `combined_file` - If `true`, combines server cert, CA cert and private key into a single file. Default `false`
- `owner` - The file owner, defaults to root
- `group` - The file group owner, defaults to root
- `cookbook` - The cookbook containing the erb template, defaults to certificate
- `create_subfolders` - Enable/disable auto-creation of private/certs subdirectories.  Defaults to true

## Usage

Here is a flushed out example using the LWRP to manage your certificate items on a Postfix bridgehead.  The following
example should select the *mail* data bag object, from the *certificates* data bag.

It should then place the managed certificate files in */etc/postfix/ssl*, and change the owner/group to *postfix*.

```ruby
certificate_manage "mail" do
  cert_path "/etc/postfix/ssl"
  owner "postfix"
  group "postfix"
end
```

### .certificate, .key, .chain helper method usage

Some helper methods are exposed for retrieving key/certificate paths in other recipes:

- `.certificate` - The final path of the certificate file. i.e. `#{cert_path}/certs/#{cert_file}`
- `.key` - The final path of the key file. i.e. `#{cert_path}/private/#{key_file}`
- `.chain` - The final path of the chain file. i.e. `#{cert_path}/certs/#{chain_file}`

```rb
# where node.fqdn = 'example.com'
tld = certificate_manage 'top_level_domain'
tld_cert_location = tld.certificate # => /etc/ssl/certs/example.com.pem

# where node.fqdn = 'sub.example.com'
sbd = certificate_manage 'sub_domain' do
  cert_path '/bobs/emporium'
  create_subfolders false
end
sbd_cert_location = sbd.key # => /bobs/emporium/sub.example.com.key
```

### Setting FQDN during the converge

If you are updating the FQDN of the node during converge, be sure to use [lazy attribute
evaluation](https://docs.chef.io/resource_common.html#lazy-attribute-evaluation) when using the LWRP to ensure
`node['fqdn']` refers to the updated value.

```ruby
certificate_manage "wildcard" do
  cert_file lazy { "#{node['fqdn']}.pem" }
  key_file lazy { "#{node['fqdn']}.key" }
  chain_file lazy { "#{node['fqdn']}-bundle.crt" }
end
```

### Using the 'none' data bag type, supplying plain text example

The 'none' option doesn't use a data bag at all, but allows you to pass the certificate, key, and/or chain as a string
directly to the resource. This allows you to use the `certificate_manage` resource for all of your certificate needs,
even if you happen to have the data stored in a different data bag location or in some other external storage that isn't
supported.

```ruby
certificate_manage "fqdn-none-plaintext" do
  cert_file lazy { "#{node['fqdn']}.pem" }
  key_file lazy { "#{node['fqdn']}.key" }
  chain_file lazy { "#{node['fqdn']}-bundle.crt" }
  data_bag_type 'none'
  plaintext_cert "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n\n"
  plaintext_key "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n\n",
  plaintext_chain "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n\n",
end
```

## Contributors

This project exists thanks to all the people who [contribute.](https://opencollective.com/sous-chefs/contributors.svg?width=890&button=false)

### Backers

Thank you to all our backers!

![https://opencollective.com/sous-chefs#backers](https://opencollective.com/sous-chefs/backers.svg?width=600&avatarHeight=40)

### Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website.

![https://opencollective.com/sous-chefs/sponsor/0/website](https://opencollective.com/sous-chefs/sponsor/0/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/1/website](https://opencollective.com/sous-chefs/sponsor/1/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/2/website](https://opencollective.com/sous-chefs/sponsor/2/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/3/website](https://opencollective.com/sous-chefs/sponsor/3/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/4/website](https://opencollective.com/sous-chefs/sponsor/4/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/5/website](https://opencollective.com/sous-chefs/sponsor/5/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/6/website](https://opencollective.com/sous-chefs/sponsor/6/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/7/website](https://opencollective.com/sous-chefs/sponsor/7/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/8/website](https://opencollective.com/sous-chefs/sponsor/8/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/9/website](https://opencollective.com/sous-chefs/sponsor/9/avatar.svg?avatarHeight=100)

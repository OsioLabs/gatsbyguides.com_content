# Install and Configure Drupal

[# summary #]
If you want to integrate Gatsby and Drupal you'll have to get a Drupal site up-and-running in a location that Gatsby can access. Then install the JSON API module and make a couple of configuration changes.

In this tutorial we'll:

- Install the latest version of Drupal 8
- Install the contributed modules required to facilitate interaction with Gatsby
- Make some configuration changes in Drupal to allow Gatsby to access data

By the end of this tutorial you should have a working Drupal 8 site with some demo content that you can use as a backend data source for your Gatsby project. You should clearly understand what's required to get any Drupal site into a state that can work with Gatsby.
[# endsummary #]

## Goal

Install the latest version of Drupal on your development environment and configure it to work as a data source for Gatsby.

## Prerequisites

For the purposes of this tutorial we'll install Drupal on our [localhost](http://localhost) alongside Gatsby so we can easily do development for both at the same time. Alternatively, you can install Drupal using a hosting provider like [Pantheon](https://pantheon.io/) that allows you to have a development demo site.

If you've already got an existing Drupal site and want to update it so that it can be integrated with Gatsby, this tutorial will cover everything you need to do so. Skip the parts about getting Drupal installed and start with installing the JSON API module.

## Requirements for using Drupal as a backend for Gatsby

In order to use Drupal as a backend data source for Gatsby you need:

1. Drupal 8 installed
2. The contributed JSON API module enabled
3. Permissions configured so that anonymous traffic can access the JSON API provided REST endpoints
4. The contributed JSON API Extras and Simple OAuth modules enabled (optional, but recommended)
5. Drupal configured to support CORS

## Install Drupal

For this tutorial we'll install Drupal 8's Umami demo profile, which gives us a basic data model and some content we can use while learning. If you're following along with these tutorials in order to build your own application feel free to start with Drupal's standard profile and construct your own data model as required.

This makes a lot of assumptions, but the quickest way to get something up and running to follow along with these tutorials is as follows:

```shell
composer create-project drupal-composer/drupal-project:8.x-dev drupal --stability dev --no-interaction
cd drupal
composer require drupal/jsonapi drupal/jsonapi_extras drupal/simple_oauth
php web/core/scripts/drupal quick-start demo_umami
```

For a more in-depth look at what's required to get Drupal installed and running on a local development environment, check out [Chapter 3: Installation](https://drupalize.me/series/user-guide/installation-chapter) of the Drupal 8 User Guide.

## Download and enable contributed modules

In order to get Drupal and Gatsby to play well together we'll install the following contributed modules:

- [JSON API](https://www.drupal.org/project/jsonapi): This is the only one that's required for the integration to work. JSON API provides zero-configuration REST access to all the content in your Drupal site using the [{json:api}](https://jsonapi.org/) spec.
- [JSON API Extras](https://www.drupal.org/project/jsonapi_extras): Allows us to tweak the configuration of the JSON API module. We'll use this to disable resource endpoints that we don't need exposed.
- [Simple OAuth](https://www.drupal.org/project/simple_oauth): We'll use this, and the included Simple OAuth Extras module, to turn Drupal into an OAuth 2 provider. Our Gatsby application can then use Drupal for user account storage, authentication, and authorization.

The quickest way to download these all is using Composer. From the root of your Drupal project execute the following command:

```shell
composer require drupal/jsonapi drupal/jsonapi_extras drupal/simple_oauth
```

Then in your Drupal site in the Manage administration menu navigate to *Extend*. Click the box to enable *JSON API*, *JSON API Extras*, *Simple OAuth*, and *Simple OAuth Extras*. Scroll to the bottom of the page and click *Install*. Once completed you should see a confirmation message indicating that the modules were successfully installed.

You can confirm that JSON API is working by navigating to the URL */jsonapi* on your Drupal site. You should see a list of JSON API endpoints.

![Screenshot of Firefox showing output from accessing /jsonapi.](/content/gatsby-and-drupal/images/firefox-jsonapi-example.png)

[Learn more about downloading and installing Drupal modules](https://drupalize.me/tutorial/user-guide/extend-module-install?p=3072).

## Configure permissions

Edit the permissions to give the Anonymous role the *Access JSON API resource list* permissions. Without this Gatsby will get an HTTP 406 when trying to access the root listing at */jsonapi*.

In the Manage administration menu navigate to *People* > *Permissions*. Click the box for *Access JSON API resource list* under the Anonymous User header.

![Screenshot of the Drupal permissions page with the checkbox for the JSON API access resource list checked for anon users.](/content/gatsby-and-drupal/images/permissions-jsonapi.png)

Then scroll to the bottom of the page and click *Save permissions*.

## Configure Simple OAuth

First generate a pair of keys for the Simple OAuth module to use when encrypting tokens. These should be stored outside of your Drupal root directory. We recommend the following directory structure:

```txt
.
├── LICENSE
├── README.md
├── composer.json
├── composer.lock
├── config
├── keys
├── scripts
├── vendor
└── web // > Drupal root directory
```

Generate the necessary keys with the following set of commands:

```shell
mkdir keys
cd keys
openssl genrsa -out private.key 2048
openssl rsa -in private.key -pubout > public.key
chmod 600 public.key
chmod 600 private.key
```

Then tell the Simple OAuth module where to find them. In your Drupal site, in the Manage administrative menu navigate to *Configuration* > *Simple OAuth* and fill in the form with the paths to the keys you just generated.

```shell
Access token expiration time: 300
Refresh token expiration time 1209600
Public Key: ../keys/public.key
Private Key: ../keys/private.key
```

![Screenshot of simple oauth configuration form with settings listed above.](/content/gatsby-and-drupal/images/simpleoauth-settings.png)

Next, setup a a new OAuth client. First add a new Drupal role. Navigate to *People* > *Roles* (admin/people/roles) and add a new role named "Gatsby Client".

Then in the Manage administration menu navigate to *Configuration* > *Simple OAuth* > *Clients* and click the button *Add Consumer*. Fill in the form, and remember the value you enter for the *New Secret* field as you'll need that again later. Under *Scopes* choose the *Gatsby Client* role we just created. Finally, click *Save* to add the new consumer.

On the resulting page you should see your new consumer list along with a UUID. Make note of this UUID. Combined with the secret from above these will be your consumer ID, and key, used for OAuth requests later.

Finally, give authenticated users permission to *Grant OAuth 2 codes*. In the Manage administration menu navigate to *People* > *Permissions* (people/permissions). Check the box to give *Authenticated User* the *Grant OAuth 2 codes* permissions. Then scroll to the bottom of the page and click *Save permissions*.

![Screenshot showing simple oauth permissions checkbox checked.](/content/gatsby-and-drupal/images/permissions-simpleoauth.png)

## Configure CORS

If you're only using Drupal as a data source for Gatsby during the build phase this isn't required. However, if you plan to write code in your application that dynamically queries Drupal you'll need to set up [Cross Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS). We'll do this in our example application when we talk about hybrid pages and client only routes. So go ahead and configure it now.

Drupal 8 core provides support for CORS since 8.2, but it's turned off by default. To turn it on you will need to edit your *sites/default/services.yml* file. If you do not have one, you can create it by copying *sites/default/default.services.yml* and renaming it *sites/default/services.yml*.

Update the `cors.config` section to match the following:

```yaml
# Configure Cross-Site HTTP requests (CORS).
# Read https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
# for more information about the topic in general.
# Note: By default the configuration is disabled.
cors.config:
    enabled: true
    # Specify allowed headers, like 'x-allowed-header'.
    allowedHeaders: ['x-csrf-token','authorization','content-type','accept','origin','x-requested-with', 'access-control-allow-origin','x-allowed-header','*']
    # Specify allowed request methods, specify ['*'] to allow all possible ones.
    allowedMethods: ['*']
    # Configure requests allowed from specific origins.
    allowedOrigins: ['http://localhost/','http://localhost:8000','http://localhost:9000','*']
    # Sets the Access-Control-Expose-Headers header.
    exposedHeaders: true
    # Sets the Access-Control-Max-Age header.
    maxAge: false
    # Sets the Access-Control-Allow-Credentials header.
    supportsCredentials: true
```

This configuration is very generic, and it will allow any kind of resource sharing. It's suitable for learning purposes, but you should learn about hardening these settings for a production application. Make sure to update `allowedOrigins` and `allowedMethods` to reflect only the valid domains and HTTP methods that your browser-based applications use. Public APIs can leave these values as is, since they may not know about the consumers that integrate with the API.

After *services.yml* is updated, you need to [clear caches](https://drupalize.me/tutorial/clear-drupals-cache) for the changes to be applied.

## Recap

In this tutorial we downloaded and installed Drupal and the JSON API, JSON API Extras, and Simple OAuth contributed modules. Then we made changes to the default configuration necessary to allow Gatsby to access the data and users on our site. We adjusted permissions related to accessing JSON API data and OAuth tokens, generating public/private keys for OAuth encryption, and enabling CORS support.

With all of these steps complete your Drupal site is ready to serve as both a data source for Gatsby's build process as well as the target for dynamic API queries in React. Consumers will be able to access all of your site's content via the */jsonapi* endpoint, as well as authenticate and authorize users via OAuth.

## Further your understanding

- Explore the data made available by JSON API at /jsonapi
- Configure the JSON API Extras module to disable endpoints you don't need like those related to "blocks"

## Additional resources

- The Drupalize.Me [Web Services in Drupal 8](https://drupalize.me/series/web-services-drupal-8) series provides extensive documentation for using JSON API and OAuth with Drupal.
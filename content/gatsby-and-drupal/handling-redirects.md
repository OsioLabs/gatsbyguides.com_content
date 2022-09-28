# Dealing with Redirects

[# summary #]

When content on your site moves from one URL to another it's best practice to setup a redirect. Ensuring that any existing links will continue to work. With Gatsby we can use the `createRedirect` action within our _gatsby-node.js_ file to inform Gatsby about redirects we want to create.

The general technique for generating redirects is the same regardless of where you are sourcing your data from. We'll cover both generically creating redirects in Gatsby as well as specifically how to handle them in the context of using Drupal as a backend.

In this tutorial we'll learn about:

- Using the `createRedirect` action to register a redirect with Gatsby during the build process
- What Gatsby does, and doesn't, do with regards to redirects
- How to source information about redirects from Drupal and add them to our Gatsby application

By the end of this tutorial you'll know how to dynamically create redirects in Gatsby, and how to retrieve information about redirects to create from Drupal.

[# endsummary #]

## Goal

Learn how to create redirects from one route to another when the canonical URL of a page changes.

## Prerequisites

- [Understand what a 301 redirect is and the use case for them](https://moz.com/learn/seo/redirection)
- [Dynamically Creating Pages](http://dynamically-creating-pages.md)

## Register a redirect with Gatsby

Redirects get created at the same time as building the list of pages you want Gatsby to generate by using the `createRedirect` action passed to the `createPages` Node API. Call `createRedirect` once for every redirect you want to add and pass an object with information about the redirect as the argument.

Example:

```js
exports.createPages = ({ actions }) => {
  const { createRedirect } = actions;
  // Register a redirect from /old-url to /new/better-url.
  createRedirect({
    fromPath: 'old-url',
    toPath: 'new/better-url',
    isPermanent: true,
  });
};
```

[Read more about the options you can pass to the `createRedirect` function](https://www.gatsbyjs.org/docs/actions/#createRedirect).

Note that calling `createRedirect` solely registers with Gatsby that you would like the redirect to exist. Out of the box Gatsby doesn't actually generate any code to actually perform the redirect.

## Make the redirect do something

By default Gatsby doesn't generate code to perform a redirect. And instead leaves it up to plugins, or custom code, to figure out what to do with the list of redirects registered by the `createRedirect` action.

The preference is for this to be handled at the server level. For example via nginx or Apache configuration. Since Gatsby is server agnostic it instead relies on plugins to generate the necessary configuration for handling redirects.

Some examples of plugins that handle redirects:

- The [gatsby-plugin-netlify plugin](https://www.gatsbyjs.org/packages/gatsby-plugin-netlify/) generates Netlify specific redirect configuration
- The [gatsby-plugin-meta-redirect plugin](https://www.gatsbyjs.org/packages/gatsby-plugin-meta-redirect/) will generate a static HTML file with a `<meta>` tag like `<meta http-equiv="refresh" content="0; URL='/new-url/'" />` that will cause the client to redirect

## Generate your own redirect configuration

You can write custom code to handle whatever server side configuration is necessary for your environment. This is done by implementing the `onPostBuild` Node API. Redirects registered via the `createRedirect` action are available via the `store` object passed to `onPostBuild`.

This approach works the same way as the plugins linked above. And even if you don't write your own code this should help better understand what's happening during the build process.

Example implementation in _gatsby-node.js_:

```js
const path = require('path');
const fs = require('fs');

/**
  * Helper function to handle writing an array of redirects to a .json file.
  */
function writeRedirectsFile(redirects, folder, pathPrefix) {
  if (!redirects.length) return;
  let redirectList = [];

  for (const redirect of redirects) {
    const { fromPath, toPath } = redirect;
    redirectList.push({
      from: `${pathPrefix}/${fromPath}`,
      to: `${pathPrefix}/${toPath}`
    });
  }

  fs.writeFileSync(`${folder}/redirects.json`, JSON.stringify(redirectList));
}

// Implements Gatsby's onPostBuild Node API. Note, this ONLY runs during
// gatsby build, not during gatsby develop.
exports.onPostBuild = ({ store }) => {
  const { redirects, program, config } = store.getState();

  // Determine if the current application has a path prefix configured via
  // gatsby-config.js or other.
  let pathPrefix = '';
  if (program.prefixPaths) {
    pathPrefix = config.pathPrefix;
  }

  // Figure out where the /public directory is.
  const folder = path.join(program.directory, 'public');

  return writeRedirectsFile(redirects, folder, pathPrefix);
};
```

The above code does the following:

- Implements `onPostBuild` which runs at the end of `gatsby build`, by the time this function is called anything adding a redirect using the `createRedirect` action will have already done so
- Retrieve the list of redirects created during the build process using `store.getState()`
- Calculate any configured `pathPrefix`, and the location of the _public/_ directory where Gatsby outputs it's build artifacts
- Convert the list of redirects to a simplified JSON structure and write it to a file named _redirects.json_ that gets added to the _public/_ directory

Note: This code is executed by running the `gatsby build` command, but not when running `gatsby develop`.

## Configure Drupal to allow Gatsby to source redirect entities

In a typical Drupal configuration the [Pathauto module](https://drupal.org/project/pathauto) is used to automatically generate URL aliases based on a token like `post/[node:title]`. When the node's title changes, the associated URL changes as well. In [Dynamically Creating Pages](http://dynamically-creating-pages.md) we used the `node.path.alias` value from Drupal to set the route at which Gatsby would create a page. If this value changes in Drupal, the next time our Gatsby site is built the page will have a new route. And, unless we do some additional work, the old route will cease to exist.

It's [widely considered best practice to maintain 301 redirects in this scenario](https://moz.com/learn/seo/redirection). We need to make sure Gatsby and can figure out both the old and new URL and setup appropriate redirects.

If you don't have them installed already, download and install [Path Auto](https://www.drupal.org/project/pauthauto), and [Redirect](https://www.drupal.org/project/redirect).

```sh
composer require drupal/pathauto drupal/redirect
drush en pathauto redirect -y
```

Learn more about [Downloading and Installing a Module from Drupal.org](https://drupalize.me/tutorial/user-guide/extend-module-install?p=3072).

Configure Path Auto by navigating to _Configuration_ > _Search and Metadata_ > _URL Aliases_ > _Patterns_ (admin/config/search/path/patterns) in Drupal's administration menu. Here you configure one or more 

Click _Add pathauto pattern_. Choose "Content" in the _Pattern type_ dropdown and then set a _Path pattern_ using the available tokens. In our example site we've got a content type named Recipe, and we'll set the Path pattern to `recipe/[node:title]`. The `[node:title]` token will be automatically replaced with a URL safe version of the title of the recipe.

![Screenshot of Drupal's pathauto module configuration form showing it filled in with the values listed above.](/content/gatsby-and-drupal/images/redirects-pathauto-config.png)

Next, configure the Redirect module to automatically generate redirects when a URL changes. Navigate to _Configuration_ > _Search and Metadata_ > _URL Redirects_ > _Settings_ (admin/config/search/redirect/settings) in Drupal's administration menu. Then check the checkbox for _Automatically create redirects when URL aliases are changed_.

To make redirect records publicly accessible, and available to the gatsby-source-drupal plugin, you'll also need to apply a patch which allows for more granular access control. Without the patch there is no way to provide read-only access to redirect entities.

- Patch: <https://www.drupal.org/node/3057679>
- [Learn about patching projects using Composer](https://github.com/cweagans/composer-patches/blob/master/README.md)

With the patch in place, navigate to _Configuration_ > _People_ > _Permissions_ (admin/people/permissions). Then give read-only access to redirect records for all users by checking the box labeled "View redirect entity" under the _Anonymous user_ column and pressing _Save_.

![Drupal's permissions page with the box in the anonymous users column checked for the View redirects permissions.](/content/gatsby-and-drupal/images/redirects-drupal-permissions.png)

At this point you should be able to access redirect records via the API. Assuming you've got one or more redirect record in Drupal when you visit the [`/jsonapi/redirect/redirect`](https://gatsby-drupal-demo.ddev.site/jsonapi/redirect/redirect) endpoint you should see them listed. If you don't have any redirects edit an existing node and change it's title to create one.

Now when you run the `gatsby develop` command you should see those redirect records in Gatsby's GraphQL database. Look for the `allRedirectRedirect` collection.

![Screenshot of GraphiQL showing a set of redirect records sourced from Drupal.](/content/gatsby-and-drupal/images/redirects-graphql.png)

## Add redirects during page creation

Now that we have access to the redirects in Gatsby's GraphQL database we need to use that information along with the `createRedirect` action to inform Gatsby about the redirect.

In your _gatsby-node.js_ file add, or adjust, the code to that it contains something like the following. This example builds on the `createPages` code written in the [Dynamically Creating Pages](/content/gatsby-and-drupal/dynamically-creating-pages.md) tutorial.

```js
exports.createPages = async ({ graphql, actions }) => {
  const { createPage, createRedirect } = actions;

  // Load any information about redirects.
  // This data is used when creating pages below to check for changes in the
  // Drupal generated path to a page and then calls createRedirect().
  // Note that calls to createRedirect() don't do anything by default other than
  // make the data available to plugins. You'll need a plugin like
  // https://www.gatsbyjs.org/packages/gatsby-plugin-netlify/ to actually setup
  // redirects to happen.
  const redirects = await graphql(`
    {
      allRedirectRedirect {
        edges {
          node {
            redirect_source {
              path
            }
            redirect_redirect {
              uri
            }
          }
        }
      }
    }
  `).then(result => {
    // Create pages for collections sourced from Drupal.
    const data = [];
    if (!result.errors) {
      result.data.allRedirectRedirect.edges.forEach(({ node }) => {
        // Redirect paths will take one of two forms depending on how they were
        // created in Drupal. entity:node/42 or internal:/node/42, this
        // normalizes them both to /node/42.
        data[node.redirect_redirect.uri.replace(/^entity:|internal:\//, '/')] = node;
      });
    }

    return data;
  });

  return new Promise((resolve, reject) => {
    graphql(`
      {
        allNodeRecipe {
          edges {
            node {
              drupal_id,
              drupal_internal__nid,
              title,
              path {
                alias,
              }
            }
          }
        }
      }
    `).then(result => {
      result.data.allNodeRecipe.edges.forEach(({ node }) => {
        let path_alias;
        if (node.path.alias == null) {
          path_alias = `recipe/${node.drupal_id}`;
        } else {
          path_alias = node.path.alias;
        }

        // Handle generating redirects as needed.
        if (redirects[`/node/${node.drupal_internal__nid}`]) {
          createRedirect({
            fromPath:
            redirects[`/node/${node.drupal_internal__nid}`].redirect_source
              .path,
            toPath: path,
            isPermanent: true,
            redirectInBrowser: true,
          });
        }
        
        createPage({
          // This is the path, or route, at which the page will be visible.
          path: path_alias,
          // This the path to the file that contains the React component
          // that will be used to render the HTML for the recipe.
          component: path.resolve(`./src/templates/recipe.js`),
          context: {
            // Data passed to context is available in page queries as GraphQL
            // variables.
            drupal_id: node.drupal_id,
          },
        })
      });

      resolve()
    })
  })
};
```

In the above code we:

- Get the `createRedirect` action from the supplied `actions` object.
- Query GraphQL for a list of all redirects.
- Look over the results and transform the data making it easier to match with the values we get for the `node.path.alias` field. Drupal stores redirects using a Drupal specific scheme for routes, and we need to accommodate for that. We do so by normalizing them all to the form `/node/{NID}`.
- Save the normalized data as `redirects` for later use.
- Update the GraphQL query used to get information about recipes to include the `drupal_internal__nid` field in the results. This field contains the node ID used in Drupal, and will match what's used in the redirect records.
- Inside the `forEach` loop where we create pages for each of the recipes we added some code to check if there are any redirect records for the node we're creating a page for, and if so, call the `createRedirect` action and register the redirect with Gatsby.

Now, when you run the `gatsby build` command it'll register any redirects with Gatsby. And then any plugins you have enabled that handle redirects will be able to use that information to ensure that when a user navigates to <https://example.com/old-url> they get redirected to <https://example.com/new/better-url>.

## Recap

In this tutorial we learned how to use the Gatsby `createRedirect` API to register a new redirect. We learned that by default Gatsby doesn't do anything with these redirect records, but we can use custom code or install a plugin to make use of them. Finally, we learned how to configure Drupal to generate redirects when a node's path changes, and how to use those redirect records within Gatsby.

## Further your understanding

- Can you configure Gatsby to create output a static HTML page that contains a `<meta>` redirect corresponding to each of the redirects from Drupal?
- Why do you need to rebuild your Gatsby application whenever a redirect entity is created in Drupal?

## Additional resources

- [Gatsby createRedirect documentation](https://www.gatsbyjs.org/docs/actions/#createRedirect) (gatsbyjs.org)
- [Redirect module](https://drupal.org/project/redirect) (drupal.org)

<!-- internal -->
<!-- lint disable -->
<!-- vale off -->

In many typical Drupal configurations you use something like path auto to automatically generate URLs based on a token like `post/[node:title]`, when the title changes, the URL might change as well. If it does you now have the possibility of some content somewhere linking to the old URL and/or SEO stuff so you'll need to maintain the 301 redirect.

- Can you get redirects from Drupal in GraphQL?
- Then query them to make a list and use the `createRedirect` or whatever the appropriate Gatsby Node API is for creating redirects
- Then `gatsby build` and test it to make sure that it works

Steps

- In Drupal install and configure(?) PathAuto and Redirect modules. A common setup. So that when the title of a page is changed the URL is updated and a Redirect is created
- `composer require drupal/pathauto drupal/redirect`
- Edit an existing recipe, and change the URL so that a new redirect is created

_Current status:_ redirect entities aren't GETable by anon users so they don't end up in GraphQL and therefore don't currently have a way to get that list in Gatsby.

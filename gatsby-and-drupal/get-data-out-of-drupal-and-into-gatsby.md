# Get Data Out of Drupal and Into Gatsby

[# summary #]
One of the killer features of Gatsby is its ability to pull in data from various sources at build time, and then use that data to dynamically generate what will eventually become the static pages of your site. Rather than hard-code a specific data source, Gatsby uses source plugins to allow developers to choose from a variety of different data sources, including Drupal.

In this tutorial we'll:

- Learn about how source plugins work at a high-level
- Install and configure the *gatsby-source-drupal* source plugin
- Connect our Gatsby environment to Drupal and test that it's all working by exploring Gatsby's GraphQL database

By the end of this tutorial you'll know what source plugins are, the role they play in a Gatsby project, and how to use the *gatsby-source-drupal* plugin to pull data out of Drupal and into Gatsby at build time.
[# endsummary #]

## Goal

Use the *gatsby-source-drupal* plugin to ingest Drupal content into Gatsby.

## Prerequisites

- [Install and Configure Drupal](/content/gatsby-and-drupal/install-and-configure-drupal.md)
- [Familiar with the concept of plugins for Gatsby](https://www.gatsbyjs.org/docs/plugins/)
- [Familiar with GraphQL](https://www.howtographql.com)

## What are source plugins?

When we think of static site generators we probably imagine a tool that reads Markdown files from Git repository, applies a template, and converts them to HTML at build time. Gatsby can do this, but it can also do a whole lot more.

Source plugins are what Gatsby uses to pull data into GraphQL to build its internal [data layer](https://www.gatsbyjs.org/tutorial/part-four/#data-in-gatsby). Using source plugins Gatsby is made to collect your data from wherever that data lives: Markdown files in the filesystem, Google Spreadsheets, Drupal, third party APIs, and more. Then at build time, it creates an internal GraphQL server of all of this data.

This is a super powerful concept. It's one of the things that really sets Gatsby apart. Gatsby can source data from multiple locations at the same time. And **all of that data** is pulled into a single GraphQL database. This gives the developers working on your Gatsby application a single unified way to access any of the data they might need to render a page.

In most cases this can be done with minimal custom code. Install the required source plugins, configure them, and let Gatsby do its thing.

Read more about [Data in Gatsby](https://www.gatsbyjs.org/tutorial/part-four/#data-in-gatsby). Then check out the [list of available source plugins](https://www.gatsbyjs.org/plugins/?=gatsby-source-).

## gatsby-source-drupal

We'll use the *[gatsby-source-drupal](https://www.gatsbyjs.org/packages/gatsby-source-drupal/)* plugin to ingest data from Drupal. This works because earlier we added the JSON API module to Drupal. That module outputs our Drupal sites content using the {json:api} spec. Because the *gatsby-source-drupal* plugin understands that spec, with very little configuration it can do the work of finding content in Drupal and pulling it into Gatsby's GraphQL database.

Install the plugin:

```shell
npm install --save gatsby-source-drupal
```

Edit *gatsby-config.js* and add the necessary configuration:

```js
module.exports = {
  plugins: [
    {
      resolve: `gatsby-source-drupal`,
      options: {
        baseUrl: `http://gatsby-drupal.ddev.local/`,
        apiBase: `jsonapi`, // optional, defaults to `jsonapi`
      },
    },
  ],
}
```

Plugin configuration is nested within the `plugins:` array. Each entry represents a plugin, and can be either a **string** (the name of the plugin to enable for those that don't require configuration) or an **object** (with additional configuration information for the plugin).

The `baseUrl` is the base URL of your Drupal site. That is, the location of your Drupal home page. `apiBase` is the location at which the JSON API module exposes its endpoints. By default this is */jsonapi*.

Start, or restart, the Gatsby development server after making these changes:

```shell
$ gatsby develop

success open and validate gatsby-config — 0.132 s
success load plugins — 1.067 s
success onPreInit — 3.724 s
success delete html and css files from previous builds — 0.359 s
success initialize cache — 0.134 s
success copy gatsby files — 0.236 s
success onPreBootstrap — 0.013 s
⠁ Starting to fetch data from Drupal
success source and transform nodes — 102.818 s
success building schema — 1.485 s
success createPages — 0.189 s
success createPagesStatefully — 0.074 s
success onPreExtractQueries — 0.011 s
success update schema — 0.492 s
success extract queries from components — 0.375 s
success run graphql queries — 0.274 s — 18/18 66.21 queries/second
success write out page data — 0.016 s
success write out redirect data — 0.001 s
⠄ onPostBootstrapdone generating icons for manifest
success onPostBootstrap — 0.356 s

info bootstrap finished - 122.444 s

You can now view gatsby-starter-default in the browser.

  http://localhost:8000/

View GraphiQL, an in-browser IDE, to explore your site's data and schema

  http://localhost:8000/___graphql
```

This time during the bootstrap process Gatsby will see you've got the *gatsby-source-drupal* plugin installed, and will invoke it during the "source" phase. The plugin goes out and grabs a copy of every entity exposed by JSON API and puts it into Gatsby's GraphQL store, and also downloads a copy of every image attached to any image field so they can be included in your static site build.

## Test it out

Once the development server is up and running click the link for the [GraphiQL in-browser IDE](https://github.com/graphql/graphiql) that Gatsby output. Probably [http://localhost:8000/___graphql](http://localhost:8000/___graphql). GraphiQL is a powerful tool for querying and inspecting a GraphQL database, and Gatsby helpfully includes it in its development server and automatically links it to the GraphQL database containing all the data Gatsby just sourced.

If everything worked, you should be able to run queries here that show the data which Gatsby pulled in from Drupal. Note that Gatsby creates GraphQL collections out of Drupal content following a specific naming convention: `allNode{CONTENT-TYPE}`. The pattern is the text "allNode" followed by the machine name of the Drupal content type.

Here's an example query you can try:

```graphql
{
  allNodeRecipe {
    edges {
      node {
        drupal_id,
        title,
        created,
        path {
          alias,
        }
        relationships {
          field_image {
            localFile {
              absolutePath,
            }
          }
        }
      }
    }
  }
}
```

## UUID vs drupal_id

In order to maintain compatibility with Drupal's JSON API module at both versions 1.x, and 2.x+, you should use the `drupal_uid` field as the unique identifier for an entity whenever you're working with content from Drupal. This ensures that the ID being used within Gatsby is also the same as the one being used by Drupal. This is necessary due to how the `UUID` field output by Drupal is handled in JSON API v1 vs v2+.

## Drupal entity reference fields

In Drupal's data model pieces of content (entities) are able to declare relationships to other pieces of content using what are known as entity references. When Gatsby sources data from Drupal, these entity references are migrated to GraphQL "relationships", which is why you don't see those fields where you might expect them in the GraphQL schema. Don't worry, they're still there, you just need to look in the "relationships" field.

The *gatsby-source-drupal* plugin also helpfully creates backreferences for any entity reference within GraphQL. So you can traverse a relationship in either direction -- from recipe to author, or from author to recipe.

Also note that if the Entity being referenced isn't available via JSON API (for permissions reasons, for example) then it won't show in GraphQL. For example, if an anonymous user can't view user profiles, Gatsby won't contain an "author" field for Drupal nodes. When trouble-shooting, if the data isn't available in Gatsby's GraphQL database, first verify that it's accessible via the Drupal */jsonapi* endpoint to non-authenticated users.

## Recap

In this tutorial we installed the *gatsby-source-drupal* plugin and configured it to ingest data from Drupal. We then ran `gatsby develop` which performs the source and transform nodes operation that gets data out of Drupal and into Gatsby's GraphQL database. Then finally we confirmed that it was working using the GraphiQL IDE to explore the imported data.

## Further your understanding

- Use the GraphiQL IDE to further explore the data imported from Drupal. Note how it only imports content entities and not configuration entities. What other content is available? And what is missing that you might be used to seeing with Views in Drupal?

## Additional resources

- [Sourcing from Drupal](https://www.gatsbyjs.org/docs/sourcing-from-drupal/) (gatsbyjs.org)
- [Gatsby using Drupal Example repo](https://github.com/gatsbyjs/gatsby/tree/master/examples/using-drupal) (github.com)
- [How to GraphQL](https://www.howtographql.com) (howtographql.com)

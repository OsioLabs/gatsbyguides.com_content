# #100DaysOfGatsby Week 2: Host Your Gatsby Site for Free

The [week #2 challenge](https://www.gatsbyjs.org/blog/100days/free-hosting/) is to deploy your Gatsby project to the web. If I am successful, you can read this blog post.

🎉Tada! If you're reading this it's working. :) 🎉

This site is hosted on [Netlify](https://netlify.com). We chose Netlify because it was quick to get started with, and thus far has been more than sufficient for our requirements.

The basic setup was relatively easy. After creating an account with Netlify, and authorizing Netlify to access my GitHub repos, I was able to choose the repository for this site. Netlify automatically recognized that it was a Gatsby project and provided some default configuration that got things working.

Over time we've made some changes to the default configuration to accommodate our use-case. I'll talk more about those changes below.

## What's involved in publishing a Gatsby site?

When you run `gatsby build` Gatsby pulls in the dynamic blog content stored in the Drupal backend and uses it to create a set of static assets that represent the current state of the content. Think of it as taking a snapshot of your content exactly as it exists at that moment. These assets, once generated, are fixed in time. Any changes you make to the content in Drupal won't be reflected on the site until you run `gatsby build` again and create a new snapshot.

At a very high level, publishing a Gatsby site requires you to:

1. Make changes to your content, or Gatsby source code
2. Run `gatsby build` to generate the production assets for the site
3. Put those production assets in a location that's accessible via the web

In our case there are two different reasons we need to do a deployment and update the site:

1. Content was added, or updated, in Drupal and we need to rebuild the site to reflect those changes.
2. Gatsby source code was changed — for example, CSS tweaks — and we need to rebuild the site to make those changes take effect.

## Publish content changes

![](/content/blog_posts/images/Build_hooks2.png)

Whenever a new blog post is added in Drupal, or an existing blog post edited, the static assets for the blog need to be recreated. Essentially, someone, or something, needs to run `gatsby build` and move the resulting files to the web host.

In our case, Netlify takes care of running the `gatsby build` command and then hosting the resulting application. But we need to tell Netlify when the content changes so that it knows to run the build process.

To accomplish this we're using the [Build Hooks module](https://www.drupal.org/project/build_hooks). We've configured the module to add a button that content editors can click to trigger a Netlify build. The module also allows you to automatically trigger a build whenever Drupal detects a change. For our use case, we've left this as a manual process. Often times an editor will make changes to multiple different content items in a batch, and we don't need to run a build for every edit.

## Deploy code changes

One of the features of Netlify is branch deployments. That is, for every branch (or pull-request) opened in Git, Netlify will automatically build and host a preview version of the site. You can click around and test that your changes work before merging them in. It's awesome!

Our Drupal application, hosted by Pantheon, has a similar feature where we can build preview environments to review changes before merging them. It also provides a development environment for integrating features, and a test environment for doing QA before deploying to production.

When building preview versions of the Gatsby application we generally want to do so against the QA version of our Drupal backend instead of the production site. This is especially true for sites like [https://heynode.com](https://heynode.com) which have a subscription feature. In order to test the subscription system is working, we want to use a development instance of the payment gateway.

To accomplish this we've configured all non-production instances of our Drupal application to make use of testing environments for payments, mail handling, and other things. Likewise, we've configured all non-production builds of the Gatsby sites to build against a Drupal test environment.

Additionally, we sometimes make changes that require updates to both the Drupal and Gatsby codebases in order to work. For instance, adding a blog feature requires creating the blog content type in Drupal, and writing the Gatsby code to consume that content. By changing the environment that Gatsby uses when sourcing content we can preview what these changes will look like and work on them in tandem.

On the Gatsby side we accomplish this by:

1. Using environment variables to configure the URL that Gatsby sources Drupal content from
2. Setting different values for these environment variables on Netlify depending on the build context

For the *gatsby-config.js* file we're making use of Node.js's `process.env` global to read environment variables, and the [Node.js dotenv package](https://www.npmjs.com/package/dotenv) to help with configuration. Then instead of hard-coding the location of the Drupal backend we provide it as `process.env.GATSBY_DRUPAL_API_ROOT`.

Example *gatsby-config.js*:

```js
require('dotenv').config({
    path: `.env`,
});

// During SSR we need to figure out this location value based on ENV variables.
// We need to know this for setting things like the ?redirect= param in OAuth links.
if (typeof window === 'undefined') {
  if (typeof process.env.CONTEXT === 'undefined') {
    // If you're getting this it's because you're running gatsby build without
    // specifying a CONTEXT environment variable.
    throw new Error('Can not complete build without required ENV variables.');
  }

  if (process.env.CONTEXT === 'development') {
    // When running gatsby develop we can just leave this as null as there's no
    // SSR happening when using the dev server.
    process.env.GATSBY_ROOT_URL = '<http://localhost:8000>';
  } else if (process.env.CONTEXT === 'production') {
    process.env.GATSBY_ROOT_URL = process.env.URL;
  } else if (
    process.env.CONTEXT === 'deploy-preview' ||
    process.env.CONTEXT === 'branch-deploy'
  ) {
    process.env.GATSBY_ROOT_URL = process.env.DEPLOY_PRIME_URL;
  }
}

module.exports = {
  siteMetadata: {
    title: 'GatsbyGuides.com',
    siteUrl: process.env.GATSBY_ROOT_URL,
    description: `Learn to build blazing fast web applications with Gatsby.`,
    author: ``,
  },
  plugins: [
    {
      resolve: `gatsby-source-drupal`,
      options: {
        baseUrl: process.env.GATSBY_DRUPAL_API_ROOT,
        apiBase: `api`,
        filters: {
          'node--tutorial': 'filter\[consumer.label\][value]=GatsbyGuides.com',
          'node--collection': 'filter\[consumer.label\][value]=GatsbyGuides.com',
          'node--blog_post': 'filter\[consumer.label\][value]=heynode.com',
        },
      },
    },
    ...
  ],
};
```

This example also contains some logic to dynamically set the `siteMetadata.siteUrl` variable depending on the build environment. In our use case we need to do this to make OAuth work correctly.

Here's an example *netlify.toml* file that sets a different Drupal root for non-production builds:

```toml
[build]
  base    = "web"
  publish = "web/public"
  command = "npm run build"

[build.environment]
  # Don't install devDependencies. Speeds up builds a little.
  NODE_ENV = "production"

[context.production.environment]
  GATSBY_DRUPAL_API_ROOT = "<https://members.osiolabs.com>"

# Branch Deploy context: all deploys that are not from a pull/merge request or
# from the Production branch will inherit these settings.
[context.branch-deploy.environment]
  GATSBY_DRUPAL_API_ROOT = "https://test-*****"

# Deploy Preview context: all deploys resulting from a pull/merge request will
# inherit these settings.
[context.deploy-preview.environment]
  GATSBY_DRUPAL_API_ROOT = "https://test-*****"
```

This file gets included in the root of your Git repo and Netlify will use it whenever it performs a build.

[Read more about configuring environment specific variables for Netlify](https://docs.netlify.com/configure-builds/get-started/#build-environment-variables).

## There’s so much more to learn!

I would like to spend some time exploring how to schedule blog posts for future publication. At a high level I think this involves using a Drupal module like [Scheduler](https://www.drupal.org/project/scheduler) to allow a content editor to set a publication date. Then I’d probably write some code that detects when the Scheduler transitions an entity from un-published to published. Finally, I think I can leverage the code already in the Build Hooks module to trigger a Netlify build.

My coworker Blake has been working on setting up a build process that uses [Tugboat.qa](https://tugboat.qa). The idea is that when a pull-request is created for the Drupal 8 backend our CI setup will create an instance of the Drupal application using the code from that PR — while also cloning the current (configurable) version of each of the Gatsby client sites and building previews of them as well. This would allow us to created fully isolated previews for the whole stack, and to do some additional end-to-end testing. I’m looking forward to seeing what he comes up with.

## Additional resources

- [Learn more about Environment variables](https://heynode.com/tutorial/overview-environmental-variables) ([heynode.com](http://heynode.com))
- Learn more about how to [Set Up and Test a Dot Env (.env) File](https://heynode.com/tutorial/set-and-test-dot-env-env-file) ([heynode.com](http://heynode.com))
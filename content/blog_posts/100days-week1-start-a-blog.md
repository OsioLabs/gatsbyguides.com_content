# #100DaysOfGatsby Week 1: Start A Blog

The first of the #100DaysOfGatsby challenges is to start a blog to keep track of your progress. If you're reading this, that means I've completed that challenge. Woohoo!

[Read more about the first challenge here](https://www.gatsbyjs.org/blog/100days/start-blog/).

Rather than start from scratch, I'm going to add a blog to the existing [gatsbyguides.com](http://gatsbyguides.com) site. In fact, it’s the blog you're currently reading. The content for this blog, like the rest of the content on this site, will be sourced from a Drupal 8 backend.

I've already built Gatsby sites, a few of which were integrated with Drupal. I've even [built a blog](https://heynode.com/blog) before. So in my posts I’ll focus on some of the more unique aspects that went us into making this blog. However, if you're curious to learn more about the basics of integrating Gatsby and Drupal, this site already has tutorials covering [why Drupal](https://gatsbyguides.com/tutorial/introduction-drupal-gatsby-developers), [getting started with Drupal](https://gatsbyguides.com/tutorial/install-and-configure-drupal), and [connecting Gatsby to Drupal](https://gatsbyguides.com/tutorial/get-data-out-drupal-and-gatsby) using the gatsby-source-Drupal plugin.

The rest of this post assumes that you're already familiar with the basics of installing and configuring Gatsby plugins. You should also be familiar with using the `createPages()` Node API to extract content from GraphQL and turn it into pages.

## One Drupal, many blogs

We use a single Drupal 8 application as the backend for many sites. Right now that includes this site and [https://heynode.com](https://heynode.com). In future, we plan on making more.  Drupal handles our content management needs, payment infrastructure (for Hey Node), and user authentication needs.

To achieve this, one of the things we use is the [Consumers module](https://www.drupal.org/project/consumers). That allows us to create entities in Drupal that represent the different sites (consumers) that Drupal will be managing content for. We then use entity reference fields on the different content types to associate individual content items with one or more consumers.

For example, when creating a new blog post we can choose which site(s) to associate a post with.

![](/content/blog_posts/images/create-blog-post.png)

This example uses an entity reference field with the list widget, giving the content author a set of checkboxes to choose which consumer(s) the post belongs to. We've chosen to allow blog posts to be associated with more than one site, making it possible for a single post to appear on multiple sites. But you could just as easily turn this into a select list and require a one-to-one relationship between a blog post and a consumer.

Using this setup, regardless of which blog you're writing for, you’ll use the same Drupal backend to author the post. From an infrastructure perspective, this setup means there's only one Drupal instance we need to maintain. When work is done to improve the backend API, or the content authoring experience, those changes are available across all our sites, regardless of which specific product they were developed for.


## Tell Gatsby to get only the blog posts for this site

Initially when setting this up I used a very straightforward configuration for the gatsby-source-drupal plugin. Basically, turn it on, and suck in all the content that Drupal exposed. Then in the GraphQL query in the `createPages()` implementation in *gatsby-node.js**,* I added a filter to return only blog posts associated with this site.

Example:

```graphql
{
  allNodeTutorial(filter:{
    relationships: {
      consumers: {
        elemMatch: {
          name: {
            eq: "gatsbyguides.com"
          }
        }
      }
    }
  }) {
    edges {
      node {
        drupal_id,
        title,
        path {
          alias
        },
        # ...
      }
    }
  },
}
```

This works fine, but it means that each time `gatsby build` runs, it pulls in ALL the blog posts from the CMS. Right now that's not that many. But it could become hundreds, or thousands, in the future. Imagine if each blog post had an image associated with it, and Gatsby needed to process that image. Then imagine how this would result in really long build times and some non-trivial amount of data getting thrown away without being used.

A better solution would be to get only the content for this specific site from Drupal, so that Gatsby only has to process things it will actually use. Drupal's JSON API already has the capacity to filter the results returned from a request. We just needed to teach Gatsby how to apply filter parameters to the requests that it makes. It turns out, making this possible [wasn't to](https://github.com/gatsbyjs/gatsby/issues/11696)[o](https://github.com/gatsbyjs/gatsby/issues/11696) [much work](https://github.com/gatsbyjs/gatsby/issues/11696). Yay open source!

The gatsby-source-drupal plugin allows you configure optional per-collection JSON API filters.

Here's an example of what the configuration looks like:

```js
{
  resolve: `gatsby-source-drupal`,
  options: {
    baseUrl: process.env.GATSBY_DRUPAL_API_ROOT,
    apiBase: `api`,
    filters: {
      'node--blog_post': 'filter\[consumer.label\][value]=GatsbyGuides.com',
    },
  },
},
```

The `filters` key is an object whose keys are the JSON API collection ID, and whose value is the filter you want to apply to that collection. You can figure out the collection ID by visiting the root of your JSON API endpoint. View an example here `https://members.osiolabs.com/api`. Under the "links" section of the output are the collection IDs.

![](/content/blog_posts/images/jsonapi-preview.png)

You can use [any valid JSON API filter](https://www.drupal.org/docs/8/modules/jsonapi/filtering) to limit what's returned when Gatsby sources data from that collection. The above example would result in Gatsby using this URL `https://members.osiolabs.com/api/node/blog_post?filter[consumer.label][value]=GatsbyGuides.com`. The end result is that only blog posts which have the checkbox for the [GatsbyGuides.com](http://GatsbyGuides.com) consumer checked will be returned from Drupal, and Gatsby won't have to bother with collecting and processing a bunch of unnecessary data.

Another side effect of the fact that we have one Drupal backend powering multiple blogs is that while developing this specific blog, I could use content from another blog to test and make sure things were working. To do so, I only needed to modify the filter.


## Conclusion

We wanted a way to use a single Drupal 8 site as the content source for multiple, loosely related Gatsby sites. To accomplish this, we created a data model in Drupal that uses Consumer entities to represent the different frontends, and leverages entity reference fields to associate content with a specific consumer.

Then we configured the gatsby-source-drupal plugin so that it could be smart about only downloading the content from Drupal required for the site being built.
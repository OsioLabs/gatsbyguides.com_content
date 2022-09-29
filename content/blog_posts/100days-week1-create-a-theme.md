# #100DaysOfGatsby Week 1: Create a Gatsby Theme

[In the previous post](/content/blog_posts/100days-week1-start-a-blog.md) I explained how we use a single Drupal backend to serve content to multiple different Gatsby frontends. Building on that, I want to create a Gatsby theme to encapsulate the code for processing blog posts from Drupal. This theme would be a useful tool going forward, because doing things like processing blog posts into pages, dealing with Drupal routing, and paging for lists is likely to use very similar code for each site.

## Making a Gatsby theme

[Gatsby themes](https://www.gatsbyjs.org/docs/themes/) are a mechanism for capturing some subset of a Gatsby application’s configuration, API implementations, and components into a reusable package.

My thinking is that creating a theme which understands the shared Drupal backend would make it easier to add a blog to any product site without having to re-do a bunch of work. This has some awesome benefits for us:

- The code and configuration required to do the heavy lifting of interacting with Drupal can be shared among projects.
- It can be independently versioned and managed.
- When one client site requires updates to blog functionality, all projects can benefit.
- When we change something about how the backend works that affects the Gatsby code, we only have to update it in one place and roll it out to all the different sites. A recent example of this was JSON API schema changes in Drupal 8.8.

When I first created the theme I also included the CSS styling and UX of a blog in the theme. This ended up being a mistake. It turns out, while we wanted all our blogs to share the business logic of sourcing data from Drupal and turning it into pages in a Gatsby site, we didn’t want all our blogs to look the same.

Ultimately we decided that for our use case, the role of the theme should be to:

- **Source blog post data** from Drupal.
- Implement Gatsby's `createPages()`, `createRedirect()` and other page creation related APIs.
- **Message the data** received from Drupal into a form that's a bit more user friendly.
- **Provide an example implementation of rendering** with the idea that the example should be shadowed by the application using the theme and overridden with site-specific styling.

Another way to think about this would be that the theme should implement the data model, and business logic controller, while the individual site maintains control over the view layer.

As a result, in the theme's *gatsby-node.js* file, we have code that implements Gatsby's `createPages` API for blog posts. This is logic that we want to be the same for every site implementing a blog. Here's a simplified example:

```js
exports.createPages = async ({ graphql, actions, reporter }) => {
  const { createPage } = actions;
  const result = await graphql(`
    {
      allNodeBlogPost(sort: {fields: [created], order: DESC}) {
        edges {
          node {
            drupal_id
            title
            path {
              alias
            }
          }
        }
      }
    }
  `);

  if (result.errors) {
    reporter.panicOnBuild(`Error while running GraphQL query for blog posts.`);
    return
  }

  // Create individual blog pages.
  const blogPageComponent = require.resolve('./src/templates/blog-page.js');

  posts.forEach(({ node }, index) => {
    // Figure out previous and next posts and add them to the pageContext so
    // we can provide navigation.
    const nextPost = index === 0 ? false : posts[index - 1].node;
    const previousPost = index === posts.length - 1 ? false : posts[index + 1].node;

    createPage({
      path,
      component: blogPageComponent,
      context: {
        drupal_id: node.drupal_id,
        previous_id: previousPost.drupal_id,
        next_id: nextPost.drupal_id,
      },
    });
  });
};
```

The final version also contains logic for handling redirects, pagination, and more. This code ultimately ends up being a mapping between Drupal's way of handling data, and Gatsby.

Then, in *src/templates/blog-pages.js* (the component used to render a page), we query GraphQL for the complete set of data we need for a blog post, mutate it to something a bit friendlier, and ultimately pass it as props to a component whose sole job is rendering.

```js
import React from 'react';
import { graphql } from 'gatsby';

import BlogPostTemplate from '../components/Blog/BlogPostTemplate';

/**
  * Wrapper around the <BlogPostTemplate /> component to message the data we get
  * from Drupal before passing it along. The intent is that you should not need
  * to override this component and if you want to change the way a blog post
  * looks you can shadow the template component.
  */
const BlogPostTemplateWithData = (props) => {
  if (props.data.post.relationships.image == null) {
    props.data.post.relationships.image = [];
  }

        // Simplify the data structure returned from GraphQL.
  const post = {
    title: props.data.post.title,
    author: props.data.post.relationships.uid.display_name,
    path: props.data.post.path.alias,
    summary: props.data.post.summary.processed,
    body: props.data.post.body.processed,
    created: props.data.post.created,
    images: props.data.post.relationships.image,
    timeToComplete: null,
  };

  let previousPost;
  if (props.data.previousPost) {
    previousPost = {
      title: props.data.previousPost.title,
      author: props.data.previousPost.relationships.uid.display_name,
      path: props.data.previousPost.path.alias,
      summary: props.data.previousPost.summary.processed,
      created: props.data.previousPost.created,
      timeToComplete: null,
    };
  }

  let nextPost;
  if (props.data.nextPost) {
    nextPost = {
      title: props.data.nextPost.title,
      author: props.data.nextPost.relationships.uid.display_name,
      path: props.data.nextPost.path.alias,
      summary: props.data.nextPost.summary.processed,
      created: props.data.nextPost.created,
      timeToComplete: null,
    };
  }

  // Use the BlogPostTempalte (or shadowed varient) to render the content.
  return (
    <BlogPostTemplate
      previousPost={(previousPost ? previousPost : false)}
      nextPost={(nextPost ? nextPost :false)}
      {...post}
    />
  );
};

export default BlogPostTemplateWithData;

export const query = graphql`
  fragment drupalFields on node__blog_post {
    drupal_id
    drupal_internal__nid
    title
    created(formatString: "MMM. Mo, YYYY")
    path {
      alias
    }
    summary {
      processed
    }
    relationships {
      uid {
        display_name
      }
    }
  }
  query BlogPost($drupal_id: String!, $next_id: String, $previous_id: String) {
    post: nodeBlogPost(drupal_id: { eq: $drupal_id }) {
      body {
        processed
      }
      relationships {
        image {
          relationships {
            imageFile {
              localFile {
                childImageSharp {
                  fluid(maxWidth: 1280) {
                    ...GatsbyImageSharpFluid
                  }
                }
              }
            }
          }
        }
      }
      ...drupalFields
    }
    nextPost: nodeBlogPost(drupal_id: { eq: $next_id }) {
      ...drupalFields
    }
    previousPost: nodeBlogPost(drupal_id: { eq: $previous_id }) {
      ...drupalFields
    }
  }
`;
```

This line `import BlogPostTemplate from '../components/Blog/BlogPostTemplate';` imports the component responsible for doing the rendering. The one we include in the theme is intended as a super basic example. Where this gets really powerful is that in the project that implements the theme, like this site, we can shadow that component and provide a site-specific display of a blog post — while still sharing the complicated business logic among all our sites.

You can see the complete code here: [https://github.com/OsioLabs/gatsby-theme-osiolabs-drupal-blog](https://github.com/OsioLabs/gatsby-theme-osiolabs-drupal-blog). Caveat, this probably won't work as-is for just any site (I'm still figuring out how to untangle some of the dependencies), but it's a good starting point if you want to try something similar.

So far this has been working out really well. In fact, it took me a whole lot longer to write up this blog than it did to `npm install` the theme, configure it, and shadow a couple of components to wrap them with the main layout component for this site.

Something I would like to spend some more time learning about is [latent component shadowing](https://johno.com/latent-component-shadowing), which seems to be a similar approach to above, though perhaps a bit more formalized.

## Conclusion

In order to make it quicker to add a blog to this and future sites, we create a Gatsby theme. The theme encapsulates the logic necessary to pull content for a specific consumer into Gatsby and map the data to React components for display. This lets us share much of the code among all the different blogs we need to maintain, and reduces the maintenance burden as the code would have been largely duplicated.

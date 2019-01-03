# Building Applications with Gatsby

[# summary #]
Gatsby applications are so much more than just static HTML sites. Any site you build with Gatsby is a complete progressive web application, complete with support for offline access, pre-fetching and pre-caching data, dynamic requests executed at runtime and more. Gatsby doesn't just spit out static HTML files rendered from React components. It creates a complete React application, so your Gatsby application can do anything you would do with vanilla React.

In this tutorial we'll:

- Look at how Gatsby hydrates your static HTML into a full React application
- Define two different approaches for dealing with dynamic content in a Gatsby application

By the end of this tutorial you should have a better understanding of how Gatsby infuses the static HTML it generates with React so that you can enhance your static HTML with dynamic elements. You should be able to define two different approaches for doing so, and choose the right one for your use case.
[# endsummary #]

## Goal

Understand how Gatsby hydrates your React application, and the *hybrid page* and *client only route* approaches to developing dynamic web applications with Gatsby.

## Prerequisites

- [What Is Gatsby?](/content/gatsby/what-is-gatsby.md)

## Static sites vs. Dynamic apps

It's quite difficult to define the difference between a static site and a dynamic application, or to figure out where one stops and the other begins. This is especially true when using a platform like Gatsby.

[This blog post by Dustin Schau provides some useful context](https://www.gatsbyjs.org/blog/2018-10-15-beyond-static-intro/).

In this case what we're going to be looking at when talking about "app" functionality is:

- Dynamic content: Content that is sourced and rendered at runtime vs. being statically rendered. For example, an up-to-the-minute list of Tweets with a specific hashtag, or a list of articles in your blog that is generated in real-time by querying the CMS vs. being statically rendered by Gatsby.
- User authentication and personalization: allowing users to authenticate and identify themselves, so that some or all of the page can be personalized for them. Examples include displaying a user's name and avatar, or showing authorized users private content.

## Hydration

With Gatsby, HTML, CSS, and JS are statically generated using React DOM server-side APIs and webpack. These files are then served to the user's browser, super fast, because they're static.

Then, on the client side, JavaScript is used to perform React hydration. `React.hydrate()` tells React that you’ve already got existing markup. Instead of recreating it on the client, it should preserve it and attach any needed event handlers to the existing markup. Then it should transfer rendering to the React reconciler -- at which point you've got a full client-side React application.

Once hydrated, Gatsby essentially produces the equivalent of [create-react-app](https://github.com/facebook/create-react-app). Which means, if you can do it using a standard create-react-app shell, you can do it with Gatsby too.

So, the user gets the experience of a super fast initial page load -- thanks to the static HTML. After it's loaded in the client it transforms into a progressive web application.

In our experience this is super powerful for an application where a large portion of the experience is static, and can be rendered server side, but where preserving some dynamic elements is still important. For example:

- An e-commerce app with static product pages and a dynamic shopping cart
- Media sites where some content is public and some requires authentication to view

## Two approaches to dynamic pages with Gatsby

**Hybrid pages:** One method for creating dynamic pages with Gatsby is to create pages that are mostly static with dynamic elements being filled in after the initial page load. This technique is especially useful for pages where the majority of the content on the page is the same for every user, but small parts of the page are personalized, or require user authentication.

[Learn more about building hybrid pages.](/content/gatsby-and-drupal/create-hybrid-pages.md)

**Client-only routes:** For some pages, none of the page needs to be server rendered as all data will be loaded live from your API after the user logs in. One example is a user's account page. For these pages we can tell Gatsby that this route is only relevant on the client-side and can be skipped during server-side rendering.

[Learn more about building client-only routes.](/content/gatsby-and-drupal/create-client-only-routes.md)

## Recap

Gatsby applications are more than just static assets. Using React's hydration technique after a user's browser loads the initial static assets, client-side JavaScript does the work of bootstrapping a full progressive web application environment in React. Once that's completed, you can use React to create dynamic elements within the page. Hybrid pages and client-only routes are two common ways of approaching dynamic content in a Gatsby application.

## Further your understanding

- Check out the [Gatsbyjs.org showcase](http://gatsbyjs.orghttps://www.gatsbyjs.org/showcase/?filters%5B0%5D=App&filters%5B1%5D=Learning&filters%5B2%5D=eCommerce) for examples of Gatsby projects with application-like functionality.
- [Create Hybrid Pages](/content/gatsby-and-drupal/create-hybrid-pages.md)
- [Create Client Only Routes](/content/gatsby-and-drupal/create-client-only-routes.md)
- [Authenticate Users with OAuth](/content/gatsby-and-drupal/authenticate-users-with-oauth.md)

## Additional resources

- [Webinar: Beyond Static- Building Dynamic Apps with Gatsby](https://www.gatsbyjs.com/build-apps-webinar-video/) (gatsbyjs.com)
- [React.hydarate() documentation](https://reactjs.org/docs/react-dom.html#hydrate) (reactjs.org)

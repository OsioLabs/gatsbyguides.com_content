# Deploying Your Application

[# summary #]
One of the benefits of using a tool like Gatsby that generates static files for your application is that the requirements for a hosting environment are pretty minimal. You can deploy to countless hosting solutions -- such as Netlify, Cloudfront, and GitHub Pages -- with minimal effort.

However, there are still some things we can do to improve the experience, like using CI/CD to automatically build and deploy our application when changes are merged in Git, or integration with our CMS so that when an editor adds or edits content it triggers a build of the application.

In this tutorial we'll:

- Point you towards existing documentation on deploying Gatsby applications
- Learn about ways you could trigger a build from Drupal

By the end of this tutorial you should have some ideas about how, and where, to deploy your production Gatsby application.
[# endsummary #]

## Goal

Figure out how to deploy a production build of your application, ideally automating as much of the process as possible.

## Prerequisites

- [Install and Configure Drupal](/content/gatsby-and-drupal/install-and-configure-drupal.md)

## Build a production-ready version of your application

The short version: whenever changes are made to either your application's code, or the content in your CMS, you'll want to run `gatsby build` to generate a new set of static files. Then, place the resulting files in the *public/* directory into the appropriate place in your hosting environment. Ideally, you automate as much of this as possible.

The Gatsby documentation site has tons of documentation on best-practices for working with various hosting providers, and does a good job of covering the scenario where code in your application's Git repository has changed and you want to deploy a new version. Rather then duplicate all that here, we recommend you check out the official documentation.

- [Preparing a site to go live](https://www.gatsbyjs.org/tutorial/part-eight/)
- [Deploying and Hosting](https://www.gatsbyjs.org/docs/deploying-and-hosting/)

## Automatically update content

In our application, when an editor adds or edits recipes in Drupal we need to run `gatsby build` again. This will pull in the latest recipe content, and rebuild the static files for our application using that data to ensure users see the latest recipes.

From a technical standpoint the implementation is relatively easy, though it might require some custom code on the Drupal site of things.

At a high-level you need to:

- Listen for specific actions happening in Drupal. e.g.: a node is saved, a button is clicked
- Trigger your CI/CD build process put in place above in response to that action

The right strategy for automating builds, however, depends largely on knowing your content, your workflow, and the people who will be adding/editing content. There really is no "one size fits all" approach.

Some possible solutions:

- The [Build Hooks](https://www.drupal.org/project/build_hooks) module was built specifically with Gatsby and Netlify in mind. It should work with other hosts as well. This solution provides the ability to configure a button to build on demand rather than relying on automatic builds on every update.
- Brent Robbins from ATEN has a great walkthrough of setting up Drupal to use the Webhooks module in order to ping Netlify and tell it to run your Gatsby build process whenever a node is created, updated, or deleted. Check out [Decoupled Drupal + Gatsby: Automating Deployment](https://atendesigngroup.com/blog/decoupled-drupal-gatsby-automating-deployment).

## Not every update requires a build

While automating these builds, keep in mind that not every change in Drupal will require a build. It might be okay in some circumstances for multiple edits to happen before triggering a build. Rebuilding the application can take time, especially as the amount of content grows. If we're constantly rebuilding and redeploying we might not be taking advantage of our hosting environment's CDN and caching layers.

In the example above using Webhooks, a build is triggered every time a piece of content in Drupal is saved. In our case, this is probably fine. However, that might not always be true. Consider the following examples:

- Multiple authors adding multiple recipes at the same time, or users submitting their own recipes, and anything that could result in a high number of edits being made.
- Content publication needs to be scheduled for a specific date and time
- Multiple pages need to be edited, and a preview of the resulting complete site made available prior to publication for public consumption
- Only privileged users should be able to trigger a production build

In many cases, the most elegant answer might just be the simplest. Provide users with a button they can click in the Drupal UI that triggers a build in the CI/CD system.

Given that this tends to be extremely application-specific we're not going to provide any specific examples here for now. However, if this is something you want to learn more about, let us know.

## Recap

In this tutorial we learned that Gatsby applications are comprised of static assets, and are therefore pretty straight-forward to deploy to most hosting providers. We saw that in order to ease the maintenance burden it's a good idea to set up some kind of CI/CD process for building and deploying your application when either the code or content changes. Finally, we talked a little about some of the things to keep in mind when figuring out your content deployment strategy.

## Further your understanding

- Make a list of the conditions under which you would want Drupal to trigger a deployment, and a list of conditions where you do not want it to.
- Are there elements of your CMS configuration, or the way in which people use it, that might cause thrashing from too many edits happening at once?
- Should editors be able to manually trigger a deployment without changing content? If so, what does that look like?

## Additional resources

- [Deploying and Hosting](https://www.gatsbyjs.org/docs/deploying-and-hosting/) (gatsbyjs.org)
- [Decoupled Drupal + Gatsby: Automating Deployment](https://atendesigngroup.com/blog/decoupled-drupal-gatsby-automating-deployment) (atendesigngroup.com)

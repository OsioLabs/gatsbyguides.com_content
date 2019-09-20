# Use Our Drupal Instance, or Another CMS

[# summary #]
Throughout these tutorials we use Drupal as the backend Content Management System (CMS) for our project. You can however choose to use another CMS instead, and for the most part be able to follow along with these tutorials. Gatsby mostly doesn't care where your data comes from. Once it's been consumed by Gatsby it's all the same. And that's one of the beautiful things about it.

Additionally, to make it easier to learn Gatsby without having to worry much about the CMS backend right now, we've setup a Drupal instance you can connect Gatsby to.

In this tutorial we'll:

- Explain how you can use our existing Drupal backend while learning Gatsby instead of setting up your own
- Learn about how you can easily swap out Drupal with your CMS of choice and still benefit from the content of these tutorials

By the end of this tutorial you should be able to choose the path that works best for you while following the rest of the tutorials in this series.
[# endsummary #]

## Goal

Provide some additional options for anyone who doesn't want to use Drupal, or who isn't ready to host their own Drupal instance.

## Prerequisites

While we focus on using Drupal as the backend CMS in most of the tutorials here, this is a personal decision. And you can use the same techniques we discuss with just about any CMS for which there is an existing Gatsby source plugin.

Once the data has been ingested by Gatsby, querying the internal GraphQL database works the same way regardless of where the data comes from. That means [dynamically generating pages](/content/gatsby-and-drupal/dynamically-creating-pages.md), or [creating lists of pages](/content/gatsby-and-drupal/creating-lists-of-content.md), works the same.

You can read more about why we think Drupal is a good choice in [An Introduction to Drupal for Gatsby Developers](/content/gatsby-and-drupal/what-is-drupal.md).

## Option 1: Use an existing Drupal site

Want to follow along with these tutorials, and use Drupal as the backend, but don't feel like standing up your own Drupal 8 site? No worries, we've got one you can use for testing. 

Use this if:

- You're not concerned about the CMS at this point but do want to learn about developing applications with Gatsby that source data from a CMS
- Or, you're pretty sure you want to use Drupal as your CMS, but for now you're only interested in the Gatsby side of things.

Here's the details you'll need to use our example site. Plug them in as necessary while working through code examples:

- **URL:** [http://dev-gatsby-drupal-demo.pantheonsite.io/](http://dev-gatsby-drupal-demo.pantheonsite.io/)
- **JSON API endpoint:** [http://dev-gatsby-drupal-demo.pantheonsite.io/jsonapi](http://dev-gatsby-drupal-demo.pantheonsite.io/jsonapi)
- **OAuth Client ID:** ffa31eab-16ac-40b2-99a7-46acace22766
- **OAuth Client Secret:** gatsby
- **Test username:** test_account
- **Test password:** p4ssw0rd

If you go this route you won't be able to make any changes to the Drupal backend. You can't login to the Drupal backend as an administrator and create new content or change any configuration. And you can't create new test users. This won't stop you from testing out all the features we make use of in our Gatsby application though.

## Option 2: Use your own Drupal site

You can also use an existing Drupal site, or start your own new one, to serve as the backend while following along with these tutorials. The data won't match exactly, but that's fine. The concepts are all the same, and if you're at all familiar with Drupal you should be able to identify the differences.

Use this if you:

- Already have an existing Drupal application and you want to experiment with using Gatsby. It's always more fun to learn with your own data.
- You're starting a new application, that uses Drupal as the backend, and you want to end up with a starting point for that application after completing these tutorials.

Learn more about installing and configuring Drupal in [Install and Configure Drupal](/content/gatsby-and-drupal/install-and-configure-drupal.md).

## Option 3: Use another CMS

You can also choose to use a different CMS entirely. In fact, anything with an [existing Gatsby source plugin](https://www.gatsbyjs.org/plugins/?=gatsby-source-) should work. Install the source plugin you need instead of `gatsby-source-drupal` and follow the instructions provided by the plugin to connect Gatsby with your data. Once the data is pulled into Gatsby's GraphQL store the way you access it from your React code isn't any different than how you would access data from Drupal.

*In fact, that's the beautiful part of how Gatsby's uses GraphQL!*

Use this if:

- You're already using another CMS for your data and don't plan to use Drupal

### Gotcha's

**GraphQL fields and objects will likely have different names:** The names of objects and fields available to you when querying GraphQL are going to be dependent on the source plugin you use. When using the `gatsby-source-drupal` plugin this matches the content types configured in the specific Drupal applications data model. You'll need to adjust those queries to match your data. Luckily the GraphiQL tool which Gatsby includes at http://localhost:8000/__graphql when you run `gatsby develop` makes is possible to quickly explore the GraphQL data model.

**Authorization code examples:** The code that handles user authentication will vary depending on where your user accounts live. We've used an OAuth password grant flow in this example, so in theory anything that supports OAuth authentication will work. However in practice this is likely to require a bit of tweaking if you do reuse the code we wrote to interface with something other than Drupal. That said, we've also written these tutorials with the idea that you should be able to swap in your own authentication and authorization library with minimal changes.

## Recap

In this tutorial we looked at three different possible ways to get started configuring a backend CMS to use while following along with these tutorials. This includes; Use our existing Drupal backend, setup your own Drupal instance, and choose and setup a different CMS entirely.

## Further your understanding

- What CMS or datasource are you currently using for storing the content that you're planning to use with your Gatsby application? Is there an existing `gatsby-source-*` plugin for extracting that data?
- What is the role of a source plugin?

## Additional resources

- [List of existing `gatsby-source-*` plugins](https://www.gatsbyjs.org/plugins/?=gatsby-source-)

<!-- internal -->
<!-- lint disable -->
<!-- vale off -->

Add your own notes below here about anything you want to keep track of. This is a good place for links, and your video script/notes, and that kind of fun stuff ...

# What is Gatsby?

## Summary

Gatsby ([https://www.gatsbyjs.org/](https://www.gatsbyjs.org/)) is a fun to use web application generator for [React](https://reactjs.org/) that makes it easy to create blazing fast websites. Gatsby provides a modern framework for turning content into feature-rich, visually engaging apps and websites.

In this tutorial we'll:

- Provide a brief overview of what Gatsby is
- Link to lots of additional resources for exploring more about Gatsby and it's use-case

By the end of this tutorial you should have a better understanding of what Gatsby is and what you can do with it.

## Goal

Explain what Gatsby is, why you might want to use it, and what use-cases it's good for.

## Static ~~site~~ application generator

At a really high-level Gatsby is a CLI tool. written in Node, that generates static HTML and JavaScript bundles by performing server-side rendering of a React application. You give it React components, and it spits out optimized HTML files.

![Illustration showing React component being converted to static HTML.](/content/gatsby/images/gatsby-and-drupal.png)

Gatsby applications are more than just static HTML though. Using [hydration](https://medium.com/@baphemot/understanding-reactjs-data-hydration-initialization-bacbb790c7cb), after the static HTML assets are served to the user and displayed super fast. The HTML DOM is hydrated with the same React application that was used to generate the HTML in the first place. At which point it's mutated into a full progressive web application.

Through this, Gatsby can be used to create applications that handle things like user authentication and personalization, and dynamic content. Something you don't find in most "static site generators". In many ways it's like [create-react-app](https://github.com/facebook/create-react-app) with a bunch of extra features for working with content already baked in.

## Blazing fast front-end performance

Applications built with Gatsby are fast. [Blazing fast even](https://www.gatsbyjs.org/blog/2017-09-13-why-is-gatsby-so-fast/). Gatsby makes it easy to implement patterns like [PRPL](https://developers.google.com/web/fundamentals/performance/prpl-pattern/), and [blur-up images](https://jmperezperez.com/medium-image-progressive-loading-placeholder/), and more, that make modern front-end applications super fast.

In fact, Gatsby does a good job of making it hard to create slow applications.

![Tweet from @acdlite says; Tip: When evaluating libraries check if it's blazing fast.If it's fast, but the README doesn't specify whether its fastness is blazing, keep searching. Often you can find a similar library that does the same thing, but blazingly. Blazing means good.](/content/gatsby/images/acdlite-tweet.png)

Gatsby does a ton of things for you automatically, so you don't have to worry about implementing best practices like the following yourself:

- Route based code-splitting
- Inlining critical resources
- Pre-fetch/pre-cache routes
- Image optimizations
- Service workers for offline support
- And much more

Most of this is done behind the scenes for you. And, in many cases as new techniques become available Gatsby will be able to implement them, and use them in your application, without you having to do anything.

## A view layer for your data

At it's core, Gatsby uses a system for extracting data from sources like Drupal, Markdown files, or your API of choice, and then using that data to generate static pages at build time. The technique allows for many of the benefits of both static sites (speed, ease of deployment, etc.) and those built using a content management system (easy to update, user friendly editorial interface, and more).

![Illustration showing screenshots of a markdown document and a rendered HTML document implying that  Gatsby can convert one to the other.](/content/gatsby/images/gatsby-markdown.png)

Using source plugins to perform an [extract, transform, load](https://en.wikipedia.org/wiki/Extract,_transform,_load) process Gatsby can ingest content from anywhere into it's own GraphQL database. Which in turn gives you a unified method for accessing the data your application needs. It's a powerful concept, and one of the things that really makes Gatsby stand out.

It also frees you up to use your favorite tool, or tools, for managing your applications content. Or even to work on the two applications independent of one another. Think of Gatsby as a way to build a front-end for all of your data no matter where it lives.

## A modern tool chain

Gatsby developers use Node.js, React, GraphQL, and Webpack to define their application. Gatsby provides an exceptionally good developer experience with hot reloading, debugging tools, and a tool chain that allows you to iterate faster.

## Gatsby around the web

Rather than duplicate content from elsewhere we'll instead link you to some of our favorite resources that we think do a good job explaining what Gatsby is, and why you should use it.

- [GatsbyJS — building fast modern websites with React Kyle Mathews (@kylemathews)](https://www.youtube.com/watch?v=-EftEYczRVI): A lightning talk by Gatsby's founder Kyle Mathews giving an overview of the project.
- [gatsbyjs.org](https://www.gatsbyjs.com/): The official home of the open source Gatsby project. Cotains some great getting started guides, and the official project documentation.
- [gatsbyjs.com](https://www.gatsbyjs.com/): The commercial organization supporting Gatsby's development. Their site does a good job of selling the feature set of Gatsby and providing some example use-cases for the types of things that Gatsby does really well.
- [A First Look at Gatsby, a Static Site Generator for React](https://www.youtube.com/watch?v=CSemYFzHAtU): This video from LevelUpTuts gives a great overview of Gatsby and the underlying technology.
- [Web Performance 101 — also, why is Gatsby so fast?](https://www.gatsbyjs.org/blog/2017-09-13-why-is-gatsby-so-fast/)

Check out the [Gatsby Showcase](https://www.gatsbyjs.org/showcase/) for examples of applications built with Gatsby.

## Recap

In this tutorial we got an overview of what Gatsby is, an what it does. But to really get a sense of how Gatsby could be used in your own development process we recommend diving in and building something. It doesn't take long to get a basic Gatsby application up-and-running so you can experiment on your own.

Check out the [Hello World!](/content/gatsby/hello-world.md) tutorial and get started with your first Gatsby application.

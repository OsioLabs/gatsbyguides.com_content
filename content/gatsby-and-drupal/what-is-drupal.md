# An Introduction to Drupal for Gatsby Developers

[# summary #]
Drupal is an open-source content management system with a robust set of tools for data modeling and customizing the experience of content authors and editors. It also provides a robust web services API that allows it to operate as the backend content repository for any number of front-end clients. It's also super easy to integrate with Gatsby.

In this tutorial we will:

- Learn about what Drupal is, and why it's a good choice as a CMS backend for your Gatbsy application

By the end of this tutorial you should have a better understanding of what Drupal is, and what its use-cases are.
[# endsummary #]

## Goal

Learn a little bit about what Drupal is and why it's a great choice to use as a backend for your Gatsby applications.

## Prerequisites

> Note: We originally published this as [An Introduction to Drupal for React Developers](https://reactfordrupal.com/tutorials/drupal-for-react-developers). The version below has been modified slightly to address aspects that are specific to using Gatsby to develop your React application.

[Drupal](https://www.drupal.org/) is one of the most popular open source content management systems (CMS) in the world. It's used by millions of people and organizations around the globe to build and maintain their websites. You probably use Drupal every day without knowing it, as many top businesses and government organizations use Drupal, including the Government of Australia, Red Cross, Harvard, The Economist, BBC, NBC News, Whole Foods, Cisco, Twitter, and many more.

Drupal’s standard features include easy content authoring, reliable performance, and excellent security. But what sets it apart is its flexibility; modularity is one of its core principles. Its tools help you build the versatile, structured content that dynamic web experiences need.

Started in 2000, Drupal encapsulates years' worth of lessons learned and best-practices codified, and a vibrant community of users and developers to support it. Historically Drupal has been best known for its monolithic approach to building sites, providing both the backend editorial tools, and the front end public user experience. This, however, is changing and as Drupal shifts to adopt modern API-first best practices it’s becoming a real contender for use in decoupled architectures.

Check out this [Introduction to Drupal](https://drupalize.me/guide/introduction-drupal) to learn more.

In this article we’ll explore Drupal from the perspective of a Gatsby developer looking to familiarize themselves with Drupal and its capabilities. Whether you’re evaluating Drupal as a possible CMS for your Gatsby application, or are already using Drupal and want to learn more about its value as an API-first CMS, read on.

Briefly stated, use Drupal for the backend and Gatsby for the front-end to get the best of both worlds: an interface for content creators, tailored to their needs, without developing it yourself from scratch; and the freedom to create a blazing fast front-end experience, coded exactly to your unique specifications, using all your favorite features from Gatsby.

## Why do I need a content management system (CMS)?

If your product (the thing people are coming to you for) is content, written, edited, and moderated by humans, then you’ll need to provide an interface for them to perform that work. For some of the more basic use cases you can likely get by with flat files in a Git repository, and use the web editor on GitHub or similar to allow users to edit content. But this starts to break down when your project requires:

- Complex editorial workflows
- Categorizing, highlighting, and promoting content
- Media asset management
- Managing the relationships between content and media assets
- Fine-grained permission control
- And more

A CMS like Drupal provides a web-based interface for managing your content and editorial needs. It also allows you to customize both the interface used for creating content, and the underlying data model for that content, to fit your specific use case.

Think of this as a user interface on top of the database that stores your content that you don’t need to code yourself. It exposes not only the data, but also the processes used to create it.

## Drupal is an API-first CMS

In addition to all the features listed above that you might expect from a CMS, Drupal can also provide a powerful web services API that can be used to retrieve and manage content, as well as perform all of the other actions that a CMS is expected to be able to do.

Since the release of Drupal 8 in 2015 the community has been heavily focused on improving the API features of Drupal and ensuring that all of the system’s features are available via the APIs it provides. Those might be managing users, configuring the application itself, or creating, updating, and listing content.

Combining a CMS with a full-featured API gives editorial teams a singular workflow, and interface, to produce content once, in an environment tailored to their needs, that then gets distributed efficiently to a variety of devices and online experiences. Using a [COPE](http://blog.programmableweb.com/2009/10/13/cope-create-once-publish-everywhere/) approach (Create once, publish everywhere) allows web (Gatsby) and mobile applications, desktop clients, and business partners to all access your content.

Traditionally, Drupal is used to both manage content and present it. Your entire website sort of exists inside of Drupal. Decoupled drupal – or “headless Drupal” – is when Drupal is used strictly as a content backend without the inclusion of a presentation layer. There’s no public-facing part of the installation, only the content, the administrative UI, and a web services API for accessing it. If you’re looking to use Drupal as the backend for your Gatsby application then this is what you’re looking for.

If this is what you want to do, there are [distributions](https://drupalize.me/tutorial/user-guide/understanding-distributions?p=3081) (pre-packaged versions of Drupal that consist of additional modules and initial configuration) like [Contenta CMS](http://www.contentacms.org/) and [Reservoir](https://github.com/acquia/reservoir) that provide a quicker path to using Drupal in this way. Distributions are to Drupal as Gatsby is to React applications. What you get is a bunch of best-practice configuration already in place, and some scaffolding to make it easier to quickly get your API set up.

## Modules extend, alter, and enhance core features

The base Drupal CMS, known as Drupal core, contains the code needed to run the standard CMS functionality as well as many common, but optional, features. What makes Drupal shine is the availability of [thousands of contributed modules](https://www.drupal.org/project/project_module) that can be used to alter, extend, and enhance the base CMS with all sorts of new features.

Drupal modules work much like Gatsby plugins. Rather than assume that all Drupal-based applications are going to function the same way, Drupal provides you with a set of snap-together blocks and you build the application you need. You can locate and add the additional contributed modules you need, and use the UI to integrate the functionality they provide. Doing so allows you to create the unique editorial experience that makes the most sense for your use case.

If your Gatsby application needs offline support, you use an existing plugin like `gatsby-plugin-offline` and rely on it to do the heavy lifting. Similarly in Drupal if you wanted to add the ability to allow editors to crop images based on a chosen focal point you could install the contributed [Focal Point](https://www.drupal.org/project/focal_point) module. In both cases you benefit from the existing work, and reduce the amount of time needed to complete the project.

If you can’t find a module that does exactly what you need, you (or someone else) can usually write PHP code to create a custom module that leverages existing contributed modules and focuses on just the parts that are unique to your application.

This large ecosystem of contributed modules means that Drupal can grow with you. If you need to add an ecommerce section, surveys, a discussion forum, or other features down the road you can do so without having to change to another platform or write a whole bunch of custom code. All of these features are also made available via the API.

## Data modeling tools

One of Drupal's biggest strengths is its robust suite of data modeling tools. Rather then prescribe what your content should consist of, Drupal instead provides you with a user interface for creating a data model that meets your content needs. This isn't unique to Drupal, but Drupal has been a leader in this domain for years and is particularly good at it.

Drupal defines a set of base record types (referred to as entity types) like content, configuration, user account, and vocabulary. Using the built-in tools an administrator can create variations of these record types. For example, if you were working on a site for a food magazine you might create a content type for articles, and another for recipes. At a high-level both are content, and share many things in common. But they each have a unique data model. Articles might consist of a title, a body field, a thumbnail image, and a hero image, while a recipe is composed of a name, a description, a list of ingredients, an image, and directions for cooking. These individual data points are referred to as *fields* in Drupal.

Structuring your content in this way makes it easier for editors to manage the content because it is explicit about what data should be entered, and where. This structure allows API consumers like a React application to maintain full control over the presentation, and placement, of the data. It's also beneficial to Gatsby which can infer information about relationships, and data types, when sourcing data from Drupal.

Over the years a wealth of additional tools have developed around Drupal’s core data modeling features. Contributed modules add new field types, which can be used to collect different types of data like geographic (geo) data, or give more context to existing data types. For example: the file in this field isn’t just a file, it’s an audio file, and has associated metadata like artist, track number, and album. Because they all leverage a central data modeling system, any one of these add-ons can be used with any other without fear of conflicting.

Central to a solid content architecture is the ability for one piece of content to reference another. A recipe could have an author, so instead of adding a name and email field to every recipe you could instead add an author reference field. The author reference field creates a relationship between the author and one or more recipes. A single author can be referenced from multiple recipes, and if they change their email address sometime in the future it only needs to be done in one place. Similar to a relational database, Drupal has built-in features for creating and managing these relationships. There is also support in the API for including related objects when requesting a parent object in order to help reduce the number of HTTP requests required to load and display a set of related records.

If you’re curious and want to learn more, the underlying systems within Drupal that make this possible are the Entity API and the Field API.

While many of the CMSes on the market today provide tools for creating structured data, Drupal's go far beyond the standard data types of text, number, date and time, image/file, etc. While the data stored in the database might look like a simple string of text, Drupal can be made to understand that that string is actually the ISBN number of a
book. Then it can use this knowledge to do things like present editors with an autocomplete field so they can enter the more human-friendly title of the book while the backend looks up the ISBN to store. Or, instead of just delivering the ISBN to a front end client, Drupal can first look up metadata about the book and provide the client with a JSON object containing title, author, publication data, and a thumbnail of the cover image. This reduces the amount of work content authors are required to do, and improves the editorial experience of adding information about a book.

For front-end developers this means you can structure the data, and metadata, that make up your application's content in meaningful ways, and give editors an intuitive interface for creating content via the backend UI, without having to write any code.

## Customizable publication workflows

Different applications have different content workflow needs. As your organization grows and changes your publication process is likely to evolve as well. Drupal has the ability to facilitate your unique editorial workflow, including managing drafts, review, scheduling content for publication, and then doing the same for future revisions.

Drupal core supports the creation of any number of workflow states, and the ability to define how a piece of content transitions between those states. It also supports moderation tools that allow revisions to a piece of content to go through an editorial review process before being published, while keeping the current version available. Revisions to content are tracked over time so you can review how things have changed. You define the workflow and rules, and Drupal will provide the related user interface automatically.

Contributed modules can be added to provide additional features like scheduling, syndication, access control based on workflow state, and more. Drupal’s list-building utility Views can be used to create landing pages tailored to users in different roles. Editors can see a list of all content awaiting publication, while authors can see their in-process drafts and writing assignments.

Finally, robust user roles and permissions provide granular control over what different users can, and cannot, do within the system.

## Choose the API specification that fits your needs

Drupal itself is agnostic about what format you use to represent your data in an API. Through the use of contributed modules, Drupal 8 supports numerous API specifications and data formats. Depending on your needs, and which API you're most comfortable with, you can choose the API spec that's going to work best for you.

Through the core REST module Drupal supports a pure HTTP REST implementation, and data formats like JSON, and JSON-HAL. If you already know how Drupal’s internals work, or need full control over the CMS via the API this is a great option.

When working with Gatsby and the `gatsby-source-drupal` plugin you can use the contributed  [JSON API](https://www.drupal.org/project/jsonapi) module, which outputs data in a format the Gatsby can intuitively understand and consume.

Drupal also supports non-RESTful APIs like [GraphQL](https://www.drupal.org/project/graphql), which could also be especially appealing to Gatsby developers.

Whichever flavor you choose, Drupal's ability to perform introspection on your data model via the data modeling system allows you to generate a lot of boilerplate documentation, making the task of creating and maintaining your API documentation easier. Modules like [Docson](https://www.drupal.org/project/docson) and [Open API](https://www.drupal.org/project/openapi) allow you to generate API definitions that can be used with other third party tools for documentation, automated testing, and more.

You can also choose from a variety of different client authentication methods. Drupal supports [OAuth 2](https://www.drupal.org/project/simple_oauth), session authentication, and [JWT](https://www.drupal.org/project/jwt). That combination makes it a great choice if your Gatsby application requires both content and user management.

## Drupal is open-source

As a front end developer you're likely more interested in improving the UX or performance of your application, not the implementation details of the content management system -- that's the domain of back end developers. And that's part of what makes SaaS options like Firebase or Contentful so appealing. You don't have to do anything and things mostly just work.

A lot (but certainly not all) of the popular headless CMSes are hosted SaaS solutions. That makes it super easy to get up and running, but also comes with some hidden costs, including vendor lock-in, a limited ability to customize the backend features, and a pricing model
you have no control over.

Using an open-source solution like Drupal means you’re free to move hosting providers or even host it yourself. You can customize the system to meet your exact specifications. And you can find a large community of developers to work with, should you need additional help.

If you do want a hosted solution you can choose from hosting providers like [Pantheon](https://pantheon.io/), [Acquia](https://acquia.com/), and [Amazee.io](https://amazee.io/), amongst others. They provide one-click installs, help with keeping the software up-to-date, and solid development workflows. But it’s still Drupal, and should you ever need to move to a different provider there’s nothing stopping you from doing so.

Open-source grows with you as both you and your project change.

## Community

![Members of the Drupal community.](https://reactfordrupal.com/static/drupal-community-2b9507a8e55471599ffb1825c3ace66c-9f69c.jpg) 
Photos CC BY-NC-SA 2.0 by [Amazee Labs](https://www.flickr.com/photos/amazeelabs/).

![Members of the Drupal community.](https://reactfordrupal.com/static/drupal-community-2b9507a8e55471599ffb1825c3ace66c-51f7f.jpg)

Drupal is one of the largest open source communities in the world, with over 1 million active participants who work together to improve the Drupal software, write documentation, handle security, host events, and more. The community primarily interacts online through Drupal.org and sub-sites like groups.drupal.org. In person, we connect at national, regional, and local events and meetups. Chances are there’s a Drupal meetup near you.

All development of Drupal is managed through the issue queues on Drupal.org, where you can find people working on both the core software and contributed modules. The developer community consists of volunteers as well as people who are paid by their employers or other sponsors to work on Drupal. There isn’t any one company that oversees the project, though there are many companies with a vested interest in supporting it.

The Drupal community tends to be welcoming and friendly to new people and new ideas. Given the size, and speed, of the developer community it can be a bit daunting to get started contributing. However, there are ongoing efforts to provide mentorship and assistance to anyone interested in getting involved.

## Recap

For web applications whose primary value is the content that they provide, having a content management system is essential. If using open-source software is an important part of the decision there is currently no better choice available than Drupal. Its modular system allows for the creation of unique editorial experiences, and its powerful data modeling tools ensure you can chunk and slice your data however you need to. Through add-on modules you can access that content via the API flavor of your choice.

## Further your understanding

If you want to learn more about using Drupal as a backend for your decoupled architecture here's some additional resources:

- [Decoupled Drupal](https://drupalize.me/series/decoupled-drupal) (Drupalize.Me)
- [Web Services in Drupal 8](https://drupalize.me/series/web-services-drupal-8) (Drupalize.Me)
- [How to decouple Drupal in 2018](https://dri.es/how-to-decouple-drupal-in-2018) (dri.es)
- [Introduction to decoupled Drupal presentation](https://events.drupal.org/vienna2017/sessions/introduction-decoupled-drupal) by Preston So (events.drupal.org)

# Hello World!

[# summary #]
The first step in building an application with Gatsby is getting the Gatsby CLI installed, and then using it to scaffold a "Hello World" site. Doing so will let you confirm that all the pieces are working, and give you a chance to walk through the essential components of a Gatsby application.

In this tutorial you will:

- Get Gatsby installed and confirm that it's working
- Use the `gatsby new` command to scaffold a new project
- Create a "Hello World" site that consists of two pages: a home page and an about page

Instead of going into too much detail here, we'll walk through the required steps and link to existing resources that provide in-depth information so you can explore things further.

By the end of this tutorial you will be able to create a two-page "Hello World" site using Gatsby, and you'll understand the essential pieces of any Gatsby project.
[# endsummary #]

## Goal

Create a static site with a home page and an about page using Gatsby.

## Prerequisites

- You'll want to be comfortable with command line basics.
- Installing Gatsby requires that you have either `npm` or `yarn` installed already. We'll use `npm` but either will work. Learn more about installing all of Gatsby's dependencies in the official [Set Up Your Development Environment](https://www.gatsbyjs.org/tutorial/part-zero/) tutorial.

## Install the Gatsby CLI

The Gatsby CLI can be installed by running the following `npm` command:

```shell
npm install --global gatsby-cli
```

## Test that it worked

To test whether it worked, run the command `gatsby` with no arguments. It should output the help text for the Gatsby CLI.

Example:

```shell
$ gatsby
Usage: gatsby <command> [options]

Commands:
  gatsby develop                   Start development server. Watches files, rebuilds, and hot reloads if something changes
  gatsby build                     Build a Gatsby project.
  gatsby serve                     Serve previously built Gatsby site.
  gatsby info                      Get environment information for debugging and issue reporting
  gatsby new [rootPath] [starter]  Create new Gatsby project.

Options:
  --verbose      Turn on verbose output [boolean] [default: false]
  --no-color     Turn off the color in output [boolean] [default: false]
  -h, --help     Show help  [boolean]
  -v, --version  Show version number [boolean]

Pass --help to see all available commands and options.
```

## Start a new Gatsby project

Use the `gatsby new` command to start a new Gatsby project. This will scaffold a minimum set of required files and configuration. Optionally, tell the `gatsby new` command to use one of the available [starter projects](https://www.gatsbyjs.org/docs/gatsby-starters/). For this tutorial we'll use the default starter so you can leave that argument off.

The following command will scaffold a new Gatsby project by creating the directory *gatsby-drupal/*, and then populate it using the default starter:

```shell
gatsby new gatsby-drupal
```

**Note:** If you've got `yarn` installed the `gatsby new` command will use `yarn` instead of `npm` to retrieve dependencies. Yarn is not required for Gatsby to work though.

Once that's complete you can test that it's working by running the `gatsby develop` command:

```shell
$ cd gatsby-drupal
$ gatsby develop

success open and validate gatsby-configs — 0.009 s
success load plugins — 0.218 s
success onPreInit — 0.581 s
success delete html and css files from previous builds — 0.014 s
success initialize cache — 0.017 s
success copy gatsby files — 1.007 s
success onPreBootstrap — 0.011 s
success source and transform nodes — 0.050 s
success building schema — 0.292 s
success createPages — 0.001 s
success createPagesStatefully — 0.037 s
success onPreExtractQueries — 0.000 s
success update schema — 0.083 s
success extract queries from components — 0.061 s
success run graphql queries — 0.044 s — 6/6 139.41 queries/second
success write out page data — 0.006 s
success write out redirect data — 0.001 s
⠄ onPostBootstrapdone generating icons for manifest
success onPostBootstrap — 0.217 s

info bootstrap finished - 8.437 s

  DONE  Compiled successfully in 4552ms                                                                                                              2:15:33 PM

You can now view gatsby-starter-default in the browser.

  http://localhost:8000/

View GraphiQL, an in-browser IDE, to explore your site's data and schema

  http://localhost:8000/___graphql

Note that the development build is not optimized.
To create a production build, use gatsby build

ℹ ｢wdm｣:
ℹ ｢wdm｣: Compiled successfully.
```

Once the development server is started the command will output a URL, most likely http://localhost:8000/, which you can visit in order to see your new application.

You can stop the development server by returning to the Terminal window where it is running and typing <key>CTRL</key>-<key>c</key>.

The `gatsby new` command you ran earlier should have created a bunch of standard Gatsby application-related files like so:

```txt
.
├── LICENSE
├── README.md
├── gatsby-browser.js
├── gatsby-config.js
├── gatsby-node.js
├── gatsby-ssr.js
├── node_modules [1090 entries exceeds filelimit, not opening dir]
├── package-lock.json
├── package.json
├── public
│   ├── icons
│   │   ├── icon-144x144.png
│   │   ├── ...
│   ├── index.html
│   ├── manifest.webmanifest
│   ├── render-page.js.map
│   └── static
│       └── d
├── src
│   ├── components
│   │   ├── header.js
│   │   ├── layout.css
│   │   └── layout.js
│   ├── images
│   │   └── gatsby-icon.png
│   └── pages
│       ├── 404.js
│       ├── index.js
│       └── page-2.js
└── yarn.lock
```

You can read more about the standard [Gatsby Project Structure](https://www.gatsbyjs.org/docs/gatsby-project-structure/).

With the development server running, open the file *src/pages/index.js* in your editor. Change some of the text in the file and save it. The Gatsby development server should automatically rebuild your preview and refresh the content in your browser. One of the best developer experience features of Gatsby is its hot-reloading development server and the ability to preview your changes nearly in realtime.

## Add a new page

Add a new file at *src/pages/about.js* with the following content:

```javascript
import React from 'react'
import { Link } from 'gatsby'

import Layout from '../components/layout'

const AboutPage = () => (
  <Layout>
    <h1>About</h1>
    <p>This application is a curated set of the best recipes around, carefully
      selected just for our members.</p>
    <Link to="/">Home</Link>
  </Layout>
)

export default AboutPage
```

Assuming that the `gatsby develop` server is running, when you save this file Gatsby should automatically find it, compile the updated version of your application, and make the page available to view.

Navigate to [http://localhost:8000/about](http://localhost:8000/about) in your browser to see the page you just created.

## What's going on here?

At a really high-level: Gatsby treats files within the special *src/pages/* directory as individual pages to render. The file names are translated to a route. In this case *about.js* becomes */about*. The HTML that results from rendering the React component exported by *about.js* is used to populate the route by saving it to a file like */about/index.html* which is then served to your browser.

And ta-da 🎉  you've generated a static site.

## Recap

In this tutorial we installed the Gatsby CLI, confirmed that it was working, used it to scaffold a new Gatsby project, and then ran the built-in development server so we could preview our work in near real time. Then we added a new */about* page to our project. All of this gives us a good starting point for building our Gatsby-based application and serves as a litmus test to confirm we can get all the pieces working.

## Further your understanding

- Try running the `gatsby build` command and take a look at the static HTML files it outputs.
- [The official Gatsby tutorial](https://www.gatsbyjs.org/tutorial/) (gatsbyjs.org) provides a great starting point and in-depth explanations of many of the core concepts of Gatsby. If you're new to Gatsby this should be considered required reading.

## Additional resources

- [Learn more about alternative Gatsby starters](https://www.gatsbyjs.org/docs/gatsby-starters/) (gatsbyjs.org)

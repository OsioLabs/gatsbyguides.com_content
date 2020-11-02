# Add Material UI

[# summary #]
In order to give our application some style we'll use the popular [Material UI component library](https://material-ui.com/). It's a set of React components that implement the Google Material UI design language.

Using Material UI is not required to learn how to integrate Drupal and Gatsby together, but we enjoy working with it, and it allows us to focus on the important parts of these tutorials while still being able to create an application with some basic styling.

In this tutorial we'll:

- Install the gatsby-plugin-material-ui Gatsby plugin
- Update our application's existing components to make use of the components provided by the Material UI component library

By the end of this tutorial your application should use some components from the Material UI library to give it a bit of extra style.
[# endsummary #]

## Goal

Install Material UI library and use it to provide some styling for your application.

## Install Material UI component library

The quickest way to get started using Material UI with Gatsby is via the [gatsby-plugin-material-ui plugin](https://www.gatsbyjs.org/packages/gatsby-plugin-material-ui/).

Install the plugin:

```shell
npm install --save gatsby-plugin-material-ui @material-ui/styles @material-ui/core
```

And then enable it in your _gatsby-config.js_ file:

```js
module.exports = {
  plugins: [
    'gatsby-plugin-material-ui',
    // ... additional plugin configuration ...
  ],
}
```

With the plugin enabled Gatsby will take care of all the setup required to work with [Material UI components](https://material-ui.com/), and the [Material UI styling system](https://material-ui.com/styles/basics/) which allows us to customize the look and feel of our application.

Next, we'll make use of the components provided by the Material UI library in our code. This assumes you're comfortable with [how Material UI handles styled-components](https://material-ui.com/customization/components/#1-specific-variation-for-a-one-time-situation).

Check out the [Material UI project on GitHub](https://github.com/mui-org/material-ui) and its official home page at [https://material-ui.com/](https://material-ui.com/) for more information about the library and its usage.

## Update the `Layout` component

Update the default layout component to make use of the Material UI `Container` and `Box` components to provide some basic page layout.

Update the `Layout` component in *src/components/layout.js* to match below:

```javascript
import React from 'react'
import PropTypes from 'prop-types'
import Helmet from 'react-helmet'
import { StaticQuery, graphql } from 'gatsby'
import Box from '@material-ui/core/Box';
import Container from '@material-ui/core/Container';

import Navigation from './Navigation/Navigation';

const Layout = (props) => {
  const {children} = props;

  return (
    <StaticQuery
      query={graphql`
        query SiteTitleQuery {
          site {
            siteMetadata {
              title
            }
          }
        }
      `}
      render={data => (
        <>
          <Helmet
            title={data.site.siteMetadata.title}
            meta={[
              {name: 'description', content: 'Sample'},
              {name: 'keywords', content: 'sample, something'},
            ]}
          >
            <html lang="en"/>
          </Helmet>
          <Container maxWidth="lg">
            <Navigation siteTitle={data.site.siteMetadata.title}/>
            <Box component="main">
              {children}
            </Box>
          </Container>
        </>
      )}
    />
  )
}

Layout.propTypes = {
  children: PropTypes.node.isRequired,
}

export default Layout;
```

In the above example we're importing the `Box` and `Container` components from the `@material-ui/core` package and then using them to wrap the content of every page that uses the `Layout` component.

## Add a `Navigation` component.

Add the file *src/components/Navigation/Navigation.js*. We'll use this as the header and navigation for our application:

```javascript
import React from 'react';
import { Link } from 'gatsby';
import { makeStyles } from '@material-ui/core/styles';
import AppBar from '@material-ui/core/AppBar';
import Button from '@material-ui/core/Button';
import Toolbar from '@material-ui/core/Toolbar';
import Typography from '@material-ui/core/Typography';

const useStyles = makeStyles(theme => ({
  root: {
    flexGrow: 1,
  },
  menuButton: {
    marginRight: theme.spacing(2),
  },
  title: {
    flexGrow: 1,
  },
}));

function Navigation(props) {
  const classes = useStyles();

  return (
    <AppBar position="static" className={classes.root}>
      <Toolbar>
        <Typography
          variant="h6"
          className={classes.title}
        >
          {props.siteTitle}
        </Typography>
        <div>
            <Button
              component={Link}
              to="/"
              color="inherit"
            >
              Home
            </Button>
        </div>
      </Toolbar>
    </AppBar>
  );
}

export default Navigation;
```

In the above code we:

- Use the `AppBar`, `Button`, `Toolbar`, and `Typography` components from Material UI to output a navigation bar we can use on every page.
- Then, we use the `makeStyles` function from `@material-ui/core/styles` to apply some additional tweaks to the `AppBar` component and its children via the `className` prop. You can [read more about how this works](https://material-ui.com/styles/basics/).

## Add some style to the home page

Update the home page, *src/pages/index.js*, to use the `Paper` and `Typography` components for a little extra style:

```javascript
import React from 'react'
import PropTypes from 'prop-types';
import { Link } from 'gatsby'
import { makeStyles } from '@material-ui/core/styles';
import Paper from '@material-ui/core/Paper';
import Typography from '@material-ui/core/Typography';
import Layout from '../components/layout'

const useStyles = makeStyles(theme => ({
  root: {
    padding: theme.spacing(3, 2),
  },
}));

const IndexPage = (props) => {
  const classes = useStyles();

  return (
    <Layout>
      <Paper className={classes.root}>
        <Typography variant="h2">Hi people</Typography>
        <Typography variant="subtitle1" paragraph>
          Welcome to your new Gatsby site using <a href="https://material-ui.com">Material UI</a> for the UI.
        </Typography>
        <Typography variant="subtitle1" paragraph>
          Now go build something great.
        </Typography>
        <Link to="/page-2/">Go to page 2</Link>
      </Paper>
    </Layout>
  );
};

IndexPage.propTypes = {
  classes: PropTypes.object.isRequired,
};

export default IndexPage;
```

## Recap

In this tutorial we installed the @material-ui/core component library and then made use of some of the components it provides in order to give our application a "Material UI"-like style. We'll use these components to provide UI for our application throughout the rest of this series of tutorials.

## Further your understanding

- Can you update the about page we created in the Hello World tutorial to match the styling used on the home page?
- Explore the list of available components in the [documentation for the Material UI library](https://material-ui.com/).
- We're no longer using the `Header` component from the Gatsby Default Starter. Go ahead and remove it to keep things tidy.

## Additional resources

- [https://material-ui.com/](https://material-ui.com/) 
- [https://github.com/mui-org/material-ui](https://github.com/mui-org/material-ui)

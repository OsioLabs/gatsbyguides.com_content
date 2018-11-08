# Create Client Only Routes

## Summary

For some pages none of the page needs to be server rendered as all data will be loaded live from your API after the user logs in. For example, a user account page that displays a user's personal profile and data. It's only accessible to the user, and the content is completely dynamic. Another example is the checkout funnel of an e-commerce application, the contents of your cart, and all of the payment related pages are completely dynamic and unique for each use.

In this tutorial we'll:

- Talk about the use-case for client only routes
- Use Gatsby's `createPage` API to register client only routes at build time
- Write some React components to handle routing and rendering content for client only routes

By the end of this tutorial you should know how to register one or more client only routes in your Gatsby application, and then populate them with content on the client-side when a user access that route.

## Goal

Create a user profile page that displays a user's personal information.

## Prerequisites

- [Building Applications with Gatsby](/content/gatsby/building-applications-with-gatsby.md)
- [Authenticate Users with OAuth](/content/gatsby-and-drupal/authenticate-uesrs-with-oauth.md)

In order to create client-only routes in Gatsby we need to:

- Add a new page, or pages, in *src/pages/* that will be responsible for handling any routes marked as client only.
- Use the `createPage` API in *gatsby-node.js* to declare which routes should be considered client only.
- In our example, which deals with private routes we need to define a new `PrivateRoute` component that we can use to make routes only accessible to authenticated users. This part isn't required if you're dealing with public routes.
- Define components that will render the content of these routes in the client

## Reach router

Under the hood Gatsby uses [@reach/router](https://reach.tech/router/) to handle routing within your application. Which means you can write code just like you would with any application using @react/router for application routing.

## Define your routes

Start by creating a new Gatsby page at *src/pages/user.js*. Gatsby treats any file in *src/pages/* as representative of a page, and creates a route that corresponds with the file name. In this case *user.js* maps to *localhost:8000/user*. Instead of defining a component that renders HTML though, we'll instead use the Router component to from [@reach/router](https://reach.tech/router) to delegate to another component depending on the route being used.

Example *src/pages/user.js*:

```javascript
import React from 'react';
import { Router } from '@reach/router';
import Layout from '../components/layout';
import PrivateRoute from '../components/PrivateRoute/PrivateRoute';
import Profile from '../components/Profile/Profile';

const User = () => (
  <Layout>
    <Router>
      <PrivateRoute path="/user/profile" component={Profile} />
    </Router>
  </Layout>
);

export default User;
```

This code will render a page using the standard `Layout` component. The content of the page will depend on the exact route used, and the component it maps to. In this example we're mapping the path */user/profile* to the component `Profile`.

This uses two new components, `PrivateRoute`, and `Profile` which haven't been defined just yet.

## Define a `PrivateRoute` component

In order to protect routes we define, and use, a new `PrivateRoute` component in *src/components/PrivateRoute/PrivateRoute.js*:

```javascript
import React from 'react';
import PropTypes from 'prop-types';
import { navigate } from 'gatsby';
import withDrupalOauthConsumer from '../Session/withDrupalOauthConsumer';

const PrivateRoute = ({ component: Component, location, userAuthenticated, ...rest }) => {
  if (!userAuthenticated) {
    // If we’re not logged in, redirect to the home page.
    navigate(`/`)
    return null
  }

  return <Component {...rest} />
}

PrivateRoute.propTypes = {
  component: PropTypes.any.isRequired,
}

export default withDrupalOauthConsumer(PrivateRoute);
```

This code uses the `withDrupalOauthConsumer` higher-order component to determine if the current user is logged in or not. And then conditionally renders the content of the route depending on that. If the user is authenticated render whatever component was passed in in `props.component`, if not redirect them to the front page.

## Define a `Profile` component

Define a new `Profile` component that will fetch information about the current user from Drupal and then display it.

Add the following code in *src/components/Profile/Profile.js*:

```javascript
import React from 'react';
import LinearProgress from '@material-ui/core/LinearProgress';
import Typography from '@material-ui/core/Typography';

import withDrupalOauthConsumer from '../Session/withDrupalOauthConsumer';

class Profile extends React.Component {
  state = {
    profile: false,
  }

  async componentDidMount() {
    // If we've gotten here we can assume the user is logged in since this
    // component is only ever used for authenticated users. Grab the token we
    // need to make requests to Drupal.
    const token = this.props.drupalOauthClient.isLoggedIn();

    const headers = new Headers({
      'Accept': 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
      'Authorization': `${token.token_type} ${token.access_token}`
    });

    const options = {
      method: 'GET',
      headers,
    };

    let userInfo, userData;

    // Use this endpoint to figure out the ID of the current user.
    try {
      let response = await fetch(`http://gatsby-drupal.ddev.local/oauth/debug`, options);
      userInfo = await response.json();
    } catch(err) {
      console.log(`There was an error accessing oauth/debug: ${err}`)
    }

    if (userInfo.id) {
      try {
        let response = await fetch(`http://gatsby-drupal.ddev.local/jsonapi/user/user?filter[uid][value]=${userInfo.id}`, options);
        userData = await response.json();
      } catch(err) {
        console.log(`There was an error retrieving the user's profile data: ${err}`)
      }
    }

    const profile = userData.data.shift().attributes;

    if (profile.uid == userInfo.id) {
      this.setState({profile: profile});
    }
  }

  render() {
    if (!this.state.profile) {
      return (
        <LinearProgress />
      )
    }
    return(
      <>
      <Typography variant="headline" paragraph>Hi {this.state.profile.name}, this is your profile</Typography>
      <ul>
        {
          Object.keys(this.state.profile).map(key => <li key={key}>{key}: {this.state.profile[key]}</li>)
        }
      </ul>
      </>
    );
  }
}

export default withDrupalOauthConsumer(Profile);
```

This code:

- Initially renders a progress bar
- Uses `withDrupalOauthConsumer` to gain access to the `drupalOauthClient` library.
- Retrieves information about the current user from Drupal by using the OAuth authorization token managed by `drupalOauthClient` to make authorized requests to Drupal. First one that figures out the ID of the current user based on the token used. And then another which retrieves information about the user based on their ID.
- Finally, the components state is updated with the returned data. This causes it to re-render and the content is displayed in an unordered list.

## Add a link to the user's profile

We need to provide a way to navigate to this new page. Update the `Navigation` component and add a "My Account" link for authenticated users.

In *src/components/Navigation/Navigation.js* update the code to something like the following:

```javascript
{props.userAuthenticated ?
  <>
    <Button variant="outlined" component={Link} to="/user/profile">My Account</Button>
    <LogoutLink/>
  </>
  :
  <SignIn />
}
```

This adds a new `Button` element linked to the */user/profile* route we just created.

## Make it client-only

Finally, we need to tell Gatsby the this route, /user, is a client-only route. And that is should render the application container, but doesn't need to worry about generating a static HTML asset to represent this route. This is done via the `onCreatePages` API.

Add the following to *gatsby-node.js*:

```javascript
/**
  * Implements the onCreatePage node API.
  */
exports.onCreatePage = async ({ page, actions }) => {
  const { createPage } = actions

  // page.matchPath is a special key that's used for matching pages
  // only on the client.
  if (page.path.match(/^\/user/)) {
    page.matchPath = `/user/*`

    // Update the page.
    createPage(page)
  }
}
```

This implements the `onCreatePages` API. Looks for any page whose route which matches the regular expression `/^\/user/`. So basically *user/*. And then uses the `matchPath` flag to indicate to Gatsby that this route is client only and calls `createPage` again with the updated values. `page.matchPath` tells the system that anything matching should be ignored when resolving routes during static builds, but once the application is loaded into the client should be resolved by @reach/router on the client.

## Restart Gatsby

We added a new page in *src/pages/user.js*, and in order for Gatsby to register it we need to restart the application.

You should now see a *My account* button in the navigation when you're signed in. Clicking on it should take you to a page that displays information about your user account pulled directly from Drupal.

## Recap

In this tutorial we added a client-only route to our Gatsby application. One that will have no static HTML assets generated for it, and will only ever be rendered client-side. This is accomplished by using the `onCreatePages` API to designate routes a client-only so that Gatsby skips them during static page generation. And then making use of the @reach/router routing library to handle access control and routing for the client-side only routes.

In our example we created a `PrivateRoute` component that checks a users authentication state and either renders a component or redirects the user based on that. Then we added a `Profile` component that can query the Drupal API for information about the current user and display it.

Routes created with this approach will exist on the client only and will not correspond to index.html files in an app’s built assets. If you’d like site users to be able to visit client routes directly, you’ll need to set up your server to handle those routes appropriately.

## Further your understanding

- Can you add an additional client-only route? Something like *user/login*. That when accessed displays a login form and make it only display for non-authenticated users?
- Take some time to explore the [@reach/router documentation](https://reach.tech/router) and examples
- You can also use the plugin [gatsby-plugin-create-client-paths](https://www.gatsbyjs.org/packages/gatsby-plugin-create-client-paths/) to declare client only routes. This allows you to define patterns in your *gatsby-config.js* file instead of adding code in the *gatsby-node.js* file.

## Additional resources

- [@reach/router](https://reach.tech/router)
- [https://www.gatsbyjs.org/docs/node-apis/#onCreatePage](https://www.gatsbyjs.org/docs/node-apis/#onCreatePage)
- [https://www.gatsbyjs.org/docs/behind-the-scenes-terminology/#matchpath](https://www.gatsbyjs.org/docs/behind-the-scenes-terminology/#matchpath)
# Authenticate Users with OAuth

[# summary #]
User authentication is a key component to many web applications. It allows the client application to identify the current user, and to potentially change their experience based on that information. Additionally, an authenticated user can also be authorized to perform specific actions depending on their account's permissions.

There are many different authentication and authorization patterns. OAuth is a common one, and the one we'll focus on in this tutorial. In the way we use it OAuth is similar to JSON Web Tokens (JWT), another approach commonly used with React applications. Drupal can be configured to act as the provider for both.

In this tutorial we'll:

- Define a high-level strategy for handling authentication in our application that isn't specific to any authentication mechanism
- Integrate some existing React components that manage OAuth authentication via Drupal into our application
- Verify it's working by showing/hiding a component depending on the current user's authentication state

By the end of this tutorial you'll have a better understanding of how to integrate authentication into a Gatsby application, and specifically how to authenticate users's against a Drupal OAuth provider.
[# endsummary #]

## Goal

Define `SignIn`, and `LogOutLink` components that we can use to allow users of our application to authenticate their account which is stored in Drupal.

## Prerequisites

- [Install and Configure Drupal](/content/gatsby-and-drupal/install-and-configure-drupal.md)
- [Building Applications with Gatsby](/content/gatsby/building-applications-with-gatsby.md)

## What is OAuth?

[OAuth 2](https://oauth.net/2/) is a mature open standard for token-based authentication and authorization on the Internet. OAuth 2 allows the user account information to be used by our consumers, without exposing the user's password.

One of the big benefits of OAuth 2 is that it is immensely popular. That translates into many helper libraries and third party services. That will help us build authentication in our consumer applications very quickly.

OAuth 2 will authenticate a request if that request carries a header containing a secret string that matches the records in the back end. In summary, Drupal shares a secret token with a consumer after a user has provided their credentials. After that, any request that contains that secret token can only belong to the user that Drupal shared that token with.

There are many ways to ask Drupal to generate a token, in accordance with the OAuth 2 specification. In all cases the sequence is:

1. A user provides their username and password to prove that they are who they claim to be.
2. The OAuth provider generates a secret random token and stores it in the database associated to that user ID. Tokens are stamped with an expiration date, after which the token is useless.
3. The provider returns the token to the consumer. The consumer stores that token.
4. The consumer makes as many requests as it needs to as an authenticated user by providing the token every time.

[An Introduction to OAuth 2](https://www.digitalocean.com/community/tutorials/an-introduction-to-oauth-2) by Digital Ocean provides a comprehensive overview.

## Handling OAuth with React

Our focus with this tutorial is on integrating OAuth into a Gatsby application, not on the specifics of handling the OAuth handshake. So we'll make use of some existing code which you can read through and explore on your own if you're curious. You can grab the code from [the example repository](https://github.com/LullabotEducation/gatsby-drupal-examples/tree/authenticate-users-with-oauth/src/components/drupal-oauth).

Here's what's in it:

- *drupalOauth.js*: Contains the `drupalOauth` class. A utility library for dealing with the low-level elements of the OAuth flow including exchanging a username and password for an authorization token, storing the token in local storage, refreshing an expired token, checking a user's current authentication state, and retrieving a token for use in authenticating other `fetch` requests.
- *DrupalOauthContext.js*: Define a new React context component that will manage an instance of `drupalOauth` and make it available to any component that needs it.
- *withDrupalOauthConsumer.js*: Provides the `widthDrupalOauthConsumer` higher-order component for use when another component needs to gain access to DrupalOauthContext data. Adds userAuthenticated, drupalOauthClient, and updateAuthenticatedUserState props to wrapped components.
- *withDrupalOauthProvider.js*: Provides the `withDrupalOauthProvider` higher-order compoment. Assists in initializing a DrupalOauthContext provider.

Place all of these files in the *src/components/drupal-oauth/* directory in your application.

## Initialize an OAuth context provider

We'll use the React context API to keep track of the current user's authentication state. Which will allow us to wrap any component in our application using `withDrupalOAuthConsumer`, and quickly check via the `props.userAuthenticated` parameter wether the current user is authenticated or not. And then vary what the component renders as necessary.

In order to do this we need to initialize the context provider. In *src/components/layout.js* we need to add the following code:

```javascript
import drupalOauth from '../components/drupal-oauth/drupalOauth';
import withDrupalOauthProvider from '../components/drupal-oauth/withDrupalOauthProvider';

// Initialize a new drupalOauth client which we can use to seed the context
// provider.
const drupalOauthClient = new drupalOauth({
  drupal_root: 'http://gatsby-drupal.ddev.local',
  client_id: '448d13ae-c82c-4401-863d-a2d95554ecaa',
  client_secret: 'gatsby',
});

// ... component definition goes here ...

const LayoutWithStyles = withRoot(withStyles(styles)(Layout));
export default withDrupalOauthProvider(drupalOauthClient, LayoutWithStyles);
```

There's a bit of extra code here handling integration with the Material UI library, but the important parts of what's going on here are:

- Importing the `drupalOauth` class and `withDrupalOauthProvider` component
- Initializing a new instance of the `drupalOauth` class and providing the necessary information to connect to our Drupal Oauth server. We configured this in [Install and Configure Drupal](/content/gatsby-and-drupal/install-and-configure-drupal.md). This instance of the `drupalOauth` client will be injected into the React DrupalOauthContext so that components consuming that context will have access to the utility class and the methods it provides. This makes it easier for components to use the utility class without also having to initialize it first, and for maintenance purposes allows us to just configure the client once.
- Finally, we wrap the primary component using `withDrupalOauthProvider`, which takes two arguments; An instance of `drupalOuath` and the component to wrap.

## Define a `SignIn` component

Next, we'll need a way to let users provide their username and password, and then use those to authenticate the user. To do this we define a new `SignIn` component which display a form. When the form is submitted we attempt to authenticate the user and update the applications state accordingly.

This component will render a button, which when clicked will display a modal dialog containing a log in form. Example:

![](/content/gatsby-and-drupal/images/signin-component-example.png)

Add the file *src/components/SignIn/SignIn.js*:

```javascript
import React from 'react';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogContentText from '@material-ui/core/DialogContentText';
import DialogTitle from '@material-ui/core/DialogTitle';
import CircularProgress from '@material-ui/core/CircularProgress';

import withDrupalOauthConsumer from '../Session/withDrupalOauthConsumer';

class SignIn extends React.Component {
  state = {
    open: false,
    processing: false,
    username: '',
    password: '',
    error: null,
  };

  handleClickOpen = () => {
    this.setState({ open: true });
  };

  handleCancel = () => {
    this.setState({ open: false });
  };

  handleSubmit = () => {
    this.setState({ processing: true });
    const { username, password } = this.state;

    this.props.drupalOauthClient.handleLogin(username, password, '').then(() => {
      this.setState({ open: false, processing: false });
      this.props.updateAuthenticatedUserState(true)
    });    
  };

  render() {
    const { error, processing } = this.state;

    return (
      <>
        <Button onClick={this.handleClickOpen} variant="contained" color="primary">Log in</Button>
        <Dialog
          open={this.state.open}
          onClose={this.handleClose}
          aria-labelledby="form-dialog-title"
        >
          <DialogTitle id="form-dialog-title">Log in</DialogTitle>
          <DialogContent>
            {error && <p>{error.message}</p>}
            <DialogContentText>
              Enter your username and password below to log in.
            </DialogContentText>
            <TextField
              autoFocus
              margin="dense"
              name="username"
              label="Username"
              type="text"
              fullWidth
              onChange={event =>
                this.setState({ [event.target.name]: event.target.value })
              }
            />
            <TextField
              margin="dense"
              name="password"
              label="Password"
              type="password"
              fullWidth
              onChange={event =>
                this.setState({ [event.target.name]: event.target.value })
              }
            />
          </DialogContent>
          <DialogActions>
              <Button onClick={this.handleCancel} color="default">
                Cancel
              </Button>
              {
                processing ?
                  <CircularProgress />
                  :
                  <Button onClick={this.handleSubmit} color="primary" variant="contained">
                    Log in
                  </Button>
              }
          </DialogActions>
        </Dialog>
      </>
    );
  }
}

export default withDrupalOauthConsumer(SignIn);
```

This code follows a [fairly standard pattern](https://reactjs.org/docs/forms.html) for defining a form component, and uses components from the Material UI library for styling. The most interesting parts here are:

- The entire component is wrapped with `withDrupalOauthConsumer` which gives us `this.props.drupalOauthClient` , and `this.props.updateAuthenticatedUserState` from the DrupalOauthContext provider we initialized in *layout.js*.
- In the `handleSubmit()` method we use `this.props.drupalOauthClient.handleLogin(username, password, scope)` which handles the heavy lifting required to make a request to the Drupal OAuth server attempting to exchange a username and password for an authorization token. If that request succeeds it stores the token in local storage for later use. We then call `this.props.updateAuthenticatedUserState(true)` which updates the state variable in the DrupalOauthContext provider. That update will bubble out to any other component using the context provider and trigger a re-render in those components so our application will update almost instantly to reflect that a user is now logged in.

## Define a logout link

We also need to allow users to log out. So we'll define a new `LogoutLink` component we can use for that.

In *src/components/LogoutLink/LogoutLink.js*:

```javascript
import React from 'react';
import Button from '@material-ui/core/Button';

import withDrupalOauthConsumer from '../Session/withDrupalOauthConsumer';

const LogoutLink = (props) => {
  if (props.drupalOauthClient) {
    return(
        <Button
        variant="outlined"
        onClick={async () => {
          await props.drupalOauthClient.handleLogout();
          props.updateAuthenticatedUserState(false);
        }}
      >
        Log out
      </Button>
    );
  }

  return('');
};

export default withDrupalOauthConsumer(LogoutLink);
```

This code does the following:

- Similar to the `SignIn` component, we use `withDrupalOauthConsumer` to gain access to the `handleLogout()` and `updateAuthenticatedUserState()` functions we need to do the heavy lifting.
- When a user clicks the button, we first call `props.drupalOauthClient.handleLogout()` which deletes the authorization token in local storage, effectively logging them out. And then call `props.updateAuthenticatedUserState(false)` which updates the application state to reflect the change.

## Update the navigation

With these two components defined, we can update the `Navigation` component. The objective is to render the `SignIn` component for users who are not currently authenticated. And the `LogoutLink` component for those who are.

In *src/components/Navigation/Navigation.js* import the components we need:

```javascript
import withDrupalOauthConsumer from '../Session/withDrupalOauthConsumer';
import SignIn from '../SignIn/SignIn';
import LogoutLink from '../LogoutLink/LogoutLink';
```

Then update the export statement to wrap the existing `Navigation` component with `withDrupalOauthConsumer` which will give us access to `props.userAuthenticated`.

```javascript
export default withStyles(styles)(withDrupalOauthConsumer(Navigation));
```

Finally, update the `Navigation` component so that it checks to see if the user is authenticated, and renders either a `SignIn`, or a `LogoutLink` depending on the state:

```javascript
{props.userAuthenticated ?
  <>
    <LogoutLink/>
  </>
  :
  <SignIn />
}
```

This pattern can be used anytime you want to conditionally display something depending on wether the current user is authenticated or not.

- Import the require components
- Wrap the component you want to update with the `widthDrupalOauthConsumer` HOC
- Use the value of `props.userAuthenticated` to determine what to render

Try it out! You should be able to login now using any Drupal user's username and password. When you log in you should be able to see the authorization token stored in local storage. And the application should update so that the navigation displays a log out link.

## Recap

In this tutorial we added the ability for users to log in, and out, of our application. We started with some generic code for performing the OAuth handshake between React and Drupal in a React friendly way. Then, we defined two new components; `SignIn`, and `LogoutLink` which make use of that code to add a sign in form and log out link to our application. Finally, we updated the `Navigation` component so that it will display either a `SignIn` or a `LogoutLink` depending on the current users authentication state. 

## Further your understanding

- This current setup lacks robust error handling. Can you update your application so that when the `drupalOauth.handleLogin()` call fails it displays a message to the user letting them know?
- A good alternative to OAuth is [JWT](https://tools.ietf.org/html/rfc7519) ([tools.ietf.org](http://tools.ietf.org/))

## Additional resources

- [Gatsby Authentication Demo](https://github.com/gatsbyjs/gatsby/tree/master/examples/simple-auth) (github.com)
- [Making a site with user authentication](https://www.gatsbyjs.org/docs/authentication-tutorial/) (gatsbyjs.org)
- [Gatsby Mail](https://github.com/DSchau/gatsby-mail) is an application that demonstrates authentication with the Context API similar to this tutorial (github.com)

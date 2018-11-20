# Create Hybrid Pages

## Summary

One method for creating dynamic pages with Gatsby is to create pages that are mostly static with dynamic elements being filled in after the initial page load. This technique is especially useful for pages where the majority of the content on the page is the same for every user, but small parts of the page are personalized, or require user authentication.

In this tutorial we'll:

- Update our Drupal applications configuration to restrict access to some recipe data to authenticated users only
- Modify our Gatsby application so that anonymous users see a teaser of each recipe, while authenticated users get full access all of the recipes details

By the end of this tutorial you should know how to build pages that protect access to some content, as well has have a better understanding of the hybrid pages approach to building dynamic content pages in Gatsby.

## Goal

Modify our application so that recipe pages require a user to sign in before they can view a complete recipe.

## Prerequisites

- [Building Applications with Gatsby](/content/gatsby/building-applications-with-gatsby.md)
- [Authenticate Users with OAuth](/content/gatsby-and-drupal/authenticate-uesrs-with-oauth.md)

## What we're building

In this example we're going to update our application so that a user must sign in before they can view a complete recipe. Non-authenticated users will get a preview of the recipe (statically rendered), but not be able view the complete recipe.

This requires:

- Creating a new `RecipeTeaser` component to use for non-authenticated users
- Updating configuration in Drupal so that the ingredients and instructions fields are protected and require authentication to view. This will make them no-longer publicly accessible via the API, and users will have to authenticate first before they can access that content. Gatsby will always run it's build process as an anonymous user, and thus the protected fields will not be available in Gatsby's GraphQL database.
- Updating the `Recipe` component to make an authenticated `fetch()` request directly to the Drupal API in order to access protected content, and then display it
- Updating the *src/templates/recipe.js* template so that it it displays the `RecipeTeaser` component for non-authenticated users, and the `Recipe` component for authenticated users

Let's get to it.

## Update Drupal to protect access to some recipe fields

We need to update Drupal so that certain fields on the Recipe content type require a user be authenticated in order to view them. This ensures that someone can't just bypass our client application and make requests to the API directly to gain access to protected content.

Install the [Field Permissions module](https://www.drupal.org/project/field_permissions) which will allow us to restrict access to specific fields on an entity:

```shell
composer require drupal/field_permissions
```

And then enable it via the Drupal UI.

Once it's enabled in the *Manage* administration menu navigate to *Structure* > *Content types* > *Recipe* > *Manage fields* then edit both the *Ingredients* and *Recipe instructions* fields.

For each field, in the new *Field visibility and permissions* section added by the field permissions module select *Custom permissions* and then give the *Authenticated User* role the "View anyone's value for field field_ingredients" permission. And give *Author* and *Editor* permission to create and edit values for the field. Then click *Save settings*.

![Screenshot of form showing field permissions configured for the recipe instructions field](/content/gatsby-and-drupal/images/field_permissions-example.png)

This ensures that the content of these fields is only visible to authenticated users. So when someone queries the API for a recipe if they are an anonymous user these fields will not be in the returned object. However, if they authenticate with OAuth, and the API request contains the authorization token, the content will be present.

It's also worth noting that Gatsby's source plugin will no longer see these fields as Gatsby acts as an anonymous user. So if you want to use the content in your application at any point you'll have to query the API for it directly. Which is of course exactly what we want in order to protect the content. If you have these fields in your GraphQL query in the recipe template you'll need to remove them or you'll get an error when trying to build your application.

## Create a `RecipeTeaser` component

The first thing we'll do is create a new `RecipeTeaser` component. This will display the portion of a recipe that is public, as well as a call to action for user's to sign in to view the rest of the recipe. Once updated, Gatsby will use this component when rendering the static HTML version of this hybrid page.

Example:

![Screenshot of the recipe teaser component showing a call to action element with a login button.](/content/gatsby-and-drupal/images/recipe-teaser-example.png)

Create the file *src/components/RecipeTeaser/RecipeTeaser.js*:

```javascript
import React from 'react';
import PropTypes from 'prop-types';
import Img from 'gatsby-image';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import GridList from '@material-ui/core/GridList';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';
import Typography from '@material-ui/core/Typography';
import { withStyles } from '@material-ui/core/styles';
import RecipeList from '../RecipeList/RecipeList';
import SignIn from '../SignIn/SignIn';

const styles = theme => ({
  cta: {
    margin: '2em 0',
    padding: '1em',
    background: '#ececec',
    border: '1px solid #999',
  },
  ctaSignIn: {
    display: 'inline',
  },
  recipeList: {
    marginTop: '2em',
  }
});

const RecipeTeaser = (props) => (
  <>
    <Img fluid={props.image.localFile.childImageSharp.fluid} />
    <Typography variant="headline" paragraph>{props.title}</Typography>
    <GridList cols="5" cellHeight="auto">
      <ListItem>
      <ListItemText primary="Difficulty" secondary={props.difficulty} />
    </ListItem>
    <ListItem>
      <ListItemText primary="Cooking time" secondary={`${props.cooking_time} minutes`} />
      </ListItem>
      <ListItem>
        <ListItemText primary="Preparation time" secondary={`${props.preparation_time} minutes`} />
      </ListItem>
      <ListItem>
      <ListItemText primary="Category" secondary={props.category} />
    </ListItem>
    {props.tags &&
    <ListItem>
      <ListItemText primary="Tags" secondary={props.tags.map(item => item.name)}/>
    </ListItem>
    }
    </GridList>

    <Typography variant="subheading">Summary:</Typography>
    <Typography variant="body2" paragraph dangerouslySetInnerHTML={{ __html: props.summary }} />

    <Card raised={true}>
      <CardContent>
        <Typography variant="body" component="strong">
          <SignIn /> to view the complete content of this recipe.
        </Typography>  
      </CardContent>
    </Card>

    <div className={props.classes.recipeList}>
      <Typography variant="subheading">Try another recipe:</Typography>
      <RecipeList />
    </div>
  </>
);

RecipeTeaser.propTypes = {
  title: PropTypes.string.isRequired,
  difficulty: PropTypes.string.isRequired,
  cooking_time: PropTypes.number.isRequired,
  preparation_time: PropTypes.number.isRequired,
  summary: PropTypes.string.isRequired,
  category: PropTypes.string.isRequired,
  tags: PropTypes.array,
};

export default withStyles(styles)(RecipeTeaser);
```

This is basically just a copy of the code from *src/components/Recipe/Recipe.js*. And will be used to render the static, non-authenticated user, view of a recipe. The biggest difference is the addition of a call-to-action to log in to view the complete recipe.

## Update the existing `Recipe` component

Use `withDurpalOauthConsumer` higher-order component to gain access to the `drupalOauth` class. Then in an implementation of the `componentDidMount` lifecycle method, use `fetch()` to make an authenticated request to the Drupal API for the recipe in question. The result will contain the protected fields, which we can display for authenticated users.

Here's the complete code for the updated *src/components/Recipe/Recipe.js* file:

```javascript
import React from 'react';
import PropTypes from 'prop-types';
import Img from 'gatsby-image';
import GridList from '@material-ui/core/GridList';
import LinearProgress from '@material-ui/core/LinearProgress';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';
import Typography from '@material-ui/core/Typography';
import { withStyles } from '@material-ui/core/styles';
import RecipeList from '../RecipeList/RecipeList';

import withDrupalOauthConsumer from '../drupal-oauth/withDrupalOauthConsumer';

const styles = theme => ({
  progressBar: {
    margin: '2em 0',
  }
});

class Recipe extends React.Component {
  state = {
    ingredients: [],
    instructions: '',
  };

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

    const url = `http://gatsby-drupal.ddev.local/jsonapi/node/recipe/${this.props.uuid}`
    
    let data;
    try {
      let response = await fetch(url, options);
      data = await response.json();

      // Validate the response.
      if (data === null || data.data === undefined || data.data === null) {
        throw new Error('No valid data received from the API.');
      }
    } catch(err) {
      console.log(`API error: ${err}`);
    }

    this.setState({
      ingredients: data.data.attributes.field_ingredients,
      instructions: data.data.attributes.field_recipe_instruction.processed,
    })
  }

  render() {
    const {classes} = this.props;

    return (
      <>
        <Img fluid={this.props.image.localFile.childImageSharp.fluid} />
        <Typography variant="headline" paragraph>{this.props.title}</Typography>
        <GridList cols="5" cellHeight="auto">
          <ListItem>
          <ListItemText primary="Difficulty" secondary={this.props.difficulty} />
        </ListItem>
        <ListItem>
          <ListItemText primary="Cooking time" secondary={`${this.props.cooking_time} minutes`} />
          </ListItem>
          <ListItem>
            <ListItemText primary="Preparation time" secondary={`${this.props.preparation_time} minutes`} />
          </ListItem>
          <ListItem>
          <ListItemText primary="Category" secondary={this.props.category} />
        </ListItem>
        {this.props.tags &&
        <ListItem>
          <ListItemText primary="Tags" secondary={this.props.tags.map(item => item.name)}/>
        </ListItem>
        }
        </GridList>

        <Typography variant="subheading">Summary:</Typography>
        <Typography variant="body2" paragraph dangerouslySetInnerHTML={{ __html: this.props.summary }} />

        {this.state.instructions !== '' ?
          <>
            <Typography variant="subheading">Ingredients:</Typography>
            <List dense={true}>
              {
                this.state.ingredients.map(item => <ListItem key={item}>{item}</ListItem>)
              }
            </List>

            <Typography variant="subheading">Preparation:</Typography>
            <Typography variant="body2" paragraph dangerouslySetInnerHTML={{ __html: this.state.instructions }} />
          </>
          :
          <LinearProgress className={classes.progressBar} />
        }

        <Typography variant="subheading">Try another recipe:</Typography>
        <RecipeList/>
      </>
    )
  }
}

Recipe.propTypes = {
  title: PropTypes.string.isRequired,
  difficulty: PropTypes.string.isRequired,
  cooking_time: PropTypes.number.isRequired,
  preparation_time: PropTypes.number.isRequired,
  summary: PropTypes.string.isRequired,
  category: PropTypes.string.isRequired,
  tags: PropTypes.array,
};

const RecipeWithStyles = withStyles(styles)(Recipe);

export default withDrupalOauthConsumer(RecipeWithStyles);
```

The biggest changes include:

- Using `withDrupalOauthConsumer`
- Adding the `async componentDidMount() {}` method. In which we use `const token = this.props.drupalOauthClient.isLoggedIn();` to get an OAuth token for the current user, and then add an `'Authorization': `${token.token_type} ${token.access_token}`` header to the `fetch()` request to get more information about the Recipe.
- When the component initially renders we display a placeholder with a progress indicator to let the user know more content is loading. Then, when the `fetch()` request completes we use the data returned to update the ingredients and preparation instructions in the components state. This causes a re-render, and now we display the new content instead of the placeholder.

## Update the recipe template

Finally, the last step is to update the page template in *src/templates/recipe.js* to make use of our new components.

The updated component in *src/templates/recipe.js* looks like this:

```javascript
import React from 'react';
import { graphql } from 'gatsby';
import Helmet from 'react-helmet';
import Layout from '../components/layout';
import Recipe from '../components/Recipe/Recipe';
import RecipeTeaser from '../components/Recipe/RecipeTeaser';
import Paper from '@material-ui/core/Paper';
import { withStyles } from '@material-ui/core/styles';

import DrupalOauthContext from '../components/drupal-oauth/DrupalOauthContext';

const styles = theme => ({
  root: {
    ...theme.mixins.gutters(),
    paddingTop: theme.spacing.unit * 2,
    paddingBottom: theme.spacing.unit * 2,
  },
});

const recipeTemplate = (props) => {
  const { classes } = props;
  const { nodeRecipe: recipe } = props.data;

  const recipeClean = {
    uuid: recipe.uuid,
    title: recipe.title,
    difficulty: recipe.difficulty,
    cooking_time: recipe.cooking_time,
    preparation_time: recipe.preparation_time,
    category: recipe.relationships.category[0].name,
    tags: recipe.relationships.tags,
    summary: recipe.summary.processed,
    image: recipe.relationships.image,
  };

  return (
    <Layout>
      <Helmet
        title={`Umami - ${recipe.title}`}
        meta={[
          {name: 'description', content: recipe.title},
        ]}
      />
      <Paper className={classes.root}>
        <DrupalOauthContext.Consumer>
          {({userAuthenticated}) => (
            userAuthenticated ? <Recipe {...recipeClean} /> : <RecipeTeaser {...recipeClean} />
          )}
        </DrupalOauthContext.Consumer>
      </Paper>
    </Layout>
  )
};

export default withStyles(styles)(recipeTemplate);

// The $uuid variable here is obtained from the "context" object passed into
// the createPage() API in gatsby-node.js.
//
// Also note the use of field name aliasing in the query. This is done to
// help normalize the shape of the recipe data.
export const query = graphql`
  query RecipeTemplate($uuid: String!) {
    nodeRecipe(uuid: {eq: $uuid}) {
      uuid,
      title,
      cooking_time: field_cooking_time,
      difficulty: field_difficulty,
      preparation_time: field_preparation_time,
      number_of_servings: field_number_of_servings,
      summary: field_summary {
        processed,
      },
      relationships {
        category: field_recipe_category {
          name,
        }
        tags: field_tags {
          name,
        }
        image: field_image {
          localFile {
            childImageSharp {
              fluid(maxWidth: 1100) {
                ...GatsbyImageSharpFluid
              }
            }
          }
        }
      }
    }
  }
`;
```

In this updated code we:

- Use `DrupalOauthContext.Consumer` to detect wether the current user is authenticated or not.
- Depending on the result of that check we either display the `Recipe` component or the `RecipeTeaser` component. Because it's based on the userAuthenticated state variable in our context component whenever that state is updated it'll switch to the appropriate component here automatically.

## Test it out

In your application navigate to a recipe page. You should see the teaser version of the recipe provided by the `RecipeTeaser` component. Next, sign in as an authorized users. When the sign in process completes the page should update automatically and display the content of the `Recipe` component. Which, will request the protected data directly from the Drupal API and display it.

## Advantages of the hybrid page approach

- For anon users we're display static pages. These remain super fast.
- For authenticated users we display an initial static page super quickly, which contains most of the page data, then in the background load and populate the protected information. This gives the perception of pages loading quickly, and in many cases will give access to critical information before the API request has even completed.

## Recap

In this tutorial we updated our Drupal application to restrict access to some of the fields on the Recipe content type. Then, we modified our Gatsby application so that we display a different component to users viewing a recipe depending on their authentication status. Finally, we updated the `Recipe` component to make use of the OAuth token for the current user to make an authenticated request directly to the Drupal API. This returns the recipe content, including the protected fields, and we can display them for the user.

By doing this we've created a system where access to some of the content in our application is restricted to only users who have an account, and who are authorized to view that content.

## Further your understanding

- Think about how a similar approach could be used, without authentication, to display a static list of recipes on the front-page that queries Drupal at runtime to ensure the list is up-to-date and reconciles it if needed.
- Can you think of other examples where you might want to render a majority of the page as static content and dynamically update certain portions at runtime?
- Can you come up with examples of applications you use that do this already?

## Additional resources

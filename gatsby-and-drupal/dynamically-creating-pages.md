# Dynamically Creating Pages

[# summary #]
Now that you've got data being pulled into Gatsby's GraphQL database via one or more source plugins the next step is to use that data to dynamically generate pages at build time. In our example we're consuming a set of Recipes from our Drupal site, and now we need to generate a static HTML page for each of the N recipes.

In this tutorial we'll:

- Learn about using Gatsby's `createPages()` Node API for dynamically adding to the list of routes that Gatsby will build and statically render
- Map the results of a GraphQL query against Gatsby's database to a React template in order to generate an HTML representation of the data
- Learn about the concept of page queries in Gatsby

By the end of this tutorial you'll know how to create static pages at build time in a Gatsby application based on data sourced from Drupal. Or any other source that Gatsby supports.
[# endsummary #]

## Goal

Create static pages in Gatsby for each recipe sourced from Drupal.

## Prerequisites

- [Hello World](/content/gatsby/hello-world.md)
- [Get Data Out of Drupal and Into Gatsby](/content/gatsby-and-drupal/get-data-out-of-drupal-and-into-gatsby.md)

## What's going on here?

In order to generate static pages for the content in Gatsby's GraphQL database we need to do a couple of things. First, we need to query the database and make a list of what pages we want Gatsby to generate at what path. To do this we implement Gatsby's `createPages()` Node API, query the GraphQL database for a list of pages we want to generate, and then provide Gatsby with some information about those pages. Including the route that we want the page to live at, the template we want to use to render the HTML for the page, and enough contextual information so that the template component can extract the rest of the information it needs from database at build time.

Then we need to write a React component to use as a template for rendering each individual page. As well as a GraphQL page query that Gatsby will run to obtain the data required to build the page, and then automatically inject as `props.data` into our component.

## Implement Gatsby's `createPages()` API

Tell Gatsby about the pages you want it to render by implementing the `creagePages()` API. This is done by exporting a functioned named `createPages` from the specially named *gatsby-node.js* file at the root of your project. Go ahead and create the file if it doesn't already exist.

The `createPages()` function is called during the build process and passed an actions object which contains a collection of actions you can use to manipulate Gatsby's internal state. Gatsby uses Redux internally to manage state and "actions" in this case are basically the same as `boundActionCreators` in Redux. In this instance we'll use the `createPage` action to add one more more items to the list of things Gatsby should build. [Read more about the `createPage` action](https://www.gatsbyjs.org/docs/actions/#createPage).

Here's the code that goes in *gatsby-node.js*:

```javascript
const path = require(`path`);

exports.createPages = ({ graphql, actions }) => {
  const { createPage } = actions;

  return new Promise((resolve, reject) => {
    graphql(`
      {
        allNodeRecipe {
          edges {
            node {
              drupal_id,
              title,
              path {
                alias,
              }
            }
          }
        }
      }
    `).then(result => {
      result.data.allNodeRecipe.edges.forEach(({ node }) => {
        let path_alias;
        if (node.path.alias == null) {
          path_alias = `recipe/${node.drupal_id}`;
        } else {
          path_alias = node.path.alias;
        }

        createPage({
          // This is the path, or route, at which the page will be visible.
          path: path_alias,
          // This the path to the file that contains the React component
          // that will be used to render the HTML for the recipe.
          component: path.resolve(`./src/templates/recipe.js`),
          context: {
            // Data passed to context is available in page queries as GraphQL
            // variables.
            drupal_id: node.drupal_id,
          },
        })
      });

      resolve()
    })
  })
};
```

This code:

- Exports a new function named `createPages`. The name here is important, it's how Gatsby knows this function contains the code we want to execute during the page generation phase of the build process.
- Gatsby passes an object into the function and we extract the `graphql` function and `actions` object from it. Then further destructure the `actions` object to get the `createPage` function we'll use later.
- The function returns a `Promise`
- First we execute a query against Gatsby's internal GraphQL database. In this case we only need to get a minimal amount of information. The list of recipes to generate, the path we want to use for accessing the recipe, and the drupal_id of the recipe.
- Then we take loop over the results returned from the query and for each row we first figure out what path we want to the recipe to live at. In this case, if there's a custom path already set within Drupal we'll use it, and if not we'll use a generic one. Then for each row we call the `createPage` action and give it the path we want to use, the component to use when rendering the HTML for the path, and some additional contextual information we want made available to the template component. In this case the recipe drupal_id so we can use that to query for the complete recipe at build time.

## Define a recipe template

Next we need to define the template that is used to render the HTML for a recipe. Based on the code above this should live in *src/templates/recipe.js*. And export a React component, and a page query.

**Organization tip:** Instead of defining the HTML for your dynamic page in the template component create a separate component that does the bulk of the work and use the template as wrapper around that one.

Recipe template, *src/templates/recipe.js*:

```javascript
import React from 'react';
import { graphql } from 'gatsby';
import Helmet from 'react-helmet';
import Layout from '../components/layout';
import Recipe from '../components/Recipe/Recipe';
import Paper from '@material-ui/core/Paper';
import { withStyles } from '@material-ui/core/styles';

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

  return (
    <Layout>
      <Helmet
        title={`Umami - ${recipe.title}`}
        meta={[
          {name: 'description', content: recipe.title},
        ]}
      />
      <Paper className={classes.root}>
        <Recipe
          {...recipe}
          category={recipe.relationships.category[0].name}
          tags={recipe.relationships.tags}
          instructions={recipe.instructions.processed}
          summary={recipe.summary.processed}
        />
      </Paper>
    </Layout>
  )
};

export default withStyles(styles)(recipeTemplate);

// The $drupal_id variable here is obtained from the "context" object passed into
// the createPage() API in gatsby-node.js.
//
// Also note the use of field name aliasing in the query. This is done to
// help normalize the shape of the recipe data.
export const query = graphql`
  query RecipeTemplate($drupal_id: String!) {
    nodeRecipe(drupal_id: {eq: $drupal_id}) {
      drupal_id,
      title,
      cooking_time: field_cooking_time,
      difficulty: field_difficulty,
      ingredients: field_ingredients,
      preparation_time: field_preparation_time,
      number_of_servings: field_number_of_servings,
      instructions: field_recipe_instruction {
        processed,
      },
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
      }
    }
  }
`;
```

The code in this file does two important things:

1. It exports a React component, `recipeTemplate`, that provides a wrapper for the page content using a layout component, and then delegates to the `Recipe` component to render the content of the individual recipe.
2. Exports a variable named `query` wrapped with the `graphql` tag function which contains a GraphQL query that at build time is run to gather data for the individual recipe being displayed. Note the `$drupal_id` variable in `RecipeTemplate($drupal_id: String!)`. That comes from the `{context: drupal_id: 'xxx'}` that was passed to the `createPage` action in our implementation of the `createPages` API. This is how we know which recipe we're currently generating HTML for. When the GraphQL query completes the data it returns is injected into the `recipeTemplate` component as `props.data.*`.

Here's the complete Recipe component, *src/components/Recipe/Recipe.js*:

```javascript
import React from 'react';
import PropTypes from 'prop-types';
import GridList from '@material-ui/core/GridList';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';
import Typography from '@material-ui/core/Typography';
import { withStyles } from '@material-ui/core/styles';

const styles = theme => ({
  // custom CSS here ...
});

const Recipe = (props) => (
  <>
    <Typography variant="headline" paragraph>{props.title}</Typography>
    <GridList cols={5} cellHeight="auto">
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

    <Typography variant="subheading">Ingredients:</Typography>
    <List dense={true}>
      {
        props.ingredients.map((item, index) => <ListItem key={index}>{item}</ListItem>)
      }
    </List>

    <Typography variant="subheading">Preparation:</Typography>
    <Typography variant="body2" paragraph dangerouslySetInnerHTML={{ __html: props.instructions }} />

    <Typography variant="subheading">Try another recipe:</Typography>
  </>
);

Recipe.propTypes = {
  title: PropTypes.string.isRequired,
  difficulty: PropTypes.string.isRequired,
  cooking_time: PropTypes.number.isRequired,
  preparation_time: PropTypes.number.isRequired,
  ingredients: PropTypes.arrayOf(PropTypes.string),
  summary: PropTypes.string.isRequired,
  instructions: PropTypes.string.isRequired,
  category: PropTypes.string.isRequired,
  tags: PropTypes.array,
};

export default withStyles(styles)(Recipe);
```

## Generate some recipes

With the above changes in place restart the Gatsby development server; `gatsby develop`. And when the application's static content is rebuilt it should now include the recipe pages sourced from Drupal. Test it by either navigating directly to the path of a recipe. Or, by navigating to a known 404 page. Gatsby has a useful trick where 404 pages on the development server will give you a list of all the pages Gatsby knowns about internally.

In the next tutorial we'll look at how to dynamically generate a list of recipes for the front page, and link to these full recipe pages.

## Check out those references

Astute Drupal developers might have noticed that the recipe pages display the category, and tags, for a recipe. Both of which are Vocabularies in Drupal, and attached to the Recipe node via an Entity reference field. In Gatsby, and GraphQL, we can write a query that will traverse these relationships and allow us to get directly at the data we need.

## Dealing with text from Drupal

When handling the contents of a long text field, and some other field types as well, Drupal gives us access to both the `raw`, and `processed` content. The `raw` content is exactly what was entered into the text field by the user. And the `processed` content is the result of applying the selected text format to the content. Generally, it's best practice to make use of the `processed` value as it's been formatted, and filtered to prevent security vulnerabilities that could arise from working with user generated content. You can see examples of this in the code above like `instructions={recipe.instructions.processed}`.

An exception to this might be if you're using Markdown in Drupal. If you've got fields in Drupal configured to support Markdown formatting the `processed` value will contain the HTML resulting from applying Drupal's Markdown filter. And the `raw` value will contain the unaltered Markdown formatted text. Which, you could optionally pass through the remark Markdown processing that Gatsby uses for handling Markdown content at run time.

## Recap

In this tutorial we implemented Gatsby's `createPages` Node API to query the GraphQL database and generate a list of pages we wanted Gatsby to render for us. Then we mapped the pages in that list to a new recipe template which provides a React component that can render the HTML for a recipe, and a GraphQL query that can be used to populate the component with the necessary data. Resulting in a static HTLM page being generated by Gatsby for each of the recipes in our Drupal CMS.

## Further your understanding

## Additional resources

- [Creating and Modifying Pages](https://www.gatsbyjs.org/docs/creating-and-modifying-pages/) (gatsbyjs.org)
- `[createPages` documentation](https://www.gatsbyjs.org/docs/node-apis/#createPages) (gatsbyjs.org)
- `[createPage` documentation](https://www.gatsbyjs.org/docs/actions/#createPage) (gatsbyjs.org)

of this in Drupal with JSON API Extras module)

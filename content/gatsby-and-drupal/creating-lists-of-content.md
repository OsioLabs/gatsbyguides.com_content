# Creating Lists of Content

[# summary #]
You'll probably need to provide users with lists so they can see what content is available in your application. Those lists will need to be kept up-to-date as content is added, edited, or removed. This requires querying GraphQL to get the titles and paths for pages you want to link to, and then using the `Link` component provided by *gatsby-link* to create clickable links to those pages at build time.

In this tutorial we'll:

- Update the *src/pages/index.js* file used to generate the front page of your application so that it contains a dynamically generated list of recipes
- Create a new `RecipeList` component that uses a `StaticQuery` to generate a short list of recipes to display at the bottom of each recipe page
- Use the Gatsby `Link` component to create blazing fast internal links within our application.

By the end of this tutorial you'll know how to use both page queries and static queries to generate lists of content links from the GraphQL database at build time.
[# endsummary #]

## Goal

Add a list of recipes to the front page, and a shorter list of recipes at the bottom of each recipe page, dynamically generated at build time from the content in Drupal.

## Prerequisites

- [Get Data Out of Drupal and Into Gatsby](/content/gatsby-and-drupal/get-data-out-of-drupal-and-into-gatsby.md)

## Page query vs. Static query

There are two different ways you can get Gatsby to run a GraphQL query for you during build time. Which one you use depends primarily on the context in which you're performing the query.

- **Page queries:** Page queries are special variables exported from a file whose contents are a GraphQL query wrapped with the Gatsby provided `graphql` tag function. If this variable exists, Gatsby will automatically find, run, and inject the results of the query back into the default component exported from the same file. As the name implies, these are used when generating pages. They will only work when used either in the context of a `createPage` template component, or when generating a page from a file in *src/pages/*.* See this in use in [Dynamically Creating Pages](/content/gatsby-and-drupal/dynamically-creating-pages.md).
- **Static queries:** Static queries are implemented via the `StaticQuery` component. They provide a way for any component to issue a query and retrieve the data they need. This helps to reduce the need to pass data down the stack as props, and instead allows components that need it to declare exactly what data they need.

## Super fast links

Gatsby provides a handy `Link` component that we can use whenever creating links to internal pages. The `Link` component contains logic for handling pre-fetching and pre-caching routes as they scroll into view. [Learn more about the speed benefits this provides](https://www.gatsbyjs.org/docs/gatsby-link/).

## Add a list of recipes to the front page

To add a list of content to the front page, or any page generated from a file in *src/pages/* we need to:

- Export a `graphql` tagged function that contains our query
- Update the component to use the `props.data.*` data from the query that Gatsby automatically injects for us
- Use the `Link` component for all internal links

Here's an example of what we're going for:

![List of recipes.](/content/gatsby-and-drupal/images/recipe-list-homepage.png)

We'll start by defining a new `RecipeCard` component which we can use to display recipes on the front page. There's nothing special about this code; it just needs to exist so we can have a nice way of displaying the content.

Code for *src/components/RecipeCard/RecipeCard.js*:

```javascript
import React from 'react'
import PropTypes from 'prop-types';
import { Link } from 'gatsby'
import { makeStyles } from '@material-ui/core/styles';
import Button from '@material-ui/core/Button';
import Card from '@material-ui/core/Card';
import CardActions from '@material-ui/core/CardActions';
import CardContent from '@material-ui/core/CardContent';
import Typography from '@material-ui/core/Typography';

const useStyles = makeStyles(theme => ({
  card: {
    maxWidth: 345,
    minHeight: 310,
  },
  bullet: {
    display: 'inline-block',
    margin: '0 2px',
    transform: 'scale(0.8)',
  },
  title: {
    marginBottom: 16,
    fontSize: 14,
  },
  pos: {
    marginBottom: 12,
  },
}));

const RecipeCard = (props) => {
  const classes = useStyles();
  const RecipeLink = props => <Link to={props.path} {...props}>Read more</Link>;

  return (
    <Card className={classes.card}>
      <CardContent>
        <Typography className={classes.title} color="textSecondary">
          {props.category}
        </Typography>
        <Typography variant="h5" component="h2">
          {props.title}
        </Typography>
        <Typography className={classes.pos} color="textSecondary" dangerouslySetInnerHTML={{ __html: props.summary }} />
      </CardContent>
      <CardActions>
        <Button size="small" path={props.path} component={RecipeLink}>Read more</Button>
      </CardActions>
    </Card>
  );
};

RecipeCard.propTypes = {
  classes: PropTypes.object.isRequired,
  title: PropTypes.string.isRequired,
  summary: PropTypes.string.isRequired,
  category: PropTypes.string.isRequired,
  path: PropTypes.string.isRequired,
};

export default RecipeCard;
```

The real work happens in the code in *src/pages/index.js*. This is the file that's generating the HTML for the `/` route.

Updated code for *src/pages/index.js*:

```javascript
import React from 'react'
import PropTypes from 'prop-types';
import { graphql } from 'gatsby'
import { makeStyles } from '@material-ui/core/styles';
import Box from '@material-ui/core/Box';
import Grid from '@material-ui/core/Grid';
import Paper from '@material-ui/core/Paper';
import Typography from '@material-ui/core/Typography';

import Layout from '../components/layout'
import RecipeCard from '../components/RecipeCard/RecipeCard';

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
      </Paper>
      <Box mt={3}>
        <Grid container spacing={1}>
        {
          props.data.allNodeRecipe.edges.map(({ node: recipe }) => (
            <Grid item key={recipe.title} xs={6} md={4}>
              <RecipeCard
                title={recipe.title}
                summary={recipe.summary.processed}
                category={recipe.relationships.category[0].name}
                path={recipe.path.alias}
              />
            </Grid>
          ))
        }
        </Grid>
      </Box>
    </Layout>
  );
};

IndexPage.propTypes = {
  classes: PropTypes.object.isRequired,
};

export default IndexPage;

// The result of this GraphQL query will be injected as props.data into the
// IndexPage component.
export const query = graphql`
  query {
    allNodeRecipe(sort: {fields: [changed], order:DESC}) {
      edges {
        node {
          drupal_id,
          title,
          path {
            alias,
          }
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
    }
  }
`;
```

In this code we:

- Export a new variable named `query` using the `graphql` tag function with a query that gets details about all the recipes we want to display on the front page. It's also known as a *page query*. This is automatically picked up by Gatsby and executed. The results of the query are injected into the `IndexPage` component as `props.data.allNodeRecipe`.
- In the `IndexPage` component we loop over the returned data using `props.data.allNodeRecipe.edges.map()` and output a `<RecipeCard />` for each item.

Thus, each time the site is built using `gatsby build`, the content of home page is updated. If additional recipes were added to our CMS, they will be pulled into Gatsby's GraphQL database and then displayed.

## Creating a `RecipeList` component

Let's also create a new `RecipeList` component that displays a list of links to the 3 most recently added recipes that we can use anywhere in our application, not just when generating pages. For example, we might add a list like this to the bottom of each recipe page:

![Rendered recipe list component showing recipe title and details.](/content/gatsby-and-drupal/images/recipelist-component-example.png)

To do this we need to:

- Create a new `RecipeList` component
- Use the `StaticQuery` component provided by Gatsby to execute our query; this follows the standard ["render prop" technique](https://reactjs.org/docs/render-props.html).
- Include the `RecipeList` component somewhere on our site so that it gets rendered

Example *src/components/RecipeList/RecipeList.js*:

```javascript
import React from 'react';
import PropTypes from 'prop-types';
import { StaticQuery, Link, graphql } from "gatsby"

const RecipeListWrapper = () => (
  <StaticQuery
    query={graphql`
      query {
        allNodeRecipe(limit: 3) {
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
    `}
    render={data => <RecipeList recipes={data.allNodeRecipe.edges} />}
  />
);

const RecipeList = ({recipes}) => (
  <ul>
    {
      recipes.map(({ node: recipe }) => (
        <li key={recipe.drupal_id}>
          <Link to={recipe.path.alias}>
            {recipe.title}
          </Link>
        </li>
      ))
    }
  </ul>
);

RecipeList.propTypes = {
  recipes: PropTypes.arrayOf(
    PropTypes.shape({
      node: PropTypes.shape({
        drupal_id: PropTypes.string.isRequired,
        title: PropTypes.string.isRequired,
        path: PropTypes.shape({
          alias: PropTypes.string.isRequired,
        }).isRequired,
      }).isRequired,
    }),
  ).isRequired,
};

export default RecipeListWrapper;
```

In this code we:

- Create a fairly generic `RecipeList` component that takes an array of recipes and displays them as an unordered list of links to internal pages using the Gatsby `<Link />` compnent
- Create a `RecipeListWrapper` component, within which we use the `StaticQuery` component provided by Gatsby to query the GraphQL database for the data we want to display. The `StaticQuery` component takes `query` prop which uses the `graphql` tag function to supply a query that we would like the execute. It also uses a `render` function which takes a Component to render the results. The results of the query are passed as a props to the provided Component.

Edit the `Recipe` component created in [Dynamically Creating Pages](/content/gatsby-and-drupal/dynamically-creating-pages.md) and add the new `RecipeList` component to the bottom in order to display additional recipes for someone to read when they complete the one they are viewing.

[Learn more about using the `StaticQuery` component](https://www.gatsbyjs.org/docs/static-query/) to colocate a component with its data.

## Recap

In this tutorial we looked at two different ways you can create lists of content sourced from your CMS. The first, page queries, can be used in either page (*src/pages/...*) files or template (*src/template/**) files. It's the preferred method for doing things like creating landing pages that list lots of content. The second, static queries, use the `StaticQuery` component provided by Gatsby to allow you to write queries directly into any component. That method is useful when you want to colocate the data and the component opposed to passing data through props from parent to child.

## Further your understanding

- Can you think of use-cases where statically generating a list like this might *not* be ideal?
- Take the code for the front page one step further. Update it so that a static version is rendered by Gatsby. But then at runtime, have the Component query the Drupal API directly for any updated content, ensuring the list is as up-to-date as possible.

## Additional resources

- The Gatsby documentation has a [whole section on querying data with GraphQL](https://www.gatsbyjs.org/docs/graphql/) (gatsbyjs.org)
- [Learn GraphQL](https://www.howtographql.com/) (howtographql.com)

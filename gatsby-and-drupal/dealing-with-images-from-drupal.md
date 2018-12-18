# Dealing with Images from Drupal

## Summary

One of the benefits of using Gatsby is it's built in support for image optimization. Gatsby makes it easier to use best-practices techniques like blur-up or svg tracing to ensure images don't slow down page loads. As well as providing utilities that allow developers to request an image at a specific size, or set of sizes.

In this tutorial we'll:

- Install some common Gatsby image handling plugins and learn about what each one does
- Write GraphQL queries that use transformer functions to return one or more variations of an image
- Update our `Recipe` component to display images using the blur-up pattern

By the end of this tutorial you should know how to display images sourced from Drupal using the blur-up technique with Gatsby.

## Goal

Update the `Recipe` component to display images using the blur-up technique and improve load times for recipe pages in our application.

## Prerequisites

- [Dynamically Creating Pages](/content/gatsby-and-drupal/dynamically-creating.pages.md)

## How this all works

At a high level when Gatsby sources data from Drupal it pulls in the raw image files attached to any image field. The files are stored locally, and info is added to GraphQL. The gatsby-plugin-sharp, and gatsby-plugin-transform plugins work together to exposes several image processing functions in GraphQL. When you query GraphQL for an image you can use these functions to say "use this image, but return all the necessary image variants for advanced image loading techniques like blur-up or traced SVG placeholder". Finally, that returned data can be passed verbatim to the `Img` component from gatsby-image which contains the required logic to display the image(s).

It's a lot of really complex image manipulation and display logic wrapped up into a reusable pattern requiring you to do very little additional work in your code to potentially dramatically increase speed.

## Install the required plugins

*Note:* Some or all of these might be already installed depending on the starter kit you used.

Start by installing the following plugins:

- [gatsby-image](https://www.gatsbyjs.org/packages/gatsby-image/): A React component designed to work seamlessly with Gatsby's GraphQL image related queries.
- [gatsby-plugin-sharp](https://www.gatsbyjs.org/packages/gatsby-plugin-sharp/): Exposes several image processing functions built on the [Sharp image processing library](https://github.com/lovell/sharp) to GraphQL.
- [gatsby-transformer-sharp](https://www.gatsbyjs.org/packages/gatsby-transformer-sharp): Recognizes image type fields being created during the data sourcing process and creates `ImageSharp` nodes in GraphQL for processing images in a variety of ways.

```shell
npm install --save gatsby-image gatsby-plugin-sharp gatsby-transformer-sharp
```

Enable, and enable the plugins in *gatsby-config.js*:

```javascript
module.exports = {
  plugins: [
    `gatsby-plugin-sharp`,
    `gatsby-transformer-sharp`,
  ],
}
```

Start, or restart, the development server with `gatsby develop`.

## Update your GraphQL queries

Next you need to update your GraphQL queries to make use of the functions and fragments provided by the gatsby-plugin-sharp, and gatsby-transform-sharp plugins.

In *src/templates/recipe.js* modify the code to look like this:

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
          uuid={recipe.uuid}
          title={recipe.title}
          difficulty={recipe.difficulty}
          cooking_time={recipe.cooking_time}
          prepartion_time={recipe.preparation_time}
          ingredients={recipe.ingredients}
          category={recipe.relationships.category[0].name}
          tags={recipe.relationships.tags}
          instructions={recipe.instructions.processed}
          summary={recipe.summary.processed}
          image={recipe.relationships.image}
        />
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

The new part is the `image: field_image` section of the GraphQL query, and the line to pass the resulting new data down to the `Recipe` component. Here's what it does.

- field_image is the image field configured in Drupal. When the recipe was imported into GraphQL Gatsby downloaded the image, and inserted the data about the image on-disk into the `localFile` field.
- gatsby-transform-sharp recognized the image field and created the the corresponding `childImageSharp` node. Which we can use in combination with the GraphQL functions from gatsby-plugin-sharp.
- The `fluid()` function returns fluid sizes (in width) for the image. If the max width of the container for the rendered markdown file is 800px, the sizes would then be: 200, 400, 800, 1200, 1600, 2400 – enough to provide close to the optimal image size for every device size / screen resolution. You can control the sizes by specifying arguments to the function. You'll want to include a `maxWidth` parameter at a minimum, which is the max width that the image's container will ever be.
- Finally, `...GatsbyImageSharp` is a GraphQL fragment that pairs with the `Link` component from the gatsby-image plugin. It's a shortcut for specifying what data we want from the functions return values and what shape we want it in. (Note: because of this fragment in our query this query will not work in the GraphiQL IDE anymore.)
- The data returned from GraphQL is passed down to the `Recipe` component with this line `image={recipe.relationships.image}`.

## Render the image

In *src/Components/Recipe/Recipe.js* update the `Recipe` component to output an `Img` component.

First import the `Img` component:

```javascript
import Img from 'gatsby-image';
```

Then update the `Recipe` component to output an `Img` component by adding something like the following to it's return value:

```javascript
<>
  {props.image.localFile &&
    <Img fluid={props.image.localFile.childImageSharp.fluid} />
  }
  <Typography variant="headline" paragraph>{props.title}</Typography>
  // ...
```

Notice how `this.props.image.localFile.childImageSharp.fluid` which we pass as a prop to the `Img` component relates to the data structure we requested in our GraphQL query above? This is made super easy by the fact that the `Img` component knows exactly what to do with the data returned by the `...GatsbyImageSharpFluid` GraphQL fragment we used earlier.

Now navigate to any recipe page in your application, refresh the page, and watch the blur-up effect in action.

## Recap

In this tutorial we started by installing the gatsby-image, gatsby-plugin-sharp, and gatsby-transformer-sharp plugins. Then used the GraphQL functions and fragments, and React components they exposed to load images on recipe pages using the popular blur-up technique.

Maybe the best part of all of this is the fact that all the business logic is encapsulated into the Gatsby plugins and not our application specific code. This means that as techniques for loading images change and improve over time, as long as they are updated in the Gatsby plugins, we should be able to take advantage of those updates with little to no changes in our applications code.

## Further your understanding

- Can you also update the `RecipeCard` component to display an image thumbnail?
- [Check out the other image manipulation functions provided by the gatsby-plugin-sharp plugin](https://www.gatsbyjs.org/packages/gatsby-plugin-sharp/).
- In this tutorial we've dealt only with fluid width images. [Learn about using the `Img` component to handle fixed width/height response images](https://www.gatsbyjs.org/packages/gatsby-image/)

## Additional resources

- [Gatsby Image demos](https://using-gatsby-image.gatsbyjs.org/)
- [gatsby-image](https://www.gatsbyjs.org/packages/gatsby-image/)
- [gatsby-plugin-sharp](https://www.gatsbyjs.org/packages/gatsby-plugin-sharp/)

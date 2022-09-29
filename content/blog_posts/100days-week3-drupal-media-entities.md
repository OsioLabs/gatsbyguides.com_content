# #100DaysOfGatsby Week 3: Drupal Media Entities

As of Drupal 8.8, the Media Library module in Drupal core is stable — and awesome! It allows easy reuse of images, documents, videos, and other assets. It is integrated into content creation forms, and works great with the built in WYSIWYG editor.

You can see a demo of it in action here: [https://www.youtube.com/embed/3qwvBuSApro](https://www.youtube.com/embed/3qwvBuSApro)

For [challenge #3 of the #100DaysOfGatsby challenge](https://www.gatsbyjs.org/blog/100days/gatsby-image/) I wanted to explore how media (especially images) embedded into the body of a blog post using Drupal's WYSIWYG editor could work with Gatsby. I did a LOT of experimenting over the last week, and this is one of the ways I was able to get things working.

If you want to learn about using images attached to a Drupal node via an image field in Gatsby check out our tutorial, [Dealing with Images from Drupal](https://gatsbyguides.com/tutorial/dealing-images-drupal).

If you're curious about how to do this with images added via CKEditor, and NOT as part of the Media Library, check out [this blog post](https://www.andrewl.net/article/gatsby-drupal-inline-images?no-cache=1). I learned a bunch while reading it, and borrowed some of the ideas Andrew uses.

## Configure Drupal to use the Media Library for images

I started out by enabling the Media Library and Media modules in Drupal. Then I configured the *Basic HTML* text format to include the *Embed media* filter, and enabled the *Insert from Media Library* button in the WYSIWYG editor.

[Learn more about configuring Drupal text formats and editors](https://drupalize.me/tutorial/user-guide/structure-text-format-config?p=3071).

When using Drupal's Media Library to embed media entities (which in this case are images) into a post, there wasn't initially a way for me to retrieve the internal ID of the media entity from the processed HTML that I got from Drupal's JSON:API. (More on why this is necessary later.)

To understand the output you get from Drupal, it helps to understand how Drupal deals with generating the HTML that represents an embedded media entity. A Drupal field contains configuration for both the *widget* that's used to collect user input, as well as the *formatter* that's used to format the collected data when it's displayed.

An example is a text field that contains Markdown. An author types Markdown into the `<textarea>` *widget*. Drupal stores that Markdown in the database. When someone views the record containing the Markdown content, Drupal looks at the field configuration to learn which *formatter(s)* to apply (convert Markdown to HTML, in this case), and then applies them before displaying the end result to the user. Internally, Drupal keeps track of this as the *value* (raw Markdown) of a field, and the *processed* (Markdown converted to HTML) value of a field.

You can see this in the output from JSON:API which has both the `body.value` and the `body.processed` content of the body field:

![](/content/blog_posts/images/jsonapi-body-value-example.png)

A common practice is for a field to be configured to use a WYSIWYG *widget* for authors to enter content. In this case, Drupal stores whatever value is produced by the WYSIWYG editor. The Drupal WYSIWYG editor can be configured to have a button for embedding media from the site's media library.

![](/content/blog_posts/images/ckeditor-media-button.png)

When you click the button to embed a media entity into your content, Drupal stores that reference using a token like the one below. When the content is saved, this token is what you would find saved in the database mixed in with the rest of the HTML provided by the WYSIWYG editor.

```html
<drupal-media data-align="center" data-entity-type="media" data-entity-uuid="d0dfb232-56dd-4067-9c39-560c6d9b49c9"></drupal-media>
```

Assuming you've enabled the *Embed media* filter for the text formatter used for the field, Drupal will convert that token into HTML, much like converting Markdown to HTML. The *formatter* uses the `data-*` attributes in the token to figure out what kind of entity it is, what specific entity to load, and what view mode to use to display it. It then asks for the HTML version of that entity using the requested view mode, and replaces the token with whatever is returned.

Here's an example of what an embedded image media entity looks like using the default view mode:

```html
<article class="align-center media media--type-image media--view-mode-embedded-image">
  <div class="field field--name-field-image field--type-image field--label-hidden field__item">
    <img src="/sites/default/files/2020-01/create-blog-post.png" alt="Screenshot of Drupal content creation form with checkboxes for GatsbyGuides.com and HeyNode.com demonstrated at the bottom of the form." width="1155" height="1876">
  </div>
</article>
```

I wanted to add the internal ID of the image to that HTML output so that in my Gatsby code I can use it to look up the relevant image files in Gatsby's GraphQL database.

The HTML in this case is generated by Drupal's theme layer. It's no different than the process Drupal would use to generate the HTML for the entity if you were viewing it at its own canonical URL instead of embedded in a field. So to change it, I need to theme the output for media entities.

The following assumes familiarity with Drupal's theme layer.

I decided to add `data-media-source` and `data-media-source-value` attributes to the `<article>` tag. This seems like a more generic approach that'll work with non-image media too. (I haven't tried it yet.) Adding attributes can be done using an implementation of `hook_preprocess_HOOK()`. In my case I opted to put the hook implementation into a custom module because I want these changes to be applied regardless of what theme is being used. I'm using Drupal as the backend only, so the content is always viewed via the API.

The final hook implementation looks like this in *modules/custom/mymodule/mymodule.module*:

```php
/**
  * Implements hook_preprocess_HOOK().
  */
function MYMODULE_preprocess_media(&$variables) {
        /** @var \\Drupal\\media\\Entity\\Media $media */
  $media = $variables['media'];
        // Set the value to the "type" of media entity that this is.
  $variables\['attributes'\]['data-media-source'] = $media->bundle();
        // Get the primary value stored in the source field. For images this is
  // going to be the Drupal ID of the file entity that contains the image
  // file. For non-image media this could be all kinds of different things
  // so you'll need to test it out and adjust as needed.
  $variables\['attributes'\]['data-media-source-value'] = $media->getSource()
    ->getSourceFieldValue($media);

        // An alternative approach that would get you the UUID of the image entity,
  // which might be easier in Gatsby, but not necessarily as friendly to
  // non-image media types which store the source value as something other than
  // an entity reference would be to use this:
  // $media->get($media->getSource()->getConfiguration()['source_field'])->getEntity()->uuid();
}
```

The result is that the `<article>` tag for an embedded image media entity now looks like the example below instead of what we had previously:

```html
<article
  data-media-source="image"
  data-media-source-value="63"
  class="align-center media media--type-image media--view-mode-embedded-image"
>
  ...
</article>
```

You could alternatively use the raw, unprocessed, value from Drupal, which would contain the `<drupal-media />` tag. However, you would be bypassing any other filters that Drupal applies to the content, including some important security ones that help to prevent XSS/CSRF attacks. And your application would need to make sure to filter the user-generated content before displaying it.

With all of that in place, the rest of the work happens in Gatsby.

## Display images from Drupal using Gatsby's Img component

This assumes you're already using [gatsby-source-drupal](https://gatsbyguides.com/tutorial/get-data-out-drupal-and-gatsby) and [gatsby-transformer-sharp](https://www.gatsbyjs.org/packages/gatsby-transformer-sharp/). You should be generally familiar with [how the Gatsby](https://gatsbyguides.com/tutorial/dealing-images-drupal) `[Img](https://gatsbyguides.com/tutorial/dealing-images-drupal)` [component is used](https://gatsbyguides.com/tutorial/dealing-images-drupal).

Drupal exposes the image media entities at `jsonapi/images`, and the `gatsby-source-drupal` plugin already knows how to handle pulling in those entities, and downloading the associated image files. So, this information is now available in Gatsby's GraphQL without special configuration and can be queried like this:

```graphql
allImages: allImages {
  edges {
    node {
      relationships {
        imageFile {
          drupal_internal__fid
          localFile {
            childImageSharp {
              fluid(maxWidth: 1280) {
                ...GatsbyImageSharpFluid
              }
            }
          }
        }
      }
    }
  }
}
```

The value of the `drupal_internal__fid` field in this case maps to the `data-media-source-value` attribute on the `<article>` tag that we added above.

I updated the query in the *src/templates/blog-page.js* template I created earlier. So now the `data` prop passed to the `BlogPostTemplateWithData` component contains `data.allImages`.

In my Gatsby theme the goal is to keep data processing logic separate from rendering I updated the `BlogPostTemplateWithData` component to pass only the necessary images along to the display component. The following code searches the body of the blog post received from Drupal for the value of any `data-media-source-value` attributes. Then it creates a new variable `bodyImages` with just the records for those images, which is then passed along to the component that does the rendering.


```javascript
const regexp = /data-media-source-value="(\\d+)"/gm;
const matches = [...props.data.post.body.processed.matchAll(regexp)];
const imageIds = matches.map(match => parseInt(match[1]));
const bodyImages = props.data.allImages.edges
  .filter(item => {
    if (
      imageIds.includes(
        item.node.relationships.imageFile.drupal_internal__fid
      )
    ) {
      return item.node.relationships.imageFile.drupal_internal__fid;
    }
  })
  .map(item => item.node.relationships.imageFile);
```

Finally, we need to convert the `<article />` tags in the blog post's body that represent embedded images to use the `Img` component from `gatsby-image`. To do this I used the [react-html-parser library](https://www.npmjs.com/package/react-html-parser) which converts a string of HTML to a React component tree. Additionally, it allows you to apply custom transformations in the process.

Example blog post display component:

```javascript
import React from 'react'
import PropTypes from 'prop-types'
import Img from 'gatsby-image'
import ReactHtmlParser from 'react-html-parser'
import Layout from '../../../components/layout'

const BlogPostTemplate = props => {
  const {
    title,
    created,
    author,
    body,
    bodyImages,
  } = props

  let postBody = <div dangerouslySetInnerHTML={{ __html: body }} />
  if (bodyImages) {
    postBody = new ReactHtmlParser(body, {
      transform: function transform(node) {
        if (
          node.type === 'tag' &&
          node.name === 'article' &&
          node.attribs['data-media-source'] === 'image'
        ) {
          const imageData = bodyImages.find(
            el =>
              el.drupal_internal__fid ===
              parseInt(node.attribs['data-media-source-value'])
          )
          if (imageData) {
            return <Img fluid={imageData.localFile.childImageSharp.fluid} />
          }
        }
      },
    })
  }

  return (
    <Layout className="blog">
      <h1>{title}</h1>
      <div className="meta">
        By {author} on {created}.{' '}
      </div>
      {postBody}
    </Layout>
  )
}

export default BlogPostTemplate
```

For performance reasons we only use `react-html-parser` if there are images that need to replaced. If there are images the `bodyImages` variable will contain them. The `transform` function does the work of locating any `<article />` tags with a `data-media-source-value` attribute, and then matching those tags with a record in `bodyImages`. Finally the `<article />` tag is replaced with an `<Img />` component, populated with the data we retrieved from GraphQL earlier.

And now, we've got inline Drupal media entities displaying in our blog posts using all the power of Gatsby's image processing and display code. Ta-da!

## Conclusion

In order to use Gatsby's suite of image processing and display tools to display image media entities embedded into the content of a blog post sourced from Drupal we had to get Drupal to include some data in the HTML it output so we can more easily identify which media entities are embedded. Then we did a search and replace in Gatsby to find the embedded media entity and replace it with a Gatsby `<Img>` component and data from GraphQL.

While we're only dealing with images here, I think it would be possible to use a similar technique for other types of Drupal media entities. For example, you could use the `data-media-source` and `data-media-source-value` attributes in combination with a custom React component to display YouTube videos.

## Continued learning

Another option that I've been pondering would be to use the WYSIWYG tool to add the `<drupal-media/>` tags into the content body, but not enable the *Media embed* filter. This would mean that the `<drupal-media/>` tags would remain in the processed value of the body field. Then instead of having to muck with the `<article/>` tag, just to eventually replace it, you could operate directly on the `<drupal-media/>` tags, which would be a lot cleaner.

A couple of initial thoughts about this approach, and why I'm avoiding it for now:

- You wouldn't be able to display the content via Drupal, at least not without manually executing the *Media embed* filter at some point to process those `<drupal-media/>` tags.
- You could use the raw un-filtered field value, but again, there's some security implications of doing so that I haven't fully thought through. And, you would lose the potential benefit of other filters like fixing bad HTML, or automatically turning URLs into links. Though, that might okay.

I would love to hear other people's thoughts on using the raw field value in this way.

# #100DaysOfGatsby Week 4: Formik & RESTful Drupal Webforms

The task for [this challenge](https://www.gatsbyjs.org/blog/100days/react-component/) is to incorporate a third-party React library into your Gatsby project and build a contact form. Since I'm a bit behind on these challenges I have the benefit of foresight, and know that [in a future challenge](https://www.gatsbyjs.org/blog/100days/serverless/) this contact form will be combined with a serverless function to handle processing of submitted form data. I've opted to create a React-based contact form that submits its data to a [Drupal Webform](https://www.drupal.org/project/webform) via Drupal's REST API. That way, I let Drupal handle the tasks of storing the submitted form data and sending out any appropriate emails.

As recommended in the challenge, I opted to use the Formik library. I’d never used it before and enjoyed the chance to try something new. Up until this point I've always just used React + Vanilla JavaScript for form handling, and honestly with the small number of relatively simple forms I've created and need to maintain, it's been just fine. I can see why people like Formik, and will definitely consider using it again for future projects. I particularly like how it helps to reduce boilerplate code and ensures that all your forms use a standardized approach.

If you're familiar with Drupal development there are a lot of parallels between Drupal's Form API and Formik. Maybe the biggest win for both is that they take a task like form submission processing, validation, and error handling — which is quite nebulous and can be done in dozens of different *right* ways — and prescribe a single standard approach. That keeps you from the arduous task of trying to decide between two or more different *good enough* approaches. In addition to that, they abstract away the edge case problems that you might not have known about. And now they’ll never be a problem.

The result is a code base that's easier to maintain, and friendlier for whoever has to work on it next because it's consistent. It also follows a well-known, and hopefully well-documented, approach.

## Create a contact form in Drupal

I started by creating a contact form in Drupal. I configured it to store collected data, and send a notification email to [support@gatsbyguides.com](mailto:support@gatsbyguides.com) whenever a new submission is received.

While Drupal core's contact module can be used to build a contact form, the [Webform module](https://www.drupal.org/project/webform) is the tool of choice for building anything other than the most basic of contact forms. It's more flexible, has far more options for creating forms, and can be configured to do all kinds of post-processing of the data collected. You can email it, save it to a remote API, analyze it, etc. 

This makes it suitable for creating any type of data collection form, not just a contact form.

In comparison to Drupal core's Entity and Field APIs which also allow you to build custom data collection forms, the Webform module excels in scenarios where the goal is to collect data from a large number of people that's viewed by a smaller number of people. This could be a contact form or a survey. This is in contrast to content like a blog where a small number of people create content that's viewed by a large number.

We can use this form we create, and the data it collects, in a similar way to how you might use a serverless function. Assuming we can get the form data submitted to Drupal, we can do something with that data collected by React & Formik. This means setting up some kind of web services API to which React can transmit the collected data.

First [create the contact Webform in Drupal](https://www.drupal.org/docs/8/modules/webform/webform-introduction). Or, use the one that came pre-installed with the Webform module. (Like I did.) This has fields for name, email, subject, and message.

![](/content/blog_posts/images/gastbychallenge-week4-6.png)

A few settings changes I made:

- Under *Settings* > *General* for the form, I disabled the *Allow users to post submissions from a dedicated URL* option. Since the front-end form is totally decoupled from Drupal there's no reason for me to expose a page with the form on it in Drupal.
- Under *Settings* > *Emails/Handlers* I disabled sending the confirmation email. I verified the notification email is sent to the correct address. Whatever you configure here is what's going to happen when a new contact email is submitted from your React code.

You can test your form in Drupal to make sure everything is working as expected.

Next we need to allow the form to be submitted via a web services API.

## Install and configure the Webform REST module

To expose an API for submitting the contact Webform I installed the [Webform REST module](https://www.drupal.org/project/webform_rest) which uses Drupal core's REST module to allow for collecting Webform data via REST. At the time this was written I used the 8.x-2.0-beta2 version of the module, though there's also an 8.x-3.x version in development. With the Webform REST module enabled I also installed and used [REST UI](https://www.drupal.org/project/restui) to expose a UI that allowed me to enable the new REST endpoint.

With REST UI enabled, navigate to *Configuration* > *Web Services* > *REST* (admin/config/services/rest) then find the row for "Webform Submit". Click the *Enable* button to turn it on.

![](/content/blog_posts/images/gastbychallenge-week4-1.png)

While there are other Webform related endpoints, for my use-case the only one I need enabled is the ability to submit a new record. The others allow full access to doing things like creating a new Webform, managing existing submissions, etc. Keep your application’s attack surface lower by only enabling REST endpoints that you're going to use.

![](/content/blog_posts/images/gastbychallenge-week4-2.png)

You can configure the newly enabled endpoint further by choosing one or more request formats, and authentication providers, that can be used for this endpoint. I'm going to use the JSON request format, and OAuth2 for authentication. The contact form doesn't require authentication, but some other forms on the site, like the feedback form on the bottom of a tutorial, will use your authentication credentials if you're signed in.

The exposed REST endpoint will respect Drupal's existing CRUD permissions for the resources in question. So if your permissions require a user to be signed in in order to submit a webform, then they'll need to be signed in to submit it via the REST API.

## Test the new contact form REST API

We can now *submit* the contact form, or any other Webform, via the REST API by making a `POST` request to `/webform_rest/submit` with a JSON formatted request body.

Example:

```txt
POST /webform_rest/submit
```

```json
{
  "webform_id": "contact",
  "name": "Joe",
  "email": "myemail@example.com",
  "subject": "My subject",
  "message": "The message body for the email."
}
```

In the above example:

- `webform_id` is required. It identifies which form the submitted data is associated with, and can be determined by going to *Settings* > *General* for the form in question.
- The additional keys are the machine names of the configured fields which can be discovered by going to the *Build* tab for the form in question and looking under the *Key* column in the table on that page. Check out the image listing the fields for the contact form above for an example.
## Submit the React/Formik form data to Drupal

In order to tie it all together we need to add some custom JavaScript code to the `onSubmit` handler of the `<Formik>` component that makes an API request to Drupal using the collected form data. This is probably easiest to understand by looking at the complete example.

The final code for the contact form looks like this:

```javascript
import React from 'react'
import { Field, Form, Formik, ErrorMessage } from 'formik'
import * as Yup from 'yup'

async function handleFormSubmission(values, actions) {
  const API_ENDPOINT = `${process.env.GATSBY_DRUPAL_API_ROOT}/webform_rest/submit?_format=json`;
  const headers = new Headers({
    Accept: 'application/json',
    'Content-Type': 'application/json'
  });

  const payload = {
    ...values,
    webform_id: 'contact',
  };

  const options = {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  };

  try {
    const response = await fetch(API_ENDPOINT, options);
    if (response.ok) {
      // Success.
      const data = await response.json();

      if (typeof data.error !== 'undefined') {
        // Error returned from Drupal while trying to process the request.
        actions.setStatus({
          error: true,
          message: data.error.message,
        });
      } else {
        actions.setStatus({
          success: true,
          message: 'Thanks. We will get back to you shortly.',
        });
      }
    } else {
      // Error connecting to Drupal, e.g. the server is unreachable.
      actions.setStatus({
        error: true,
        message: `${response.status}: ${response.statusText}`,
      });
    }
  } catch (e) {
    actions.setStatus({
      error: true,
      message: e.message,
    });
  }

  actions.setSubmitting(false);
}

const ContactUsForm = () => (
  <div className="contact-form">
    <Formik
      initialValues={{ email: '', name: '', subject: '', message: '' }}
      validationSchema={Yup.object({
        name: Yup.string().required('Required'),
        email: Yup.string()
          .email('Invalid email address')
          .required('Required'),
        subject: Yup.string().required('Required'),
        message: Yup.string().required('Required'),
      })}
      onSubmit={(values, actions) => {
        handleFormSubmission(values, actions);
      }}
    >
      {({ handleReset, isSubmitting, isValidating, status }) => (
        <>
          {status && (status.success || status.error) ? (
            <div className={status.success ? 'success' : 'error'}>
              {status.message}
              {' '}
              <button onClick={() => handleReset()}>Send us another message</button>
            </div>
          ) : (
          <Form>
            <div className="field field--name">
              <label htmlFor="name">Name:</label>
              <Field type="text" name="name" />
              <ErrorMessage name="name" component="span" />
            </div>
            <div className="field field--email">
              <label htmlFor="email">Email:</label>
              <Field
                type="email"
                name="email"
                placeholder="email@example.com"
              />
              <ErrorMessage name="email" component="span" />
            </div>
            <div className="field field--subject">
              <label htmlFor="subject">Subject:</label>
              <Field type="text" name="subject" />
              <ErrorMessage name="subject" component="span" />
            </div>
            <div className="field field--message">
              <label htmlFor="message">Message:</label>
              <Field name="message" as="textarea" rows={8} />
              <ErrorMessage name="message" component="span" />
            </div>
            {isSubmitting && !isValidating ? (
              'Just a moment ...'
            ) : (
              <button type="submit" className="field field--submit">
                Submit
              </button>
            )}
          </Form>
          )}
        </>
      )}
    </Formik>
  </div>
);

export default ContactUsForm;
```

I chose to put the API request logic into its own function so that in the future I can more easily abstract it into another file and reuse it. Also note the error handling. It's important to remember that even though the form has been validated by Formik there's still potential for errors to happen when processing the submission. For example, Drupal might reject the submitted data, or the API server might be offline.

## Test it out

Now, I can fill in the form:

![](/content/blog_posts/images/gastbychallenge-week4-3.png)

Submit it:

![](/content/blog_posts/images/gastbychallenge-week4-4.png)

Verify the new records are created in Drupal:

![](/content/blog_posts/images/gastbychallenge-week4-5.png)

## Recap

A Gatsby application is *just* a React application. So almost any third-party React library can be used in building the pages of your Gatsby site. Libraries like Formik make form handling in React applications follow a defined pattern which makes it easier to reason about your codebase, and provide helpers to lessen boilerplate code. I used Formik to create a contact form.

Once the form data is collected we need to do something with it. In this case I set up a Drupal Webform to process contact requests that can be accessed via the RESTful API. Then I used JavaScript in my React component to send the collected data to Drupal for processing.

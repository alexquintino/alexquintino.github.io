---
layout: post
page: blog
title: Authentication and Authorization with Auth0 and Sinatra
description: A quick case study of how Faveeo uses Auth0 for user authentication and Sinatra for user authorization
meta_image: /img/auth/auth_1.jpg
twitter_card: summary_large_image
---

<img class="pure-img" src="/img/auth/auth1.jpg">
I recently gave a quick talk at [Geneva's Ruby Meetup][1] called **Authentication and Authorization with Auth0 and Sinatra: A Case Study**. This is a text version of it.

<img class="pure-img" src="/img/auth/auth2.jpg">
The talk was about how we at Faveeo implemented user authentication and authorization with Auth0 and a Sinatra application in our new product [Horizons][2]. I decided to give this talk and share it here because I think it's an interesting and unusual setup that is worth sharing with others and to see what opinions we get.    

<img class="pure-img" src="/img/auth/auth3.jpg">
We started with a very simple application composed of a frontend application written in AngularJS that communicates with a API/backend written in Java which has access to a database of magazines. 

<img class="pure-img" src="/img/auth/auth4.jpg">
But of course we needed more. In particular we needed users. And we wanted those users to be able to login through their Twitter account. And because at Faveeo we're a small team, we were looking for something simple and easy to implement. We were also looking to keep our models oblivious of users. A magazine does not need an *owner* to exist.

<img class="pure-img" src="/img/auth/auth5.jpg">
That's when we found Auth0. They are essentially a single point of integration for several identity providers. It's really easy to implement a single sign on system and user authentication works by using signed tokens issued by Auth0.

<img class="pure-img" src="/img/auth/auth6.jpg">
To authenticate users with their Twitter login we had to integrate Auth0 into our frontend application and we had to implement a thin authentication layer in front of our API, which simply validates the issued tokens a blocks any invalid requests.

<img class="pure-img" src="/img/auth/auth7.jpg">
These Auth0 issued tokens are in fact called JWT tokens. JWT stands for JSON Web Tokens and are part of a bigger set of standards currently on the draft stage of becoming an IETF standard.
These tokens are similar in spirit to SAML tokens, but are JSON objects instead, composed of a header, payload and signature which are then encoded in base 64. 
Auth0 has created a very good website explaining what JWT tokens are and showing their structure. I highly recommend you to check it out. [jwt.io][3]

<img class="pure-img" src="/img/auth/auth8.jpg">
Using Auth0 has many benefits that are important to us. The ability to use any OAuth identity provider without having to actually deal with the OAuth protocol is obviously a big one. Other nice things are the great login and AngularJS libraries they provide and the Auth0 dashboard that gives us a good overview of our users.

<img class="pure-img" src="/img/auth/auth9.jpg">
Now that we had authenticated users, we needed to go one step further and be able to authorize them to access certain resources. We were again looking for something simple and quick to integrate but also flexible and granular to be able to support more complex scenarios. We also wanted it to be decoupled and external to our existing code.

<img class="pure-img" src="/img/auth/auth10.jpg">
We decided to jump into the whole microservices hype and build our own authorization microservice that we called the user service. It has one single job - knowing if a user is allowed to do a specific action. The idea was to have it separate from the existing code and infrastructure and with it's own continuous integration and deployment chain. 
One of the reasons we decided to build our own service was because we knew we would be able to implement it quickly and easily with tools like Sinatra and Padrino.
To implement this service we looked at how the user interacts with the frontend application and how the frontend interacts with the API. There's pretty much a one-to-one match between user action and API call. Knowing that, we decided to take our API's url and verb structure and implement an identical API on the service side that answers only HTTP 200 or 401/403 to each request, depending if the user is authorized or not. 

<img class="pure-img" src="/img/auth/auth11.jpg">
Similar to authentication, we now have a thin layer for authorization sitting infront of our API. This layer simply asks the service if the user is allowed to access a certain url (eg: GET /magazines/1234) and let's the request pass or not depending on the answer. 

<img class="pure-img" src="/img/auth/auth12.jpg">

<img class="pure-img" src="/img/auth/auth13.jpg">

<img class="pure-img" src="/img/auth/auth14.jpg">

<img class="pure-img" src="/img/auth/auth15.jpg">


[1]: http://www.meetup.com/genevarb/
[2]: http://horizons.faveeo.com
[3]: http://jwt.io

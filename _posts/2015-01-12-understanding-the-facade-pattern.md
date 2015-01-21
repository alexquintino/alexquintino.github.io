---
layout: post
page: blog
title: "Understanding the Facade Pattern"
description: "an article explaining the Facade and Gateway patterns and their uses"
related_posts: [ "/blog/value-objects"]
---

The Facade pattern is something that I use all the time and it's one of those things that will come naturally to any developer as he becomes more experienced.
Like my previous post, the Facade pattern is very simple and easy to understand but powerful when used in a large codebase.

example 1
-------
The easiest example I can think of is using Ruby's HTTP library. Let's say we need to access an API to search for a user and return true/false if it was/wasn't found:

{% highlight ruby %}
class ExampleUser
  def exists?(name)
    api = "www.example.com/users/search"

    uri = URI(api)
    params = { name: name }
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)

    res.is_a?(Net::HTTPSuccess)
  end
end
{% endhighlight %}

This doesn't look too bad but it's not good either. In a method with 6 lines, 4 are about creating and executing an HTTP request. Imagine interacting with this API in other places of your code (like searching for products). We would end up with more blocks of code similar to this one. Besides, whatever class this is, it shouldn't know anything about how to construct the request or even that it's using Ruby's HTTP library.

It would be nice if the HTTP library had a simple method that we pass our parameters to and receive an answer...




example 2
---------
Imagine we run an e-commerce shop and a customer just purchased something. There's probably going to be several things we need to do when that happens. We might have something like this in a controller:

{% highlight ruby %}

class Shop
  def purchase
    user = User.find(params[:user_id])
    product = Product.find(params[:product_id])

    if user.has_enough?(product.price)
      user.update_balance(product.price)
      tracking_code = Shipping.ship_product(user.address, product.id)
      email = "Thanks for purchasing #{ product.name }. Here's your tracking code: #{ tracking_code }"
      Email.send_email(email)
    end
  end
end
{% endhighlight %}

This is, of course, very simplified but you get the point. This code might look OK but it feels like there's a bit too much going on, too much responsibility in one single place. This class most likely will have other methods and if they all look like this, the class will be bloated; with too much knowledge.




the Facade
----------
The [Facade pattern](https://en.wikipedia.org/wiki/Facade_pattern)'s objective is to provide a simplified version of an existing interface(s). In practice, this could mean providing a simple method that calls a complicated to use external library or grouping interactions between different objects into one method.

The advantages of applying this pattern are many:

-  an external library is easier to use for the common cases of our code - code is easier to read
-  a set of related interactions can be abstracted away into a single place - code is easier to read
-  helps enforcing the [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single_responsibility_principle)
-  makes it easier to test the code - the facade class becomes the obvious place to introduce stubs



example 1 with a Facade
-----------------------
Let's look at example 1 again and introduce a facade to abstract away all the knowledge about dealing with HTTP:
{% highlight ruby %}

class HTTPFacade
  def self.success?(url, params = {})
    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)

    res.is_a?(Net::HTTPSuccess)
  end
end

class ExampleUser
  def exists?(name)
    api = "www.example.com/users/search"
    params = { name: name }

    HTTPFacade.success?(api, params)
  end
end
{% endhighlight %}

With this code we have successfully separated the responsibilities of "verifying if a user exists" and "doing an HTTP get request and checking if it was successful" into separate classes. The exists? method is now smaller and easier to test. And we can reuse the HTTPFacade in other parts of the code easily.



example 2 with a Facade
-----------------------
Applying the facade to example 2 we would get:

{% highlight ruby %}
class PurchaseFacade
  def finish_purchase(user, product)
    if user.has_enough?(product.price)
      user.update_balance(product.price)
      tracking_code = Shipping.ship_product(user.address, product.id)
      email = "Thanks for purchasing #{ product.name }. Here's your tracking code: #{ tracking_code }"
      Email.send_email(email)
    end
  end
end

class Shop
  def purchase
    user = User.find(params[:user_id])
    product = Product.find(params[:product_id])

    PurchaseFacade.finish_purchase(user, product)
  end
end
{% endhighlight %}

In this example we've separated the responsibility of "finishing a purchase" and "actually knowing and calling the different services to finish a purchase" into different classes. As with the previous example, the purchase method is smaller and both purchase and finish_purchase methods are easier to test.

This is actually the foundation for Service Objects that I'll discuss in a later post.


Facade methods with ActiveRecord
--------------------------------
The Facade pattern refers to objects but we can easily apply it to methods when using ActiveRecord. Best pratices for ActiveRecord say that we should not leak ActiveRecord methods outside of ActiveRecord models. So instead of:

{% highlight ruby %}
  Post.where(pub_date: 1.month.ago..Time.now).where(author: user.id).first(10)
{% endhighlight %}

we could have:

{% highlight ruby %}
class Post
  # (...)
  def self.published_last_month(user_id)
    self.where(pub_date: 1.month.ago..Time.now).where(author: user_id).first(10)
  end
end

Post.published_last_month(user.id)
{% endhighlight %}

With this, we simplified the interface to get last month's posts, moved the knowledge on how to get the posts into the Post class and abstracted away any ActiveRecord details. We applied the concept of a Facade object but on a method level. In fact, this is more or less what [scopes](http://guides.rubyonrails.org/active_record_querying.html#scopes) do behind the scenes.


Gateway Pattern
---------------
I would like to quickly mention the Gateway pattern since it's very much related to the Facade. Martin Fowler defines [Gateway](http://martinfowler.com/eaaCatalog/gateway.html), in his Patterns of Enterprise Application Architecture book, as "an object that encapsulates access to an external system or resource". In my opinion, this is a specific usage of the Facade since it's implemented in the same away and it shares the same advantages.

In fact, we can take example 1 and implement a Gateway:
{% highlight ruby %}

class HTTPFacade
  def self.success?(url, params = {})
    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)

    res.is_a?(Net::HTTPSuccess)
  end
end

class ExampleGateway
  API = "www.example.com"

  def self.users_search(name)
    api = API + "/users/search"
    params = { name: name }
    HTTPFacade.success?(api, params)
  end
end

class ExampleUser
  def exists?(name)
    ExampleGateway.user_search(name)
  end
end
{% endhighlight %}

This time, we added another level of abstraction. The method exists? is now one line and the ExampleGateway is now the single point of contact in the whole application for the example.com API. Responsibilities are more separated than before and readability of the code improved.

conclusion
----------
That's all I have about the Facade Pattern. As always with this kind of posts, the examples are heavily simplified for the sake of clarity and don't carry any sense of scale. It might not be obvious the need to apply this pattern. So please imagine these examples as part of a much bigger App. When dealing with thousands of lines of code, this kind of patterns matter.


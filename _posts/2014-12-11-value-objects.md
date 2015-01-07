---
layout: post
title: Value Objects
page: blog
description: "a small article about what value objects are and how to use them"
---

I began reading Martin Fowler's [Patterns of Enterprise Application Architecture](http://martinfowler.com/books/eaa.html) recently and it gave me the idea to start a series of posts about what I consider to be the most important [patterns](https://en.wikipedia.org/wiki/Software_design_pattern) and about those that I have used and seen in the wild. I'll try to explain them in a simpler and pragmatic way.
I decided to start with Value Objects because they are quite simple to understand but powerful to use when the size of a code base increases.

example
-------
Let's begin with an example. Imagine you're doing a registration page and ask your user for his first name and last name. At some point in your code you might have:

{% highlight ruby %}
def register
  User.register(params[:first_name], params[:last_name])
end
{% endhighlight %}

And this might look fine right now, since it's a very basic registration. Let's add more data, like the users birth date:

{% highlight ruby %}
def register
  User.register(params[:first_name], params[:last_name], params[:day], params[:month], params[:year])
end
{% endhighlight %}

By now you should be seeing a red flag. There's 5 arguments being passed to the register method. Although the right amount of arguments is debatable, it's a good practice to pass as fewer arguments as possible. It improves code readability, testability and reduces the chance of bugs. This becomes painfully obvious if we also add a user's address(street name, postal code, city, etc) to the list of arguments.

Passing too many arguments is a clear case of what's called a [code smell](https://en.wikipedia.org/wiki/Code_smell). A code smell is a warning that maybe something is wrong and something (e.g. refactoring) should be done about it.

enter Value Objects
-------------------
Value Objects are a very simple way to introduce [encapsulation](https://en.wikipedia.org/wiki/Information_hiding) or data abstraction. The main idea is to have a simple object that relates to your application's domain and groups together several related values. Enclosing those values in one object allows you to forget about the details of those values and handle the object as a single entity with a [single responsability](https://en.wikipedia.org/wiki/Single_responsibility_principle). Although you create more classes, your code is better organized and more focused.

Another advantage of using Value Objects is that the class becomes the perfect place to put utility methods that manipulate data, instead of having them laying around in other classes.

example with Value Objects
-------------------------
Refactoring the previous example with Value Objects and also adding the address, we would get:

{% highlight ruby %}
def register
  name = Name.new(params[:first_name], params[:last_name])
  birth_date = Date.new(params[:day], params[:month], params[:year])
  address = Address.new(params[:street], params[:postal_code], params[:city])

  User.register(name, birth_date, address)
end
{% endhighlight %}

This should be a bit clearer than the previous example. Although we have more lines of code, each line is simple and small. But the biggest gain here is that we're passing more information to the register method, with less arguments. If we would need to debug the User.register method, it would be easier to focus on only 3 parameters rather than 8. It also makes it harder to introduce bugs like forgetting one argument or changing their order.

Besides that, we can now introduce utility methods in the classes we just created. For example, we can use the Name class to implement a full_name method that takes the first and last names and combines them, like so:

{% highlight ruby %}
def full_name
  "#{last_name}, #{first_name}"
end
{% endhighlight %}

This way, the knowledge or logic of how to return a full name is enclosed in the Name class, as it should be.

The concept of Value Objects is a proven one and quite widespread. In fact, the [Date](http://www.ruby-doc.org/stdlib-2.1.5/libdoc/date/rdoc/Date.html) class is already included in Ruby's standard library, so no need to create or own. Other examples of Value Objects would be [IPAddr](http://www.ruby-doc.org/stdlib-2.1.5/libdoc/ipaddr/rdoc/IPAddr.html) or [URI](http://www.ruby-doc.org/stdlib-2.1.5/libdoc/uri/rdoc/URI.html). Other common Value Objects that you might create or find in other applications are Money objects for handling money and currency amounts, Point objects to represent a coordinate in a 2D/3D space or Distance objects to hold a distance and it's unit type.

I hope you understood the pattern of Value Objects and let me know if you have any questions!







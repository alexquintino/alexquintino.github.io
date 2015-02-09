---
layout: post
page: blog
title: "Processing over 50 million items: first steps with Apache Spark"
description:
---

I've been playing with the [data dumps from Discogs](http://www.discogs.com/data/) and needed to parse and analyze a lot of data quickly. Even though these dumps are not massive, this was a good opportunity to take a look at the "Big Data" world and get to know some of its tools. After some research, [Apache Spark](https://spark.apache.org/) seems to be the hottest thing right now so I decided to give it a go!

Setup and First impressions
---------------------------
Let's get started by installing Spark:

-  make sure you have Java installed by running `java -version`
-  download a [pre-built version of Apache Spark](https://spark.apache.org/downloads.html) and untar it with `tar -xzvf spark-1.2.0-bin-hadoop2.4.tgz`
-  we should now be able to run spark for the first time. Spark provides a couple of examples so let's run that:
{% highlight console %} ./bin/run-example SparkPi 10  {% endhighlight %}
-  Dozens of log messages after, we see something like `"Pi is roughly 3.140612"`.

I guess it worked!

A lot happened until that line was printed and I wanted to understand exactly what, so after some digging this is what I got:

-  Spark ran the scala class SparkPi (a simple class to approximate the value of Pi) connected to a local cluster.
-  It then sent the JAR file with the class to the worker nodes.
-  The class takes the argument passed to it and parallelizes the calculation into *n* number of tasks (in a local environment, tasks = threads)
-  After that, the reduce method in the code triggers a job to start and sends the *n* tasks to be executed.
{% highlight console %}
INFO SparkContext: Starting job: reduce at SparkPi.scala:35
(...)
INFO TaskSchedulerImpl: Adding task set 0.0 with 10 tasks
{% endhighlight %}
-  The tasks, now running on the local cluster, do their thing and finish one by one sending the results of their calculations back to whoever started the tasks (the Driver)
{% highlight console %}
INFO Executor: Finished task 3.0 in stage 0.0 (TID 3). 727 bytes result sent to driver
INFO TaskSetManager: Finished task 3.0 in stage 0.0 (TID 3) in 967 ms on localhost (1/10)
{% endhighlight %}
- Until the job completes and the result is printed
{% highlight console %}
INFO DAGScheduler: Job 0 finished: reduce at SparkPi.scala:35, took 1.343225 s
Pi is roughly 3.143028
{% endhighlight %}

This is of course a very simple scenario but shows some of the power in Apache Spark. The great thing about Spark is it's RDD(Resilient Distributed Dataset) abstraction that wraps a collection and allows to execute operations on that collection in a parallel and distributed way. This enables the code that just ran on my laptop, to run across a cluster with hundreds of machines, without any changes. I think that's very powerful.

Tackling a bigger problem
-------------------------
After checking out some of the examples, I started playing around with Spark and had a go at solving my own problems.

I had been developing some simple scripts, in Ruby, to parse the XML dumps from Discogs and output a [TSV](https://en.wikipedia.org/wiki/Tab-separated_values) with each line holding the information from each artist/release. I wanted to convert them into Scala and use Spark to process them. The most common way to read files with Spark is through it's *textFile* which will read the file and return a string for each line.

And that was my first problem with Spark. I had a XML to parse and not every line was an item. After some research I could not find an easy way to do it and since I already had the Ruby scripts I decided to postpone that to another time and carried on with other things.



### Example 1
Besides parsing XML files, another thing I wanted to do was to filter out all the artists and their releases based on a list of favorite artists. This turned out to be a breeze with Apache Spark, using mostly **map** and **filter** functions over TSV files. Below is a sample of the code to go through all the tracks and select the ones that contain any of the artists from a given list. Full class [here](https://github.com/alexquintino/discogs-parser/blob/master/scala/src/main/scala/FilterArtistsAndReleases.scala).

{% highlight scala %}
def main(args: Array[String]) {
  // artist_id / name
  val artistsIds = sc.textFile("output/artists_with_ids")
                      .map(_.split("\t"))
                      .map(artist => artist(0))
                      .collect.toSet

  // release_id / artists / title / remixers - filter out empty tracks
  val tracks = sc.textFile("output/discogs_tracks.tsv").map(_.split("\t")).filter(_.size > 2).cache()

  // release ids taken from selected tracks - there will be repeated releases
  val releaseIdsFromTracks = grabTracksForArtists(tracks, artistsIds).map(track => track(0)).distinct.collect.toSet

  // (...)
}


def grabTracksForArtists(tracks: RDD[Array[String]], artistsIds: Set[String]): RDD[Array[String]] = {
  tracks.filter(track => containsArtists(trackArtists(track), artistsIds))
}

// checks if the artists in an Array are present in a Set of artists. Then reduces it to a single true/false
def containsArtists(artists: Array[String], artists_ids: Set[String]): Boolean = {
  artists.map(id => artists_ids.contains(id)).fold(false)((bool, res) => bool || res)
}
{% endhighlight %}

I think the code is quite simple to understand. There's just a bunch of **map** modifying the data to my needs and **filter** to select the items: first steps I want according to a function. There's also **collect** that actually triggers a job and returns the results in an array, **distinct** that goes over a collection and removes duplicates and **cache** that tells Spark to cache that collection in memory to improve performance when using it later.

Another cool thing about Spark is it's Web UI that I found out while waiting for this job to finish. It let's you checkout the status of your job and tasks and gives you an overview of your cluster, among other things.
<img class="pure-img" src="/img/spark-ui.jpg" alt="Apache Spark's Web UI" title="Apache Spark's Web UI">

### Example 2
Here's a sample of another class I wrote while playing around with Spark (full class [here](https://github.com/alexquintino/discogs-parser/blob/master/scala/src/main/scala/OutputNodesAndRelationships.scala)). This time to output each artist/release/track as nodes, and output all the relationships between each node. As a limitation of the tool that I'm feeding this data into, I had to come up with a unique index in the dataset to be used when outputting the relationships.

{% highlight scala %}
def main(args: Array[String]) {

  // get list of artists with index
  val artists = getArtists(sc.textFile("output/artists_with_ids", 1))
  val artistsLastIndex = artists.map(_(0).toLong).max

  // get releases with index based on the artists max index
  val releases = getReleases(sc.textFile("output/releases", 1), artistsLastIndex)

  extractArtistsReleasesRelationships(artists, releases)
    .map(_.mkString("\t"))
    .saveAsTextFile("output/artist_release_relationships")
}

// join artists with releases
def extractArtistsReleasesRelationships(artists: RDD[Array[String]], releases: RDD[Array[String]]): RDD[List[Any]] = {
  val artistsMap = artists.map(artist => (artist(1), artist(0)))
  val releasesMap =  releases.flatMap(restructureRelease)
  artistsMap.join(releasesMap)
             .map(extractArtistReleaseRelationship)
}

def restructureRelease(release: Array[String]): Array[(String, String)] = {
  val artists = release(4)
  artists.split(",").map{
    artist => (artist, release(0)) //from (id, artists) to (artistId, id)
  }
}

def extractArtistReleaseRelationship(rel: (String, (String, String))): List[Any] = {
  List(rel._2._1, rel._2._2, "HAS_TRACKLIST")
}
{% endhighlight %}

The interesting thing here happens in **extractArtistsReleasesRelationships** where I'm creating a key-value map of artists and of releases, based on the artist's Id and then joining those maps together. The result is a list of associations between artists and releases nodes. From that I extract the indexes of each artist and release and output that to a file.

The output will be something like:

{% highlight text %}
artists_nodes - indexes / id / name / type
25944 25944 Mars  Artist
430816  430816  Gary Beck Artist
{% endhighlight %}

{% highlight text %}
tracklist_nodes - index / id / name / type
6825338 2984922 Got My Mind Made Up Tracklist
6825400 2984984 Red D Meets Vol 1 Tracklist
{% endhighlight %}

{% highlight text %}
artist_release_relationships - start / end / type
25944 6825338 HAS_TRACKLIST
430816 6825400 HAS_TRACKLIST
{% endhighlight %}

Final Impressions
-----------------
I really really like Apache Spark. Getting started with it was very simple and I was quickly doing interesting things with it. The barrier to entry is very low. It's very easy to forget that you're dealing with Spark and not just a normal collection. Spark can be very transparent in the sense that it shares some of the API of normal collections. **filter**, **map**, **reduce** are all methods of normal collections.

With all this easiness, it's only when you look at logs or the web dashboard that you're reminded of all the heavy work that Spark is doing behind the scenes. It's impressive.

I'm sure the code I wrote could be improved and optimized, specially if I was handling more data in a bigger cluster

And I have only scratched the surface! There's much more to Spark than what I used so far. For one, I have been running it all in my laptop, but Spark is made to run in big clusters and has a bunch of features to handle that. There's also [Spark Streaming](https://spark.apache.org/streaming/) to process streams of data, [GraphX](https://spark.apache.org/graphx/) to process graphs or Spark's machine learning library [MLib](https://spark.apache.org/mllib/). And I'm sure as I handle more data in bigger clusters, I'll find myself digging deeper into Spark to improve my code's performance and reduce run time.

With all that said, I'm looking forward to explore more of Apache Spark!

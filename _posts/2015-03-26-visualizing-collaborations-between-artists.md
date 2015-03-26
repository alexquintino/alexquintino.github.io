---
layout: post
page: blog
title: Visualizing collaborations between artists
description: I analyzed my Spotify music collection and visualized the relationships between artists to see what interesting things come up.
related_posts: ["/blog/processing-over-50-million-items-with-apache-spark"]
meta_image: /img/artist_vis/1024x_overview_no_labels.jpg
twitter_card: summary_large_image
enable_click_tracking: true
---

Continuing the work from my [previous post](/blog/processing-over-50-million-items-with-apache-spark/), I thought it would be a cool thing to analyze my Spotify music collection and try to visualize the relationships between artists and see what interesting things come up. Here's what I found out!

overview
--------
This is how the graph looks like (large version <a href="/img/artist_vis/overview.png" class="external-link">here</a>)
<img class="pure-img" src="/img/artist_vis/1024x_overview.jpg" alt="Overview" title="Overview">

There are 1171 nodes and 7376 edges (created from 47268 connections). Each node is an artist, and each edge is a collaboration between 2 artists. The nodes' size is proportional to the number of collaborations with different artists (degree) while the edges' thickness is proportional to the number of collaborations between the 2 artists (edge weight).

A collaboration between artists can be a track shared by 2 artists, a remix by artist B of a track from artist A, a release shared by 2 artists or a release from an artist with tracks from other artists.

analysis
--------

### major players
Looking at the graph we can spot a couple of large nodes. Radio Slave, Nic Fanciulli and Carl Craig, big names in the Deep/Tech house scene, lead the chart in terms of highest degree (number of edges connecting to it) with 83, 82 and 78 respectively.
<img class="pure-img" src="/img/artist_vis/1024x_radioslave_edges.jpg" alt="Radio Slave" title="Radio Slave">

If we take into account the total number of collaborations (weighted degree), then an interesting trio of artists appears with Stan Getz, João Gilberto and Astrud Gilberto having the highest weighted degrees (1616, 1268, 1179 respectively) and being responsible for the Bossa Nova blob.

An interesting metric to look at is PageRank, the algorithm created by Google to rank web pages according to how important they are in the overall graph of web pages. With this metric we have 3 big names in music: Snoop Dog, Kanye West and David Bowie.

Another interesting metric is betweenness centrality which in this case will be artists that are the connection between different groups of artists. The top 3 here are Groove Armada, Gilles Peterson and Nic Fanciulli.

### clusters
One of the main things I was hoping to see on the graph was clusters of similar artists and, in a way, representing different styles of music. In the end I was quite happy to see that the graph produced a couple of them. Kudos to Gephi for making it really easy. Large version <a href="/img/artist_vis/clusters.png" class="external-link">here</a>.
<img class="pure-img" src="/img/artist_vis/1024x_clusters.jpg" alt="Clusters" title="Clusters">

Here are some of them in more detail. The Hip Hop and R&B cluster:
<img class="pure-img" src="/img/artist_vis/1024x_cluster_rnb_hiphop.jpg" alt="Hip Hop and RNB cluster" title="Hip Hop and RNB cluster">

The two rock clusters:
<img class="pure-img" src="/img/artist_vis/1024x_cluster_rock.jpg" alt="Rock cluster" title="Rock cluster">

And the tiny but powerful Bossa Nova cluster. This blob comes mostly from collaborations between Stan Getz, João Gilberto and Astrud Gilberto
<img class="pure-img" src="/img/artist_vis/1024x_cluster_bossa_nova.jpg" alt="Bossa Nova cluster" title="Bossa Nova cluster">

However the biggest cluster is not so obvious to spot. Looking at the whole graph we can see that green is by far the predominant color and is literally all over the graph. The green cluster is pretty much just electronic music and together with the red and blue clusters, they are responsible for around 40% of the graph. Which is not surprising given the nature of electronic music where it's super common to collaborate with other artists in the form of remixes or compilations / DJ sets. Larger version <a href="/img/artist_vis/cluster_electronic_music.png" class="external-link">here</a>
<img class="pure-img" src="/img/artist_vis/1024x_cluster_electronic_music.jpg" alt="Electronic Music cluster" title="Electronic Music cluster">

methodology
-----------
Here's what I did to create this graph:

- I used custom software ([Spotify Extractor](https://github.com/alexquintino/spotify-extractor)) to download track information from my Spotify playlists and pass that to a parser ([TrackParser](https://github.com/alexquintino/track_parser)) in order to extract a full list of artists (main artists, remixers and featuring artists).
- Then I processed the Discogs dataset to match the artists to the ones in my playlists and extract the relevant nodes and relationships between artists<->releases<->tracks.
- Imported those nodes and relationships into Neo4j
- And queried the database for relationships between artists based on releases and tracks in common, up to 2 levels deep
{% highlight cypher %}
MATCH (n:Artist)-[*1..2]->()<--(m:Artist) WHERE NOT id(n)=id(m) RETURN n.discogs_id,m.discogs_id
{% endhighlight %}
- Finally, I used Gephi to load the query output and create the graphs

shortcomings
------------

### Matching artists betwen Spotify and Discogs
The whole process to reach these graphs is far from perfect but the biggest flaw right now is matching artists between Spotify data and Discogs data. Currently I'm doing a basic case insensitive match of the artists names. This works for the majority of artists but fails when artists have variations of names (*Amirali* on Spotify vs *Amirali Shahrestani* on Discogs) or when there are multiple artists with the same name (*Tini* on Spotify vs *Tini* and *tINI (2)* on Discogs).

### Extracting artists from a track
Given that there is no standard way to display a track's artists, name, remixes, etc. it is sometimes hard to extract the correct list of artists without more information (like a list of artists to compare to). I developed a small [library](https://github.com/alexquintino/track_parser) that does it's best trying to extract the different fields of track but, although it takes care of most cases without a problem, still fails on some situations (like *Kollektiv Turmstrasse - Ordinary (Lake People Circle Motive Remix)* returning *Lake People Circle Motive* as artist instead of *Lake People*)


going deeper
------------
There was still one thing left that I wanted to do. I went back to Neo4J and fired up this query:
{% highlight cypher %}
MATCH (n:Artist)-->(:Track)<--(l:Tracklist) WITH n,l MATCH l-->(:Track)<--(m:Artist) WHERE NOT id(n)=id(m) RETURN n.discogs_id, m.discogs_id
{% endhighlight %}

Which would hopefully return all relationships between artists that were part of the same album or compilation.
After awhile the query returned with about 1.6 million connections! I loaded it up on Gephi and it produced this (you really should check the large version <a href="/img/artist_vis/overview_tracklist_common.png" class="external-link">here</a>:
<img class="pure-img" src="/img/artist_vis/1024x_overview_tracklist_common.jpg" alt="Overview Tracklists in Common" title="Overview Tracklists in Common">
What a beauty...

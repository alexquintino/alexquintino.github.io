---
---

width = 500
height = 450
color = d3.scale.category20c();

bubble = d3.layout.pack()
  .sort(null)
  .size([width, height])
  .padding(1.5);

svg = d3.select("#skills").append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("class", "bubble")

d3.json("skills.json", (error, skills) ->
  skill = svg.selectAll(".node")
            .data(bubble.nodes(skills)
              .filter((d) -> !d.children))
            .enter().append("g")
              .attr("class", (d) -> "skill")
              .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")" )

  skill.append("title").text((d) ->  d.name)

  skill.append("circle")
      .attr("r", (d) -> d.r)
      .attr("class", (d) -> d.type)

  skill.append("text")
    .attr("y", (d) -> yValue(d.name))
    .style("font-size", (d) -> fontSize(d.name, d.value))
    .html((d) -> tSpans(d.name))
  )

fontSize = (name, value) ->
  nameSizeMultiplier = 2.5/name.length
  valueMultiplier = value/3
  nameSizeMultiplier + valueMultiplier + "rem"

yValue = (name) ->
  size = name.split(" ").length
  if size == 1
    "-0.7em"
  else if size == 2
    "-1.1em"
  else
    "-1.7em"

tSpans = (text) ->
  splits = text.split(" ")
  splitsSize = splits.size
  splits.map((t) -> '<tspan x="0" dy="1em">' + t + "</tspan>").join("")



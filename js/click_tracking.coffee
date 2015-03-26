---
---
addListener = (element, type, callback) ->
 if (element.addEventListener)
  element.addEventListener(type, callback)
 else
  if (element.attachEvent)
    element.attachEvent('on' + type, callback)

links = document.getElementsByClassName('external-link')

addListener(link, 'click', () ->
  ga('send', 'event', 'links', 'click', link.getAttribute('href'))
) for link in links


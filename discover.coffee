#
# Spider a website (including the JavaScript-generated bits) with
# a virtual browser and print every url (web page, .js, .css, images)
# that we discover.
#
# Usage:
#  phantomjs discover.coffee URL > urls.txt
#

if phantom.args.length < 1
  console.log 'Usage:  discover.coffee URL'
  phantom.exit()

seed = phantom.args[0]

urls_seen = {}
urls_seen[seed] = true
urls_printed = {}
url_queue = [seed]

finish_timeout = null

page = new WebPage()

page.onResourceRequested = (req) ->
  if not urls_printed[req.url]
    urls_printed[req.url] = true
    console.log req.url
  # there is no way to see if we're done, so we just
  # set a timer of 10 seconds, which we restart every
  # time we get something new
  clearTimeout(finish_timeout) if finish_timeout
  finish_timeout = setTimeout(phantom.exit, 10000)

page.onLoadFinished = (status) ->
  if status == 'success'
    # pages with a meta refresh tag will continue
    # by themselves, we don't have to click links
    contains_refresh = page.evaluate ->
      refresh = false
      for meta in document.getElementsByTagName 'META'
        if meta.getAttribute('http-equiv') == 'refresh'
          refresh = true
      refresh

    # for non-refreshing pages, we discover every link on the page
    if not contains_refresh
      urls = page.evaluate ->
        for link in document.getElementsByTagName 'A'
          link.href
      
      for url in urls
        if url.indexOf(seed) == 0 and not url.match(/#/) and not urls_seen[url]
          urls_seen[url] = true
          url_queue.push url

      if url = url_queue.shift()
        page.open url

# kick off
page.open url_queue.shift()


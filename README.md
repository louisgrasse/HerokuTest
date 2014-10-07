## Fulcrum Dispatch

Fulcrum dispatch is a simple record dispatching and assignment app built using fulcrum-node.  The intent is to demonstrate a small amount of functionality with commented source code to help facilitate building exactly what you need.  With the app, a dispatcher can assign records, representing appointments, to technicians by dragging and dropping them on the technicians job queue.  A map is displayed showing the location of each appointment. 

<video src="http://www.fulcrumapp.com/assets/img/blog/fulcrum-dispatch-app-720.mp4" controls>
  You can see the application in action here: <a href="http://www.fulcrumapp.com/assets/img/blog/fulcrum-dispatch-app-720.mp4">Video</a>
</video>

### Development

The server side is built on node.js and written in CoffeeScript so you'll need to install the necessary dependencies first:

```bash
cd /path/to/fulcrum-dispatch
npm install
```

Start the web server with:

```bash
npm start
```

The front-end is also written in CoffeeScript and bundled with Browserify. Use the watch command to track any changes to files in `/assets/js/src` and automatically compile and bundle with browserify:

```bash
npm run watch
```

It's probably best, though, to simply use the dev command to run the web server and watch the front-end at the same time:

```bash
npm run dev
```

To compile CoffeeScript for deployment, be sure to use the build command, not watch:

```bash
npm run build
```

#### Environment Variables

You'll need to set a couple environment variables that allow you to communicate with the Fulcrum API.

```bash
heroku config:set FULCRUM_API_KEY=super_long_string_that_is_a_secret
heroku config:set FULCRUM_FORM_ID=abc-123-def-456
heroku config:set FULCRUM_TECHNICIAN_ROLE_ID=abc-123-def-456
heroku config:set FULCRUM_DISPATCHER_ROLE_ID=abc-123-def-456
heroku config:set FULCRUM_API_URL=https://web.fulcrumapp.com/api/v2/
```

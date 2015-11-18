http                = require('http')
express             = require('express')
_                   = require('underscore')
moment              = require('moment')
bodyParser          = require('body-parser')
path                = require('path')
favicon             = require('serve-favicon')
fs                  = require('fs')
yaml                = require('js-yaml')
basicAuth           = require('basic-auth-connect')
mongodb             = require('mongodb')
MongoClient         = mongodb.MongoClient
ObjectID            = mongodb.ObjectID
connectionString    = 'mongodb://127.0.0.1:27017/timeline'
dbEvent             = null

# Connet to mongodb
connectToMongo = MongoClient.connect connectionString, (err, db) ->
  if (!err)
    console.log('connected to', connectionString)
    dbEvent = db.collection('events')

# Function to load files from our data folder
getDataFile = (file) ->
  try
    filepath = path.join(basePath, 'data', file)
    doc = yaml.safeLoad(fs.readFileSync(filepath, 'utf8'))
  catch err
    console.log(err)

# Express server!
app           = express()
webserver     = http.createServer(app)
basePath      = path.dirname(require.main.filename)
generatedPath = path.join(basePath, '.generated')
vendorPath    = path.join(basePath, 'bower_components')
faviconPath   = path.join(basePath, 'app', 'favicon.ico')

# Get our data file
config  = getDataFile('config.yaml')

# Use Basic Auth?
if config.username? || config.password?
  app.use(basicAuth(config.username, config.password)) if process.env.DYNO?

# Express configuration
app.engine('.html', require('hbs').__express)
app.use(favicon(faviconPath))
app.use('/assets', express.static(generatedPath))
app.use('/vendor', express.static(vendorPath))
app.use(bodyParser.json())
app.use(bodyParser.urlencoded())

# Port configuration
port = process.env.PORT || 3002
app.listen port, (err) ->
  console.log('server is up at port', port)

# Routes
app.get '/', (req, res) ->
  dbEvent.find().toArray (err, events) ->
    # sort events
    events = _.sortBy events, (event) ->
      return moment(event.date, 'MMM dd, YYYY')

    # reverse
    events.reverse()

    res.render(generatedPath + '/index.html', {data: {updates: events}})

# add
app.get '/add', (req, res) ->
  res.render(generatedPath + '/add.html')

# add api
app.post '/events', (req, res) ->
  data = req.body

  dbEvent.insert data, (err, event) ->
    res.send(event)

# delete api
app.get '/events/remove/:id', (req, res) ->
  dbEvent.remove {_id: ObjectID(req.params.id)}, (err, result) ->
    res.send(result)


module.exports = app

##############################################################################
########################## Sample Records ####################################
"updates": [
    {
        "date": "July 15, 2014",
        "title": "Visited Google Website",
        "item": [
            {
                "title": "View google.com",
                "url": "http://google.com"
            }
        ]
    },
    {
        "date": "July 14, 2014",
        "title": "High-fived a friend!",
        "item": [
            {
                "title": "View the high-five!",
                "url": "https://s3.amazonaws.com/giphymedia/media/WKdPOVCG5LPaM/giphy.gif"
            },
            {
                "title": "View the celebration",
                "url": "http://media.giphy.com/media/aTUAoYk7Tj87S/giphy.gif"
            }
        ]
    }
]
##############################################################################
##############################################################################

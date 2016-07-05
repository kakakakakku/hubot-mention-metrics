# Description:
#   Post mention metrics to Mackerel Service Metrics

URL = 'https://mackerel.io/api/v0/services'

module.exports = (robot) ->

  robot.hear /@here/i, (msg) ->
    unless isSetMackerelApiKey msg
      return
    unless isSetMackerelServiceName msg
      return
    postMetric(robot, 'slack.mention.here')

  robot.hear /@channel/i, (msg) ->
    unless isSetMackerelApiKey msg
      return
    unless isSetMackerelServiceName msg
      return
    postMetric(robot, 'slack.mention.channel')

  robot.hear /@everyone/i, (msg) ->
    unless isSetMackerelApiKey msg
      return
    unless isSetMackerelServiceName msg
      return
    postMetric(robot, 'slack.mention.everyone')

isSetMackerelApiKey = (msg) ->
  if process.env.HUBOT_MACKEREL_API_KEY?
    return true
  msg.send '"HUBOT_MACKEREL_API_KEY" is not set.'
  return false

isSetMackerelServiceName = (msg) ->
  if process.env.HUBOT_MACKEREL_SERVICE_NAME?
    return true
  msg.send '"HUBOT_MACKEREL_SERVICE_NAME" is not set.'
  return false

postMetric = (robot, metricName) ->

  from = (new Date/1000|0) - 259200
  to = new Date/1000|0

  mackerelApiUrlMetrics = "#{URL}/#{process.env.HUBOT_MACKEREL_SERVICE_NAME}/metrics?name=#{metricName}&from=#{from}&to=#{to}"

  robot.http(mackerelApiUrlMetrics)
    .header('X-Api-Key', process.env.HUBOT_MACKEREL_API_KEY)
    .get() (err, res, body) ->
      if res.statusCode isnt 200
        callTsdbApi(robot, metricName, 1)
        return
      response = JSON.parse body
      callTsdbApi(robot, metricName, response.metrics[response.metrics.length - 1].value + 1)

callTsdbApi = (robot, metricName, metricValue) ->
  mackerelApiUrlTsdb = "#{URL}/#{process.env.HUBOT_MACKEREL_SERVICE_NAME}/tsdb"
  json = JSON.stringify(
    [
      {
        name: metricName,
        time: new Date/1000|0,
        value: metricValue
      }
    ]
  )

  robot.http(mackerelApiUrlTsdb)
    .header('X-Api-Key', process.env.HUBOT_MACKEREL_API_KEY)
    .header('Content-Type', 'application/json')
    .post(json)

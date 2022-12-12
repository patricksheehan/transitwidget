# TransitWidget
An iOS widget to get realtime transit info quickly.


## GPT journey

"Write a swift function which uses protobuf and GTFS-RT to fetch a transit feed message given a url"
"Write a swift function which takes a list of stops from the Transit package and a location and returns the closest stop to the location"
"""
struct RouteArrivals: Identifiable {
    let id = UUID()
    let routeName: String
    let arrivalMinutes: [Int]
}

// Get all the arrival times from the feed for the given stop and return them as a list of RouteArrivals
func getArrivalTimes(stop: Stop, feedMessage: FeedMessage) -> List[RouteArrivals] {
"""

curl https://api.openai.com/v1/completions \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_API_KEY' \
  -d '{
  "model": "code-davinci-003",
  "prompt": "",
  "max_tokens": 7,
  "temperature": 0
}'

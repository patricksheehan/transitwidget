import os
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

prompt = """
struct RouteArrivals: Identifiable {
    let id = UUID()
    let routeName: String
    let arrivalMinutes: [Int]
}

// Get all the arrival times from the feed for the given stop and return them as a list of RouteArrivals
func getArrivalTimes(stop: Stop, feedMessage: FeedMessage) -> List[RouteArrivals] {
"""
response = openai.Completion.create(model="code-davinci-002", prompt=prompt, temperature=0, max_tokens=7)
print(response)
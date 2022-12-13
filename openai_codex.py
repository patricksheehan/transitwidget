import os
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

prompt = """write a swift class that parses a GTFS folder and is initialized by a url path to the folder"""
response = openai.Completion.create(model="code-davinci-001", prompt=prompt, temperature=0, max_tokens=4000)
print(response)


import os, httpclient, random, json, strutils

var api = "https://api.provesrc.com/webhooks/track/a0630392903eb61624fab661e0b7cd3f"
var locations = readFile("locations.txt").splitLines()
var names = readFile("names.txt").splitLines()
var products = readFile("products.txt").splitLines()

var client = newHttpClient()

client.headers = newHttpHeaders({"Content-Type":"application/json"})

while true:
  let data = %*{
    "email":"adejumoadeoluwa@gmail.com",
    "firstName":random.sample(names),
    "city":random.sample(locations),
    "productName":random.sample(products),
    "ip":"197.210.29.255"
    }

  echo "POSTING... ", $data
  let response = client.post(api, $data)
  echo "UPDATE: ", $response.body
  echo "CHILLING..."
  sleep(10_000)
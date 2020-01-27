import os
import httpclient
import json
import strutils

var api = "https://app.close.com/hackwithus/3d63efa04a08a9e0/"
var client = newHttpClient()

client.headers = newHttpHeaders({"Content-Type":"application/json"})

let data = %*{
  "first_name": "Adeoluwa",
  "last_name": "Adejumo",
  "email":"adejumoadeoluwa@gmail.com",
  "phone": "+15512250652",
  "cover_letter":"https://bit.ly/2UaJpNV",
  "urls": ["https://github.com/adeohluwa"]
  }

echo "POSTING... ", $data
let response = client.post(api, $data)
echo "UPDATE: ", $response.body

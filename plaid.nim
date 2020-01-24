import os
import httpclient
import json
import strutils

var api = "https://contact.plaid.com/jobs"
var client = newHttpClient()

client.headers = newHttpHeaders({"Content-Type":"application/json"})

while true:
  let data = %*{
    "name": "Adeoluwa Adejumo",
    "email":"adejumoadeoluwa@gmail.com",
    "resume":"https://www.dropbox.com/s/p3o3hqqkfzuvpj0/Adeoluwa%20Adejumo%20%28technical%20support%29.pdf?dl=1",
    "github": "https://github.com/adeohluwa",
    "superpower": "b1 spanish"
    }

  echo "POSTING... ", $data
  let response = client.post(api, $data)
  echo "UPDATE: ", $response.body

#!/usr/bin/env nimcr

# website is https so compile with  nim c -r --threads:on -d:ssl bizlist_scraper.nim

import httpclient, htmlparser, os, threadpool,
  system, strutils, re, strtabs, sequtils, 
  xmltree, nimquery, streams, csvtools, tables


# create a directory for each industry
proc mkCategories() =
  for line in lines "all.txt":
    createDir("./home/categories/$#/companies" % line)
    echo "creating '$#' directory....\n" % line
  echo """
          ++++++++++++++++++++++++++++++
          +++ Done Creating Folders! +++
          ++++++++++++++++++++++++++++++

       """


# ensure no captcha
proc ensureNoCaptcha(response: string) =
  if "CaptchaScode" in response:
    echo "STOP | Too Many Requests From This IP"
    quit(QuitFailure)


# request each url
proc retrieve(url, filename, proxy: string) =
  var browser = newHttpClient()
  let Googlebot = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  browser.headers = newHttpHeaders({"User-agent":Googlebot})
  var response = browser.request(url)
  ensureNoCaptcha(response.body)
  writeFile(filename, response.body)
  sleep(120_000)


# get the maximum page number for an industry
proc maxPageNo(urlcategory: string): string =
  var maxNo = newSeq[string]()
  var browser = newHttpClient()
  let Googlebot = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  browser.headers = newHttpHeaders({"User-agent":Googlebot})
  var response = browser.request(urlcategory)
  var xml = parseHtml(newStringStream(response.body))
  let pageNumbers = xml.querySelectorAll("a.page_no")
  for each in pageNumbers:
    maxNo.add(each.innerText)
  return maxNo[^1]


# get pages in each industry category asychronously
proc getEachIndustry() =
  # define proxy
  let proxy = "proxy1"
  for eachIndustry in lines "all.txt":
    var categoryUrl = "https://www.businesslist.com.ng/category/$#" % [ eachIndustry.replace(" ", "-")]
    var theEnd: int
    try:
      var theEnd = maxPageNo(categoryUrl)
    except IndexError:
      echo "category $# has just 1 page" % eachIndustry
      var theEnd = 1
    finally:
      for num in 1..theEnd:
        let url = "https://www.businesslist.com.ng/category/$#/$#/state:lagos" % [ eachIndustry.replace(" ", "-"), $num ]
        let filename = "./home/categories/$#/$#.html" % [ eachIndustry, $num ]
        if existsFile(filename):
          echo "skipping this {$#} page $#" % [eachIndustry, $num]
          continue
        echo "downloading... { $# } page $#" % [eachIndustry, $num]
        spawn retrieve(url, filename, proxy)


# get each company page
proc getEachCompany() =
  let proxy = "proxy1"
  for eachCategory in walkDirs("./home/categories/*"):
    for eachPage in walkFiles("$#/*.html" % eachCategory):
      var loadedPage = loadHtml eachPage


      for eachCompany in loadedPage.findAll("h4"):
        let companyUrl = eachCompany[0].attrs["href"]
        if not companyUrl.isNil:
          let url = "https://businesslist.com.ng$#" % [companyUrl]
          var companyUrl = companyUrl.replace(re"/company/\d+/","")
          var filename = "$#/companies$#.html" % [eachCategory, companyUrl]
          if existsFile(filename):
            echo "skipping this $#" % [companyUrl]
            continue
          echo "downloading... { $# }" % [companyUrl]
          spawn retrieve(url, filename, proxy)


# extract necessary details
proc extractData(): seq[string] =
  var all = newSeq[string]()
  for line in lines "all.txt":
    for eachCompany in walkFiles("./home/categories/$#/companies/*" % line):
      var companyDetails = readFile eachCompany
      var xml = parseHtml(newStringStream(companyDetails))
      var companyName = xml.querySelector("span#company_name")
      var companyDesc= xml.querySelector("#company_item > div.company_item_center > div:nth-child(5) > div.text.description")
      var companyAddress = xml.querySelector("#company_item > div.company_details.company_details_min > div:nth-child(2) > div.text.location")
      var companyPhone = xml.querySelector("#company_item > div.company_details.company_details_min > div:nth-child(3)")
      var companyMobile = xml.querySelector("#company_item > div.company_details.company_details_min > div:nth-child(4)")
      var companyWebsite = xml.querySelector("#company_item > div.company_details.company_details_min > div:nth-child(5) > div.text.weblinks")
      var companyYear = xml.querySelector("#company_item > div.company_details.company_details_min > div:nth-child(6)")
      var companyEmployees = xml.querySelector("#company_item > div.company_details.company_details_min > div:nth-child(7)")
      var companyHours = xml.querySelector("#company_item > div.company_item_center > div:nth-child(6) > ul")
      if not (companyName.isNil or companyAddress.isNil or companyWebsite.isNil or companyDesc.isNil or companyHours.isNil):
        all.add(@[companyName.innerText, companyDesc.innerText[1..300], companyAddress.innerText, companyPhone.innerText, 
          companyMobile.innerText, companyWebsite.innerText, companyEmployees.innerText, companyYear.innerText, companyHours.innerText])
        all.add("\n")
        for eachEntry in all:
          echo eachEntry
  # return all

# write data to CSV file
proc writeToCSVFile() =
  let extract = extractData()
  #name, description, address, hours, phones, mobiles, manager, website, started, employees: string
  for eachCategory in lines "all.txt":
    type Company = object
      name, address, website: string
    var fields: Company
    fields = Company(name : "NAME", address : "ADDRESS", website : "WEBSITE")
    var Ade: Company
    Ade = Company(name : "Carl", address : "L. glama", website : "http://test")
    var data: seq[Company] = @[fields, Ade]
    writeToCSV(data, "./home/categories/$#/companies/$#.csv" % [eachCategory, eachCategory])


# mkCategories()
# getEachIndustry()
# getEachCompany()
# extractData()
writeToCSVFile()

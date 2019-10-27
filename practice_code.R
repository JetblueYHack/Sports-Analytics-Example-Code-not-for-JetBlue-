
####################### get started #####################
#Reddit are dynamic
#Apple and tennis static, static data can get messy when extracting
#Advanced packages: rvest, Rcurl



## details on using the `help` function
?help                         
## information about the stats package
help(package = "stats")       


## install packages
install.packages("rvest",repos = "http://cran.us.r-project.org")
install.packages("RSelenium",repos = "http://cran.us.r-project.org")
require("rvest")
require("RSelenium") #interfact software selenium, makes it easy to connect to selenium server
require("knitr")
require("kableExtra")


####################### import files stored online #####################

## read table directly
url <- "http://www.tennis-data.co.uk/2019/ausopen.csv"
tennis_aus <- read.csv(url)
print(dim(tennis_aus))
tennis_aus[1,1:6]

## download data
url <- "http://www.bls.gov/cex/pumd/data/comma/diary14.zip"
download.file(url, dest = "dataset.zip", mode = "wb") 
unzip("dataset.zip")
# assess the files contained in the .zip file which
# unzips as a folder named "diary14"
list.files("diary14")

## exercise: online file import 
url <- "http://www.tennis-data.co.uk/2018/usopen.csv"
tennis_us <- read.csv(url)


########################## static data ##############################

## readLines
tennis_elo <- readLines("http://tennisabstract.com/reports/atp_elo_ratings.html")
head(tennis_elo)

## rvest
#load data
require('rvest')
url_nba <- "https://www.basketball-reference.com/boxscores/?month=6&day=13&year=2019"
webpage <- read_html(url_nba)
# extract date
webpage %>% html_nodes(css = 'h1') %>% html_text()
# scrape kew word
boxscore_0613 <- webpage %>%
  html_nodes(css = 'table') %>%
  html_table()
typeof(boxscore_0613)

## exercise: only the division standings table for the Easter conference.
webpage <- read_html(url_nba)
boxscore_east <- webpage %>%
  html_nodes(xpath = '//*[@id="divs_standings_E"]') %>%
  
  #*[@id="divs_standings_E"]/tbody/tr[1]/th # copied x path from inspector -> copy -> xpath
  html_table(header = T)
boxscore_east <- boxscore_east[[1]]
mean(as.numeric(boxscore_east$`W/L%`[2:6]))


## exercise: loop through static data 
url_common_start <- "https://www.basketball-reference.com/boxscores/?month="
url_seq  <- paste0(c(11,12,1:4),"&day=1&year=",c(rep(2018,2),rep(2019,4)))

# paste0 function
print(paste0(1,"A"))
print(paste0(1:3,"A"))
print(paste0(1,rep("A",3)))


score_raptor_2018 <- NULL
for (i in 1:length(url_seq)){
  url <- paste0(url_common_start,url_seq[i])
  webpage <- read_html(url)
  
  ## using xpath
  boxscore <- webpage %>%
    html_nodes(xpath = '//*[@id="divs_standings_E"]') %>%
    html_table(header=T)
  
  # ## equaivalently using css
  # boxscore <- webpage %>%
  #   html_nodes(css = '#divs_standings_E') %>%
  #   html_table(header=T)

  boxscore <- boxscore[[1]]
  score_raptor_month <- boxscore[boxscore$`Eastern Conference` == "Toronto Raptors*",]
  score_raptor_2018 <- rbind(score_raptor_2018,score_raptor_month,make.row.names = FALSE)
}
score_raptor_2018


########################## dynamic data ##############################
# package has: findElement(), sendKeystoelements(), 
## set up RSelenium
require(RSelenium)
# check available selenium driver version
binman::list_versions("chromedriver")
# check your chrome version as well 
# https://help.zenplanner.com/hc/en-us/articles/204253654-How-to-Find-Your-Internet-Browser-Version-Number-Google-Chrome
rD <- rsDriver(port = 5678L, browser = "chrome",chromever = "77.0.3865.40")
remDr <- rD[["client"]]

## example: Australia open final
## navigate to the page first, after running, will open in chrome
url <- "http://www.flashscore.com/match/Cj6I5iL9/#match-statistics;0"
remDr$navigate(url)  

# Get id element
webElem <- remDr$findElements(using = 'id', "detail")
# Use getElementText to extract the text from this element
unlist(lapply(webElem, function(x){x$getElementText()}))[[1]]
# Close driver when finished
remDr$close()  #closes the tab


## exercise: dynamic data
# set up server
remDr <- rsDriver(port = 5747L, browser = "chrome", version = "4.0.0-alpha-2",
                  chromever = "77.0.3865.40")
remDr <- remDr[["client"]]
# start loop
url <- "https://www.flashscore.com/match/fNecEwW2/#match-statistics;"
result <- NULL
# start loop
for (i in 0:3){
  # navigate page
  remDr$navigate(paste0(url,i)) 
  # find elements
  webElem <- remDr$findElements(using = 'id', 'detail')
  #  Use getElementText to extract the text from this element
  result[i+1] <- unlist(lapply(webElem, function(x){x$getElementText()}))[[1]]
  print(i)
}
# close driver
remDr$close() 


#gsub and splitstr()
# organize results
result_set <- NULL
for (i in 1:4){
  res <- result[i]
  # keep only useful information
  res <- gsub(".*Set 3\n(.+)", "\\1", res)
  # split string into vector
  result_set <- cbind(result_set, unlist(strsplit(res, split = '\n')))
}
colnames(result_set) <- c("match","set1", "set2","set3")
View(result_set)

# merge of unequal length vectors have multiple solution
# https://stackoverflow.com/questions/3699405/how-to-cbind-or-rbind-different-lengths-vectors-without-repeating-the-elements-o


########################## case study ##############################

## navigate to specific url
url <- "https://www.flashscore.com/team/connecticut-huskies/8rqVf3Tj/results/"
rD <- rsDriver(port = 6111L, browser = "chrome",version = "4.0.0-alpha-2",
               chromever = "77.0.3865.40")
remDr <- rD[["client"]]
remDr$navigate(url)

## extract live table
webElem <- remDr$findElements(using = 'id', "live-table")
unlist(lapply(webElem, function(x){x$getElementText()}))

## one click to see more
webElem <- remDr$findElement(using = 'css selector', "#live-table > div > div > div > a")
webElem$clickElement()
remDr$close()

## while loop to load all the "see more details"
url <- "https://www.flashscore.com/team/connecticut-huskies/8rqVf3Tj/results/"
rD <- rsDriver(port = 1720L, browser = "chrome",version = "4.0.0-alpha-2",
               chromever = "77.0.3865.40")
remDr <- rD[["client"]]
remDr$navigate(url)
repeat{
  x <- try(click_ind <- remDr$findElement(using = 'css selector', 
                                          "#live-table > div > div > div > a"),
           silent=TRUE)
  # if (inherits(x, "try-error")){break}
  if (inherits(x, "try-error")){
    print("done!")
    break
  }else{
    print("still clicking")
  }
  try(click_ind$clickElement(),silent=TRUE)
}
# selenium error message 

## extract full table
webElem <- remDr$findElements(using = 'id', "live-table")
uconn_score_all <- unlist(lapply(webElem, function(x){x$getElementText()}))
##  organize score results
uconn_score <- unlist(strsplit(uconn_score_all, split = '\n'))[-c(1:3)]
remDr$close()



## navigate to head to head page
#this works 
url <- "https://www.flashscore.com/match/IRo6KWr7/#h2h;overall"
rD <- rsDriver(port = 2649L, browser = "chrome",version = "4.0.0-alpha-2",
               chromever = "77.0.3865.40")
remDr <- rD[["client"]]
remDr$navigate(url)

## click to load all the data, 
webElem <- remDr$findElement(using = 'css selector', 
                             "#tab-h2h-overall > div:nth-child(3) > table > tbody > tr.hid > td > a")
webElem$clickElement()

## extract table elements
webElem <- remDr$findElement(using = 'css selector', 
                             "#tab-h2h-overall > div:nth-child(3) > table")

## organize hgead to head results
h2h <- unlist(webElem$getElementText())
h2h <- unlist(strsplit(h2h, split = '\n'))[-c(1,17,20)]
h2h <- strsplit(gsub("South Florida", "SF", h2h)," ")

## count the frequency of both team winning
win_team <- NULL
for (i in 1:length(h2h)){
  team <- h2h[[i]][c(3,4)]
  score <- as.numeric(h2h[[i]][c(5,7)])
  win_team <- c(win_team,team[which.max(score)])
}
win_team
remDr$close() 



############### ATL United Case Study ###################
## navigate to specific url
url <- "https://www.flashscore.com/team/atlanta-united/EPngUvhk/results/"
rD <- rsDriver(port = 6111L, browser = "chrome",version = "4.0.0-alpha-2",
               chromever = "77.0.3865.40")
remDr <- rD[["client"]]
remDr$navigate(url)


## click to load all the data, 
webElem <- remDr$findElement(using = 'css selector', 
                             "#tab-h2h-overall > div:nth-child(3) > table > tbody > tr.hid > td > a")
webElem$clickElement()

## extract table elements
webElem <- remDr$findElement(using = 'css selector', 
                             "#tab-h2h-overall > div:nth-child(3) > table")

## organize hgead to head results
h2h <- unlist(webElem$getElementText())
h2h <- unlist(strsplit(h2h, split = '\n'))[-c(1,17,20)]
h2h <- strsplit(gsub("South Florida", "SF", h2h)," ")

## count the frequency of both team winning
win_team <- NULL
for (i in 1:length(h2h)){
  team <- h2h[[i]][c(3,4)]
  score <- as.numeric(h2h[[i]][c(5,7)])
  win_team <- c(win_team,team[which.max(score)])
}
win_team
remDr$close() 




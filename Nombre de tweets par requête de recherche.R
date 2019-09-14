library(tidyverse)
library(lubridate)
library(scales)
library(RSelenium)
library(rvest)

# ouvre Chrome avec Selenium sur Docker, qui doit être déjà en train de tourner (j'utilise l'option -v /dev/shm:/dev/shm
# parce que sinon Chrome plante, cf. https://github.com/SeleniumHQ/docker-selenium/issues/79#issuecomment-133083785 pour
# l'explication)
system("docker run -v /dev/shm:/dev/shm -d -p 4445:4444 selenium/standalone-chrome")

# démarre RSelenium
rd <- remoteDriver(remoteServerAddr = "localhost",
                   port = 4445L,
                   browserName = "chrome")

# démarre une session (pour une raison que j'ignore, ça ne marche souvent pas la première fois, mais ça marche
# quand j'exécute le script une deuxième fois)
rd$open()

# demande à l'utilisateur d'entrer une requête de recherche
query <- readline(prompt = "Requête de recherche : ")

# url correspondant à cette requête
url <- URLencode(paste0("https://twitter.com/search?f=tweets&vertical=default&q=", query))

# ouvre l'url dans Chrome
rd$navigate(url)

# scroll vers le bas jusqu'à ce que tous les tweets soient affichés
last_page_length <- 0
page_length <- as.integer(rd$executeScript("return document.body.scrollHeight;"))
while(page_length != last_page_length) {
  last_page_length <- page_length
  rd$executeScript("window.scroll(0, document.body.scrollHeight);")
  Sys.sleep(1)
  page_length <- as.integer(rd$executeScript("return document.body.scrollHeight;"))
}

# récupère le code source de la page et lit celui-ci avec rvest
html <- rd$getPageSource()[[1]] %>% read_html()

# ferme la session
rd$close()

# arrête le serveur sur Docker
system("docker stop $(docker ps -q)")

# récupère le nombre de tweets pour cette requête
nb_tweets <- html %>%
  html_nodes(".content")

sprintf("%i tweets", nb_tweets)
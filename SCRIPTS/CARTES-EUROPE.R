#### INSTALLATION ET CHARGEMENT DES PACKAGES ####
install.packages(c("leaflet", "mapview"))
webshot::install_phantomjs()

library(leaflet)
library(mapview)

# Suppression des cartes actuelles
CARTES <- list.files("./BDD/GBIF-EUROPE/", pattern = "^[a-z]+_.*?.png")
file.remove(file.path("./BDD/GBIF-EUROPE/", CARTES))

#### CREATION DES VARIABLES ####
CIGALES_CODES <- read.csv(file = "CIGALES-CODES.csv", header = T, sep = ",")
projection = '3857'
style = 'style=gbif-natural-fr'
tileRaster = paste0('https://tile.gbif.org/',projection,'/omt/{z}/{x}/{y}@4x.png?',style)
prefix = 'https://api.gbif.org/v2/map/occurrence/density/{z}/{x}/{y}@4x.png?'
polygons = 'style=red.poly&bin=hex'

#### CREATION DES CARTES ET SAUVEGARDE ####
for (i in 1:length(CIGALES_CODES$CODE)) {
  print(CIGALES_CODES$NOM_SCIENTIFIQUE[i])
  taxonKey = CIGALES_CODES$GBIF[i]
  tilePolygons = paste0(prefix,polygons,'&taxonKey=',taxonKey)
  map<-leaflet() %>%
    setView(lng = 10, lat = 47, zoom = 5) %>%
    addTiles(urlTemplate=tileRaster) %>%
    addTiles(urlTemplate=tilePolygons) %>%
    addTiles(attribution = '<img src="https://docs.gbif.org/style/logo.svg" style="max-width:100px"/>')
  
  mapshot(map, file = paste0("./BDD/GBIF-EUROPE/",CIGALES_CODES$CODE[i],".png"), useragent = 'Mozilla/5.0',vwidth = 1500, vheight = 900)
}

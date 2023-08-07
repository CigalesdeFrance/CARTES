#### INSTALLATION ET CHARGEMENT DES PACKAGES ####
install.packages(c("sf","tmap"))

library(sf)
library(tmap)

#### CREATION DES VARIABLES ####
CIGALES_CODES <- read.csv(file = "CIGALES-CODES.csv", header = T, sep = ",")
REGIONS <- st_read("./ASSETS/regions.geojson")
DEPARTEMENTS <- st_read("./ASSETS/departements.geojson")
CANTONS <- st_read("./ASSETS/cantons.geojson")

#### STYLE DES COUCHES ####
map_REG <- tm_shape(REGIONS) + tm_borders(col="black", lwd = 2) + tm_fill(alpha = 0) + tm_logo("./ASSETS/LOGOS/Cigales_de_France.png", height=3, position = c("left", "bottom"))
map_DEP <- tm_shape(DEPARTEMENTS) + tm_borders(col="grey") + tm_fill(alpha = 0)

#### CREATION DES CARTES ET SAUVEGARDE ####
for (i in 1:length(CIGALES_CODES$CODE)) {
  print(CIGALES_CODES$NOM_SCIENTIFIQUE[i])

  # Chargement des points
  GBIF<- read.csv(paste0("./BDD/GBIF/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
  INATURALIST<- read.csv(paste0("./BDD/INATURALIST/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
  INPN<- read.csv(paste0("./BDD/INPN/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
  OBSERVATION<- read.csv(paste0("./BDD/OBSERVATION/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
  
  # Fusion des bases de données
  df <- rbind(GBIF,INATURALIST,INPN,OBSERVATION)
  data <- st_as_sf(data.frame(x=df$Longitude,y=df$Latitude),coords = 1:2,crs=st_crs(CANTONS))
  
  # Recherche des points présents dans les cantons
  CANTONS$CIGALE = lengths(st_contains(CANTONS,data)) > 0
  
  # Style de la couche variable
  map_CAN <- tm_shape(CANTONS) + tm_polygons("CIGALE", palette=c("TRUE" = "red", "FALSE" = "white"), border.alpha = 0, legend.show = FALSE)
  
  # Création de la carte finale
  map_fr <- map_CAN + map_DEP + map_REG + tm_layout(title = CIGALES_CODES$NOM_SCIENTIFIQUE[i])

  # Enregistrement  
  tmap_save(map_fr, filename=paste0("./BDD/CDF/",CIGALES_CODES$CODE[i],".png"))

}

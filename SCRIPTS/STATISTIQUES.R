#### INSTALLATION ET CHARGEMENT DES PACKAGES ####
install.packages(c("ggplot2","dplyr","grid","cowplot"), repos = "https://cloud.r-project.org/")

library(ggplot2)
library(dplyr)
library(grid)
library(cowplot)

Sys.setlocale("LC_TIME", "fr_FR.UTF-8")

#### CREATION DES VARIABLES ####
CIGALES_CODES <- read.csv(file = "CIGALES-CODES.csv", header = T, sep = ",")

#### CALCUL DES STATISTIQUES ET SAUVEGARDE ####
for (i in 1:length(CIGALES_CODES$CODE)) {
	print(CIGALES_CODES$NOM_SCIENTIFIQUE[i])
	
	# Chargement des points
	GBIF<- read.csv(paste0("./BDD/GBIF/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
	INATURALIST<- read.csv(paste0("./BDD/INATURALIST/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
	INPN<- read.csv(paste0("./BDD/INPN/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
	OBSERVATION<- read.csv(paste0("./BDD/OBSERVATION/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
	FAUNE_FRANCE<- read.csv(paste0("./BDD/FAUNE-FRANCE/",CIGALES_CODES$CODE[i],".csv"), h=T, sep=",")
	
	# Fusion des bases de données
	data <- rbind(GBIF,INATURALIST,INPN,OBSERVATION,FAUNE_FRANCE)
	
	### DATES ###
	
	data_date <- data %>%
		filter(!is.na(DATE) & trimws(DATE) != "")
		
	tot_obs_date <- length(data_date$DATE)
	
	data_date$DATE <- as.Date(data_date$DATE, format = "%Y-%m-%d")
	data_date$JOUR <- as.numeric(format(data_date$DATE, "%d"))
	data_date$MOIS <- format(data_date$DATE, "%B")
	
	# Création des décades
	data_date$DECADE <- cut(data_date$JOUR,
						breaks = c(0, 10, 20, 31),
						labels = c("1", "2", "3"),
						right = TRUE
						)
	
	data_date$MOIS <- factor(data_date$MOIS,
						levels = c("janvier", "février", "mars", "avril", "mai", "juin",
									"juillet", "août", "septembre", "octobre", "novembre", "décembre")
						)
	
	# Regrouper par mois et décade
	data_grouped <- data_date %>%
		group_by(MOIS, DECADE) %>%
			summarise(Count = n(), .groups = "drop")
	
	# Créer une date fictive avec la même année pour toutes les dates (par ex. 2000, année bissextile)
	data_date$DATE2000 <- as.Date(format(data_date$DATE, "2000-%m-%d"))
	
	# Statistiques
	min_date <- min(data_date$DATE2000)
	max_date <- max(data_date$DATE2000)
	
	date_min_reelle <- data_date$DATE[which(data_date$DATE2000 == min_date)][1]
	date_max_reelle <- data_date$DATE[which(data_date$DATE2000 == max_date)][1]
	
	mean_date <- as.Date(mean(as.numeric(data_date$DATE2000)), origin = "1970-01-01")
	median_date <- as.Date(median(as.numeric(data_date$DATE2000)), origin = "1970-01-01")
	
	# Préparer le texte (lignes séparées)
	lignes_stats_date <- c(
		paste("Date la plus précoce :", format(date_min_reelle, "%d/%m/%Y")),
		paste("Date la plus tardive :", format(date_max_reelle, "%d/%m/%Y")),
		paste("Jour moyen :", format(mean_date, "%d/%m")),
		paste("Jour médian :", format(median_date, "%d/%m")),
		paste("Nombre d'observations :", tot_obs_date)
	)
	
	# Graphique
	pdate <- ggplot(data_grouped, aes(x = MOIS, y = Count, group = DECADE)) +
			geom_bar(stat = "identity", position = "dodge", fill = "grey") +
			labs(
				#title = "Occurrences par décade du mois",
				#y = "Nombre d'observations",
				x = "Mois"
				) +
			theme_minimal() +
			theme(axis.text.x = element_text(angle = 45, hjust = 1),
					axis.title = element_text(face = "bold"),
					axis.title.y = element_blank(),
					axis.text.y = element_blank(),
					axis.ticks.y = element_blank(),
					panel.grid.major.y = element_blank(),
					panel.grid.minor.y = element_blank()
				)
	
	figdate <- ggdraw(pdate) +
				draw_text("Statistiques",
							x = 0.98, y = 0.95,
							hjust = 1, size = 11, fontface = "bold") +
				draw_text(paste(lignes_stats_date, collapse = "\n"),
							x = 0.98, y = 0.85,
							hjust = 1, size = 10)

	ggsave(paste0("./STATISTIQUES/PHENOLOGIE/",CIGALES_CODES$CODE[i],".png"), plot = figdate, width = 6, height = 6, dpi = 300, bg = "white")
	
	### ALTITUDE ###
	
	data_alt <- data %>%
		filter(ALTITUDE >= 0)
	
	tot_obs_alt <- length(data_alt$ALTITUDE)
	
	# STAT - altitude
	min_alt <- round(min(data_alt$ALTITUDE))
	max_alt <- round(max(data_alt$ALTITUDE))
	mean_alt <- round(mean(data_alt$ALTITUDE))
	median_alt <- round(median(data_alt$ALTITUDE))
	
	lignes_stats_alt <- c(
		paste("Altitude la plus basse (m) :", min_alt),
		paste("Altitude la plus haute (m) :", max_alt),
		paste("Altitude moyenne (m) :", mean_alt),
		paste("Altitude médiane (m) :", median_alt),
		paste("Nombre d'observations :", tot_obs_alt)
	)
	
	palt <- ggplot(data_alt, aes(x = ALTITUDE)) +
					geom_histogram(fill = "grey", color = "white", binwidth = 100) +
					coord_flip() +  # Histogramme horizontal
					labs(
						#title = "Histogramme de l'altitude par classes de 100 m",
						y = "Nombre d'observations",
						x = "Altitude (m)"
						) +
					theme_minimal() +
					theme(
						axis.text.y = element_text(color = "black"),
						axis.title = element_text(face = "bold"),
						plot.title = element_text(face = "bold", hjust = 0.5),
						axis.title.x = element_blank(),
						axis.text.x = element_blank(),
						axis.ticks.x = element_blank(),
						panel.grid.major.x = element_blank(),
						panel.grid.minor.x = element_blank()
						)
	
	figalt <- ggdraw(palt) +
				draw_text("Statistiques",
							x = 0.98, y = 0.95,
							hjust = 1, size = 11, fontface = "bold") +
				draw_text(paste(lignes_stats_alt, collapse = "\n"),
				x = 0.98, y = 0.85,
				hjust = 1, size = 10)

	ggsave(paste0("./STATISTIQUES/ALTITUDE/",CIGALES_CODES$CODE[i],".png"), plot = figalt, width = 6, height = 6, dpi = 300, bg = "white")

}
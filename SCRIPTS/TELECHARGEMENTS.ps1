$cigales_codes = Import-Csv "CIGALES-CODES.csv"
$bdd_codes = Import-Csv "BDD-CODES.csv"

# Test des URL
$INPN_url = (Invoke-WebRequest -Uri 'https://openobs.mnhn.fr/biocache-service/occurrences/search' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$INATURALIST_url = (Invoke-WebRequest -Uri 'https://api.inaturalist.org/v1/docs/' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$OBSERVATION_url = (Invoke-WebRequest -Uri 'https://observation.org/api/v1/docs/' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$GBIF_url = (Invoke-WebRequest -Uri 'https://api.gbif.org/v1/occurrence/search' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$FF_url = (Invoke-WebRequest -Uri 'https://www.faune-france.org' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse

if ($INPN_url.StatusCode -eq "OK") { 
	#Remove-item "./BDD/INPN/*.csv"
	New-Item -ItemType Directory -Path "./BDD/INPN/TEMP/" | Out-Null
}
if ($INATURALIST_url.StatusCode -eq "OK") {
	#Remove-item "./BDD/INATURALIST/*.csv"
	New-Item -ItemType Directory -Path "./BDD/INATURALIST/TEMP/" | Out-Null
}
if ($OBSERVATION_url.StatusCode -eq "OK") {
	#Remove-Item "./BDD/OBSERVATION/*.csv"
	New-Item -ItemType Directory -Path "./BDD/OBSERVATION/TEMP/" | Out-Null
}
if ($GBIF_url.StatusCode -eq "OK") {
	#Remove-Item "./BDD/GBIF/*.csv"
	New-Item -ItemType Directory -Path "./BDD/GBIF/TEMP/" | Out-Null
}
if ($FF_url.StatusCode -eq "OK") {
	#Remove-Item "./BDD/FAUNE-FRANCE/*.csv"
	New-Item -ItemType Directory -Path "./BDD/FAUNE-FRANCE/TEMP/" | Out-Null
}

### AUTHENTIFICATION
$OBS_TOKEN = (Invoke-WebRequest -Uri "https://observation.org/api/v1/oauth2/token/" -Method POST -Body $params | ConvertFrom-Json).access_token
$OBS_HEADERS = @{Authorization="Bearer $OBS_TOKEN"}

### CREATION DES CSV
$cigales_codes | ForEach-Object {
	$code = $_.CODE
	$nom = $_.NOM_SCIENTIFIQUE
	$faune_france = $_.FAUNE_FRANCE
	$inpn = $_.INPN
	$wad = $_.WAD
	$inaturalist = $_.INATURALIST
	$observation = $_.OBSERVATION
	$gbif = $_.GBIF
	$col = $_.CATALOGUE_OF_LIFE
	$fauna_europea = $_.FAUNA_EUROPEA
	
	# INPN
	"INPN - $nom"
	if ($INPN_url.StatusCode -eq "OK") {
		if ($inpn -eq "") {
			"  > L'espèce n'existe pas dans INPN"
			Add-Content "./BDD/INPN/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
		}
		else {
			$trurl = 'https://openobs.mnhn.fr/biocache-service/occurrences/search?q=taxonConceptID:' + $inpn +' AND (raw_dataGeneralizations:"XY+point") AND ((dynamicProperties_nivValNationale:"Certain - très probable") OR (dynamicProperties_nivValNationale:"Probable") OR (dynamicProperties_nivValNationale:"Non réalisable")) AND ((dynamicProperties_nivValRegionale:"Certain - très probable") OR (dynamicProperties_nivValRegionale:"Probable") OR (dynamicProperties_nivValRegionale:"Non réalisable") OR (*:* dynamicProperties_nivValRegionale:*))'
			$totalRecords = (Invoke-WebRequest $trurl | ConvertFrom-Json).totalRecords
			if ($totalRecords -eq 0) {
				"  > L'espèce est présente dans INPN mais ne possède aucune donnée" 
				Add-Content "./BDD/INPN/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
			}
			else {
				$json = @()
				
				$pages = [math]::floor($totalRecords/1000)
				for ($i = 1; $i -le 3; $i++) { # avec l'INPN obligé de faire tourner plusieurs fois pour avoir toutes les données
					for ($num=0;$num -le $pages;$num++) {
						if ($num -eq 0) {$startIndex=0} else {$startIndex = ($num*1000)}
						#$startIndex
						"page $num sur $pages ($i/3)"
						$jsonurl = $trurl + '&startIndex=' + $startIndex + '&pageSize=1000'
						$json_live = (Invoke-WebRequest $jsonurl | ConvertFrom-Json)
						$json_data = $json_live.occurrences
						$json += $json_data
					}
				}
				
				$json_coord = $json -match "latLong" # Vérification de la présence de coordonnées
				$json_filter = $json_coord | Where-Object { -not $_.PSObject.Properties['coordinateUncertaintyInMeters'] -or ($_.coordinateUncertaintyInMeters -le 100) } # Si présence de précision GPS alors sélection <= 100 m
				
				$export = $json_filter | Select-Object `
				@{ Name = 'ID'; Expression = { $_.uuid } },
				@{ Name = 'LATITUDE'; Expression = { ($_.latLong -split ',')[0] } },
				@{ Name = 'LONGITUDE'; Expression = { ($_.latLong -split ',')[1] } },
				@{ Name = 'DATE'; Expression = {
					if ($_.PSObject.Properties.Name -contains "eventDateEnd") { "" 
					} else { [datetimeoffset]::FromUnixTimeMilliseconds($_.eventDate).DateTime.ToString("yyyy-MM-dd") }
				}},
				@{ Name = 'ALTITUDE'; Expression = { "" } }
				
				$export | Sort-Object -Property ID -Unique | Export-Csv "./BDD/INPN/TEMP/$code.csv" -NoTypeInformation -Encoding UTF8
				
			}
		}
	}
	else {
		"  > L'API de l'INPN est inaccessible"
	}
	
	# INATURALIST
	"Inaturalist - $nom"
	if ($INATURALIST_url.StatusCode -eq "OK") {
		if ($inaturalist -eq "") {
			"  > L'espèce n'existe pas dans Inaturalist"
			Add-Content "./BDD/INATURALIST/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
		}
		else {
			$total_results = (Invoke-WebRequest "https://api.inaturalist.org/v1/observations?&place_id=6753&taxon_id=$inaturalist" | ConvertFrom-Json).total_results
			if ($total_results -eq 0) {
				"  > L'espèce est présente dans Inaturalist mais ne possède aucune donnée"
				Add-Content "./BDD/INATURALIST/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"		
			}
			else {
				$json = @()
				
				$pages = [math]::ceiling($total_results/200)
				for ($num=1;$num -le $pages;$num++) {
					"page $num sur $pages"
					$json_live = (Invoke-WebRequest "https://api.inaturalist.org/v1/observations?&place_id=6753&taxon_id=$inaturalist&page=$num&per_page=200" | ConvertFrom-Json)
					$json_data = $json_live.results
					$json += $json_data
				}
				
				$json_valid = $json | where { ($_.quality_grade -ne "needs_id") -and ($_.geoprivacy -ne "obscured") } # Observation au moins validée par une personne et non obscurcie
				$json_filter = $json_valid | Where-Object { $_.positional_accuracy -le 100 } # précision GPS <= 100m
				
				$export = $json_filter | Select-Object `
				@{ Name = 'ID'; Expression = { $_.id } },
				@{ Name = 'LATITUDE'; Expression = { ($_.location -split ',')[0] } },
				@{ Name = 'LONGITUDE'; Expression = { ($_.location -split ',')[1] } },
				@{ Name = 'DATE'; Expression = { $_.observed_on } },
				@{ Name = 'ALTITUDE'; Expression = { "" } }	
				
				$export | Sort-Object -Property ID -Unique | Export-Csv  "./BDD/INATURALIST/TEMP/$code.csv" -NoTypeInformation -Encoding UTF8
				
			}
		}
	}
	else {
		"  > L'API d'iNaturalist est inaccessible"
	}
	
	# OBSERVATION.ORG
	"Observation.org - $nom"
	if ($OBSERVATION_url.StatusCode -eq "OK") {
		if ($observation -eq "") {
			"  > L'espèce n'existe pas dans Observation.org"
			Add-Content "./BDD/OBSERVATION/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
		}
		else {
			$count = (Invoke-WebRequest "https://observation.org/api/v1/species/$observation/observations/?country_id=78" -Headers $OBS_HEADERS | ConvertFrom-Json).count
			if ($count -eq 0)  {
				"  > L'espèce est présente dans Observation.org mais ne possède aucune donnée"
				Add-Content "./BDD/OBSERVATION/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
			}
			else {
				$json = @()
				
				$pages = [math]::floor($count/300)
				for ($num=0;$num -le $pages;$num++) {
					if ($num -eq 0) {$offset=0} else {$offset = ($num*300)}
					"page $num sur $pages"
					$json_live = (Invoke-WebRequest "https://observation.org/api/v1/species/$observation/observations/?country_id=78&offset=$offset&limit=300" -Headers $OBS_HEADERS  | ConvertFrom-Json)
					$json_data = $json_live.results
					$json += $json_data
				}
				
				$json_certain = $json | where {$_.is_certain -eq "True"} # Observation certaine
				$json_valid = $json_certain | where { ($_.validation_status -ne "I") -and ($_.validation_status -ne "N") } # Observation pas en attente ou invalide
				$json_precis = $json_valid | Where-Object { $_.accuracy -le 100 } # précision GPS <= 100m
				$json_filter = $json_precis | where {$_.number -gt 0} # Effectif supérieur à 0
				
				$export = $json_filter | Select-Object `
				@{ Name = 'ID'; Expression = { $_.id } },
				@{ Name = 'LATITUDE'; Expression = { $_.point.coordinates[1] } },
				@{ Name = 'LONGITUDE'; Expression = { $_.point.coordinates[0] } },
				@{ Name = 'DATE'; Expression = { $_.date } },
				@{ Name = 'ALTITUDE'; Expression = { "" } }	
				
				$export | Sort-Object -Property ID -Unique | Export-Csv  "./BDD/OBSERVATION/TEMP/$code.csv" -NoTypeInformation -Encoding UTF8
				
			}
		}
	}
	else {
		"  > L'API d'Observation.org est inaccessible"
	}
	
	# GBIF
	"GBIF - $nom"
	if ($GBIF_url.StatusCode -eq "OK") {
		if ($GBIF -eq "") {
			"  > L'espèce n'existe pas dans GBIF"
			Add-Content "./BDD/GBIF/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
		}
		else {
			$count = (Invoke-WebRequest "https://api.gbif.org/v1/occurrence/search?country=FR&taxon_key=$gbif&occurrenceStatus=PRESENT" | ConvertFrom-Json).count
			if ($count -eq 0)  {
				"  > L'espèce est présente dans GBIF mais ne possède aucune donnée"
				Add-Content "./BDD/GBIF/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
			}
			else {
				$json = @()
				
				$pages = [math]::floor($count/300)
				for ($num=0;$num -le $pages;$num++) {
					if ($num -eq 0) {$offset=0} else {$offset = ($num*300)}
					"page $num sur $pages"
					$json_live = (Invoke-WebRequest "https://api.gbif.org/v1/occurrence/search?country=FR&taxon_key=$gbif&occurrenceStatus=PRESENT&offset=$offset&limit=300" | ConvertFrom-Json)
					$json_data = $json_live.results
					$json += $json_data
				}
				
				$json_valid = $json | where { ($_.identificationVerificationStatus -ne "Douteux") -and ($_.identificationVerificationStatus -ne "Invalide") } # Observation non douteuse ou invalide
				$json_coord = $json_valid -match "decimalLatitude" # Vérification de la présence de coordonnées
				$json_filter = $json_coord | Where-Object {
					if ($_.footprintWKT -and $_.footprintWKT.StartsWith("POINT")) { $true }
					elseif (-not $_.footprintWKT -and $_.coordinateUncertaintyInMeters -and $_.coordinateUncertaintyInMeters -le 100) { $true } 
					else { $false }
				} # Observation de type "point" ou avec une précision GPS <= 100 m
				
				$culture = New-Object System.Globalization.CultureInfo("en-US") #pour que github actions traite la date correctement
				
				$export = $json_filter | Select-Object `
				@{ Name = 'ID'; Expression = { $_.key } },
				@{ Name = 'LATITUDE'; Expression = { $_.decimalLatitude } },
				@{ Name = 'LONGITUDE'; Expression = { $_.decimalLongitude } },
				@{ Name = 'DATE'; Expression = {
					try {
						$date = [datetime]::Parse($_.eventDate, $culture)
						$date.ToString("yyyy-MM-dd")
					} catch { "" } # si date invalide
				}},
				@{ Name = 'ALTITUDE'; Expression = { "" } }
				
				$export | Sort-Object -Property ID -Unique | Export-Csv "./BDD/GBIF/TEMP/$code.csv" -NoTypeInformation -Encoding UTF8
				
			}
		}
	}
	else {
		"  > L'API de GBIF est inaccessible"
	}
	
	
	# FAUNE-FRANCE
	"FAUNE-FRANCE - $nom"
	if ($FF_url.StatusCode -eq "OK") {
		if ($faune_france -eq "") {
			"  > L'espèce n'existe pas dans Faune-France"
			Add-Content "./BDD/FAUNE-FRANCE/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
		}
		else {
			$ff_data_all = (Invoke-WebRequest "https://www.faune-france.org/index.php?m_id=95&action=geojson&sp_tg=19&sp_DChoice=all&sp_PChoice=all&sp_SChoice=species&sp_S=$faune_france" | ConvertFrom-Json).data
			
			$ff_data = $ff_data_all | where {$_.c -gt 0} # Effectif supérieur à 0
			$count = $ff_data.count
			
			if ($count -eq 0)  {
				"  > L'espèce est présente dans Faune-France mais ne possède aucune donnée"
				Add-Content "./BDD/FAUNE-FRANCE/TEMP/$code.csv" "ID,LATITUDE,LONGITUDE,DATE,ALTITUDE"
			}
			else {
				
				$export = $ff_data | Select-Object `
				@{ Name = 'ID'; Expression = { $_.i } },
				@{ Name = 'LATITUDE'; Expression = { $_.p[1] } },
				@{ Name = 'LONGITUDE'; Expression = { $_.p[0] } },
				@{ Name = 'DATE'; Expression = { $_.d } },
				@{ Name = 'ALTITUDE'; Expression = { "" } }	
				
				$export | Sort-Object -Property ID -Unique | Export-Csv  "./BDD/FAUNE-FRANCE/TEMP/$code.csv" -NoTypeInformation -Encoding UTF8
				
			}
		}
	}
	else {
		"  > Faune-France est inaccessible"
	}
}

# COMPARAISON
"--------- COMPARAISON DES FICHIERS ---------"
$bdd_codes | ForEach-Object {
	$bdd_nom = $_.BDD_NOM
	$bdd_min = $_.BDD_MIN
	$icon = $_.ICON
	$bdd_url = $_.BDD_URL
	
	" > $bdd_nom"
	
	$files = Get-ChildItem "./BDD/$bdd_nom/" -Filter *.csv
	
	foreach ($f in $files){
		$fichier = $f.Name
		$espece = $f.Name -replace ".csv"
		
		$actuel_csv = Import-Csv -Path "./BDD/$bdd_nom/$fichier"
		$nouveau_csv = Import-Csv -Path "./BDD/$bdd_nom/TEMP/$fichier"
		
		# "dictionnaires" d'accès rapide par ID
		$actuel_dico = @{}
		foreach ($row in $actuel_csv) { $actuel_dico[$row.id] = $row }
		
		$nouveau_dico = @{}
		foreach ($row in $nouveau_csv) { $nouveau_dico[$row.id] = $row }
		
		$resultats = @()
		
		foreach ($id in $nouveau_dico.Keys) {
			$nouveau = $nouveau_dico[$id]
			
			if ($actuel_dico.ContainsKey($id)) {
				$ancien = $actuel_dico[$id]
				# Vérification des mises à jour
				if ($ancien.latitude -ne $nouveau.latitude -or
				$ancien.longitude -ne $nouveau.longitude -or
				$ancien.date -ne $nouveau.date) {
					
					#$nouveau.altitude = $ancien.altitude // il est préférable de recalculer l'altitude si modification
					$resultats += $nouveau
					
					} else {
					$resultats += $ancien
				}
				} else {
				$resultats += $nouveau
			}
		}
		
		Remove-item "./BDD/$bdd_nom/$fichier"
		
		if (-not $resultats -or $espece -eq "Tibicina_corsica") { #si pas de résultat ou suppression des données de Tibicina corsica (qui occasionne des doublons)
			
			'"ID","LATITUDE","LONGITUDE","DATE","ALTITUDE"' | Set-Content -Path "./BDD/$bdd_nom/$fichier"
			
			} else {
			
			$resultats_tri = $resultats | Sort-Object ID
			$resultats_tri | Export-Csv -Path "./BDD/$bdd_nom/$fichier" -NoTypeInformation
		}
	}
	Remove-Item -Path "./BDD/$bdd_nom/TEMP/" -Recurse -Force
}

### SAUVEGARDE GIT
git config user.name 'github-actions[bot]'
git config user.email 'github-actions[bot]@users.noreply.github.com'
git add .
git commit -m "[Bot] Téléchargement des données"
git push origin main -f

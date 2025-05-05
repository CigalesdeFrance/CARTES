$cigales_codes = Import-Csv "CIGALES-CODES.csv"

# Test des API
$INPN_url = (Invoke-WebRequest -Uri 'https://openobs.mnhn.fr/biocache-service/occurrences/search' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$INATURALIST_url = (Invoke-WebRequest -Uri 'https://api.inaturalist.org/v1/docs/' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$OBSERVATION_url = (Invoke-WebRequest -Uri 'https://observation.org/api/v1/docs/' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$GBIF_url = (Invoke-WebRequest -Uri 'https://api.gbif.org/v1/occurrence/search' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse
$FF_url = (Invoke-WebRequest -Uri 'https://www.faune-france.org' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse

if ($INPN_url.StatusCode -eq "OK") { Remove-item "./BDD/INPN/*.csv" }
if ($INATURALIST_url.StatusCode -eq "OK") { Remove-item "./BDD/INATURALIST/*.csv" }
if ($OBSERVATION_url.StatusCode -eq "OK") { Remove-Item "./BDD/OBSERVATION/*.csv" }
if ($GBIF_url.StatusCode -eq "OK") { Remove-Item "./BDD/GBIF/*.csv" }
if ($FF_url.StatusCode -eq "OK") { Remove-Item "./BDD/FAUNE-FRANCE/*.csv" }

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
			Add-Content "./BDD/INPN/$code.csv" "Latitude,Longitude,ID,Date"
		}
		else {
			$trurl = 'https://openobs.mnhn.fr/biocache-service/occurrences/search?q=taxonConceptID:' + $inpn +' AND ((dynamicProperties_nivValNationale:"Certain - très probable") OR (dynamicProperties_nivValNationale:"Probable") OR (dynamicProperties_nivValNationale:"Non réalisable")) AND ((dynamicProperties_nivValRegionale:"Certain - très probable") OR (dynamicProperties_nivValRegionale:"Probable") OR (dynamicProperties_nivValRegionale:"Non réalisable") OR (*:* dynamicProperties_nivValRegionale:*))'
			$totalRecords = (Invoke-WebRequest $trurl | ConvertFrom-Json).totalRecords
			if ($totalRecords -eq 0) {
				"  > L'espèce est présente dans INPN mais ne possède aucune donnée" 
				Add-Content "./BDD/INPN/$code.csv" "Latitude,Longitude,ID,Date"
			}
			else {
				Add-Content "./BDD/INPN/$code-coord.csv" "Latitude,Longitude"
				Add-Content "./BDD/INPN/$code-id.csv" "ID"
				Add-Content "./BDD/INPN/$code-date.csv" "Date"
				$pages = [math]::floor($totalRecords/300)
				for ($num=0;$num -le $pages;$num++) {
					if ($num -eq 0) {$startIndex=0} else {$startIndex = ($num*300)}
					#$startIndex
					"page $num sur $pages"
					$jsonurl = $trurl + '&startIndex=' + $startIndex + '&pageSize=300'
					$json = (Invoke-WebRequest $jsonurl | ConvertFrom-Json)
					$json_filter = $json.occurrences -match "latLong" # Vérification de la présence de coordonnées
					$latLong = $json_filter.latLong | Add-Content "./BDD/INPN/$code-coord.csv"
					$id = $json_filter.uuid | Add-Content "./BDD/INPN/$code-id.csv"
					
					# date
					$timestamp = $json_filter.eventDate
					foreach ($time in $timestamp) {
						$datetime = [datetimeoffset]::FromUnixTimeMilliseconds($time).DateTime
						$datetime.ToString('yyyy-MM-dd') | Add-Content "./BDD/INPN/$code-date.csv"
					}
					
					# vérifier la cohérence avec $month et $year
				}
				
				$coord = Get-content "./BDD/INPN/$code-coord.csv" 
				$id = Get-content "./BDD/INPN/$code-id.csv"
				$date = Get-content "./BDD/INPN/$code-date.csv"
				$(for($index=0;$index -lt $coord.Count;$index++){$coord[$index] + "," + $id[$index] + "," + $date[$index]}) | Add-Content "./BDD/INPN/$code.csv"
				(Get-Content "./BDD/INPN/$code.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/INPN/$code.csv"
				
				Remove-item "./BDD/INPN/$code-coord.csv"
				Remove-item "./BDD/INPN/$code-id.csv"
				Remove-item "./BDD/INPN/$code-date.csv"
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
			Add-Content "./BDD/INATURALIST/$code.csv" "Latitude,Longitude,ID,Date"
		}
		else {
			$total_results = (Invoke-WebRequest "https://api.inaturalist.org/v1/observations?&place_id=6753&taxon_id=$inaturalist" | ConvertFrom-Json).total_results
			if ($total_results -eq 0) {
				"  > L'espèce est présente dans Inaturalist mais ne possède aucune donnée"
				Add-Content "./BDD/INATURALIST/$code.csv" "Latitude,Longitude,ID,Date"		
			}
			else {
				Add-Content "./BDD/INATURALIST/$code-coord.csv" "Latitude,Longitude"
				Add-Content "./BDD/INATURALIST/$code-id.csv" "ID"
				Add-Content "./BDD/INATURALIST/$code-date.csv" "Date"
				
				$pages = [math]::ceiling($total_results/200)
				for ($num=1;$num -le $pages;$num++) {
					"page $num sur $pages"
					$json = (Invoke-WebRequest "https://api.inaturalist.org/v1/observations?&place_id=6753&taxon_id=$inaturalist&page=$num&per_page=200" | ConvertFrom-Json)
					$json_filter = $json.results | where {$_.quality_grade -ne "needs_id"} # Observation au moins validée par une personne
					$json_filter.location | Add-Content "./BDD/INATURALIST/$code-coord.csv" 
					$json_filter.id | Add-Content "./BDD/INATURALIST/$code-id.csv"
					$json_filter.observed_on | Add-Content "./BDD/INATURALIST/$code-date.csv" 
				}		
				
				$coord = Get-content "./BDD/INATURALIST/$code-coord.csv" 
				$id = Get-content "./BDD/INATURALIST/$code-id.csv"
				$date = Get-content "./BDD/INATURALIST/$code-date.csv"
				$(for($index=0;$index -lt $coord.Count;$index++){$coord[$index] + "," + $id[$index] + "," + $date[$index]}) | Add-Content "./BDD/INATURALIST/$code.csv"
				(Get-Content "./BDD/INATURALIST/$code.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/INATURALIST/$code.csv"
				
				Remove-item "./BDD/INATURALIST/$code-coord.csv"
				Remove-item "./BDD/INATURALIST/$code-id.csv"
				Remove-item "./BDD/INATURALIST/$code-date.csv"
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
			Add-Content "./BDD/OBSERVATION/$code.csv" "Latitude,Longitude,ID,Date"
		}
		else {
			$count = (Invoke-WebRequest "https://observation.org/api/v1/species/$observation/observations/?country_id=78" -Headers $OBS_HEADERS | ConvertFrom-Json).count
			if ($count -eq 0)  {
				"  > L'espèce est présente dans Observation.org mais ne possède aucune donnée"
				Add-Content "./BDD/OBSERVATION/$code.csv" "Latitude,Longitude,ID"
			}
			else {
				Add-Content "./BDD/OBSERVATION/$code.csv" "Latitude,Longitude,ID,Date"
				$pages = [math]::floor($count/300)
				for ($num=0;$num -le $pages;$num++) {
					if ($num -eq 0) {$offset=0} else {$offset = ($num*300)}
					#$offset
					"page $num sur $pages"
					$json = (Invoke-WebRequest "https://observation.org/api/v1/species/$observation/observations/?country_id=78&offset=$offset&limit=300" -Headers $OBS_HEADERS  | ConvertFrom-Json)
					$json_filter = $json.results | where {$_.is_certain -eq "True"} # Observation certaine
					$json_valid = $json_filter | where { ($_.validation_status -ne "I") -and ($_.validation_status -ne "N") } # Observation pas en attente ou invalide
					$json_end = $json_valid | where {$_.number -gt 0} # Effectif supérieur à 0
					For ($i=0; $i -le (($json_end.Length)-1); $i++) {
						$lat = $json_end[$i].point.coordinates[1]
						$long = $json_end[$i].point.coordinates[0]
						$id = $json_end[$i].id
						$date = $json_end[$i].date
						$value = "$($lat),$($long),$($id),$($date)"
						$value | Add-Content "./BDD/OBSERVATION/$code.csv"
					}
				}
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
			Add-Content "./BDD/GBIF/$code.csv" "Latitude,Longitude,ID,Date"
		}
		else {
			$count = (Invoke-WebRequest "https://api.gbif.org/v1/occurrence/search?country=FR&taxon_key=$gbif&occurrenceStatus=PRESENT" | ConvertFrom-Json).count
			if ($count -eq 0)  {
				"  > L'espèce est présente dans GBIF mais ne possède aucune donnée"
				Add-Content "./BDD/GBIF/$code.csv" "Latitude,Longitude,ID,Date"
			}
			else {
				Add-Content "./BDD/GBIF/$code-coord.csv" "Latitude,Longitude"
				Add-Content "./BDD/GBIF/$code-id.csv" "ID"
				Add-Content "./BDD/GBIF/$code-date.csv" "Date"
				
				$pages = [math]::floor($count/300)
				for ($num=0;$num -le $pages;$num++) {
					if ($num -eq 0) {$offset=0} else {$offset = ($num*300)}
					#$offset
					"page $num sur $pages"
					$json = (Invoke-WebRequest "https://api.gbif.org/v1/occurrence/search?country=FR&taxon_key=$gbif&occurrenceStatus=PRESENT&offset=$offset&limit=300" | ConvertFrom-Json)
					$json_filter = $json.results | where { ($_.identificationVerificationStatus -ne "Douteux") -and ($_.identificationVerificationStatus -ne "Invalide") } # Observation non douteuse ou invalide
					$json_filter = $json_filter -match "decimalLatitude" # Vérification de la présence de coordonnées
					$lat = $json_filter.decimalLatitude | Add-Content "./BDD/GBIF/$code-lat.csv" 
					$long = $json_filter.decimalLongitude | Add-Content "./BDD/GBIF/$code-long.csv" 
					$id = $json_filter.key | Add-Content "./BDD/GBIF/$code-id.csv" 
					
					# date
					$date_saisie = $json_filter.eventDate
					$culture = New-Object System.Globalization.CultureInfo("en-US")
					
					foreach ($saisie in $date_saisie) {
						try {
							$date = [datetime]::Parse($saisie, $culture)
							$date.ToString("yyyy-MM-dd") | Add-Content "./BDD/GBIF/$code-date.csv"
						} catch {
							# date invalide
						}
					}
				}
				
				$lat = Get-content "./BDD/GBIF/$code-lat.csv" 
				$long = Get-content "./BDD/GBIF/$code-long.csv" 
				$(for($index=0;$index -lt $lat.Count;$index++){$lat[$index] + "," + $long[$index]}) | Add-Content "./BDD/GBIF/$code-coord.csv"
				(Get-Content "./BDD/GBIF/$code-coord.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/GBIF/$code-coord.csv"
				Remove-item "./BDD/GBIF/$code-lat.csv" 
				Remove-item "./BDD/GBIF/$code-long.csv" 
				
				$coord = Get-content "./BDD/GBIF/$code-coord.csv" 
				$id = Get-content "./BDD/GBIF/$code-id.csv"
				$date = Get-content "./BDD/GBIF/$code-date.csv"
				$(for($index=0;$index -lt $coord.Count;$index++){$coord[$index] + "," + $id[$index] + "," + $date[$index]}) | Add-Content "./BDD/GBIF/$code.csv"
				(Get-Content "./BDD/GBIF/$code.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/GBIF/$code.csv"
				
				Remove-item "./BDD/GBIF/$code-coord.csv"
				Remove-item "./BDD/GBIF/$code-id.csv"
				Remove-item "./BDD/GBIF/$code-date.csv"
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
			Add-Content "./BDD/FAUNE-FRANCE/$code.csv" "Latitude,Longitude,ID,Date"
		}
		else {
			$ff_data_all = (Invoke-WebRequest "https://www.faune-france.org/index.php?m_id=95&action=geojson&sp_tg=19&sp_DChoice=all&sp_PChoice=all&sp_SChoice=species&sp_S=$faune_france" | ConvertFrom-Json).data
			
			$ff_data = $ff_data_all | where {$_.c -gt 0} # Effectif supérieur à 0
			$count = $ff_data.count
			
			if ($count -eq 0)  {
				"  > L'espèce est présente dans Faune-France mais ne possède aucune donnée"
				Add-Content "./BDD/FAUNE-FRANCE/$code.csv" "Latitude,Longitude,ID,Date"
			}
			else {
				Add-Content "./BDD/FAUNE-FRANCE/$code.csv" "Latitude,Longitude,ID,Date"
				
				for ($num=0;$num -le ($count -1) ;$num++) {
					$lat = $ff_data[$num].p[1]
					$long = $ff_data[$num].p[0]
					$id = $ff_data[$num].i
					$date = $ff_data[$num].d
					
					$value = "$($lat),$($long),$($id),$($date)"
					$value | Add-Content "./BDD/FAUNE-FRANCE/$code.csv"
				}
			}
		}
	}
	else {
		"  > Faune-France est inaccessible"
	}
}

### SAUVEGARDE GIT
git config user.name 'github-actions[bot]'
git config user.email 'github-actions[bot]@users.noreply.github.com'
git add .
git commit -m "[Bot] Téléchargement des données"
git push origin main -f

### CREATION + GEOJSON
# INPN
$files = Get-ChildItem "./BDD/INPN/" -Filter *.csv

foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"

	# GEOJSON
	$csv = Import-Csv "./BDD/INPN/$fichier"
	$TotalItems = $csv.Count
	$CurrentItem = 0
	$PercentComplete = 0
	
	Set-Content "./BDD/INPN/$espece.geojson" '{
		"type": "FeatureCollection",
		"features": ['
	
	$csv| ForEach-Object {
		$lat = $_.Latitude
		$long = $_.Longitude
		$id = $_.ID
		#$id
		Write-Progress -Activity "INPN - $espece" -Status "$PercentComplete% achevé" -PercentComplete $PercentComplete

	$feature = '{
		"type": "Feature",
		"properties": {
			"ID": "'+ $id +'"
		},
		"geometry": {
			"coordinates": [
				'+ $long +',
				'+ $lat +'
			],
			"type": "Point"
		},
		"id": "'+ $id +'"
	},'

	$feature | Add-Content "./BDD/INPN/$espece.geojson"
	
	$CurrentItem++
	$PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
	}
	
	$geojson = Get-Content "./BDD/INPN/$espece.geojson"
	$geojson[-1] = $geojson[-1] -replace ',', ''
	$geojson | Set-Content "./BDD/INPN/$espece.geojson"
	"]}" | Add-Content "./BDD/INPN/$espece.geojson"
}

# OBSERVATION
$files = Get-ChildItem "./BDD/OBSERVATION/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"

	# GEOJSON
	$csv = Import-Csv "./BDD/OBSERVATION/$fichier"
	$TotalItems = $csv.Count
	$CurrentItem = 0
	$PercentComplete = 0
	
	Set-Content "./BDD/OBSERVATION/$espece.geojson" '{
		"type": "FeatureCollection",
		"features": ['
	
	$csv| ForEach-Object {
		$lat = $_.Latitude
		$long = $_.Longitude
		$id = $_.ID
		#$id
		Write-Progress -Activity "Observation.org - $espece" -Status "$PercentComplete% achevé" -PercentComplete $PercentComplete

	$feature = '{
		"type": "Feature",
		"properties": {
			"ID": "'+ $id +'"
		},
		"geometry": {
			"coordinates": [
				'+ $long +',
				'+ $lat +'
			],
			"type": "Point"
		},
		"id": "'+ $id +'"
	},'

	$feature | Add-Content "./BDD/OBSERVATION/$espece.geojson"
	
	$CurrentItem++
	$PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
	}
	
	$geojson = Get-Content "./BDD/OBSERVATION/$espece.geojson"
	$geojson[-1] = $geojson[-1] -replace ',', ''
	$geojson | Set-Content "./BDD/OBSERVATION/$espece.geojson"
	"]}" | Add-Content "./BDD/OBSERVATION/$espece.geojson"
}

# INATURALIST
$files = Get-ChildItem "./BDD/INATURALIST/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"

	# GEOJSON
	$csv = Import-Csv "./BDD/INATURALIST/$fichier"
	$TotalItems = $csv.Count
	$CurrentItem = 0
	$PercentComplete = 0
	
	Set-Content "./BDD/INATURALIST/$espece.geojson" '{
		"type": "FeatureCollection",
		"features": ['
	
	$csv| ForEach-Object {
		$lat = $_.Latitude
		$long = $_.Longitude
		$id = $_.ID
		#$id
		Write-Progress -Activity "iNaturalist - $espece" -Status "$PercentComplete% achevé" -PercentComplete $PercentComplete

	$feature = '{
		"type": "Feature",
		"properties": {
			"ID": "'+ $id +'"
		},
		"geometry": {
			"coordinates": [
				'+ $long +',
				'+ $lat +'
			],
			"type": "Point"
		},
		"id": "'+ $id +'"
	},'

	$feature | Add-Content "./BDD/INATURALIST/$espece.geojson"
	
	$CurrentItem++
	$PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
	}
	
	$geojson = Get-Content "./BDD/INATURALIST/$espece.geojson"
	$geojson[-1] = $geojson[-1] -replace ',', ''
	$geojson | Set-Content "./BDD/INATURALIST/$espece.geojson"
	"]}" | Add-Content "./BDD/INATURALIST/$espece.geojson"
}

# GBIF
$files = Get-ChildItem "./BDD/GBIF/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"

	# GEOJSON
	$csv = Import-Csv "./BDD/GBIF/$fichier"
	$TotalItems = $csv.Count
	$CurrentItem = 0
	$PercentComplete = 0
	
	Set-Content "./BDD/GBIF/$espece.geojson" '{
		"type": "FeatureCollection",
		"features": ['
	
	$csv| ForEach-Object {
		$lat = $_.Latitude
		$long = $_.Longitude
		$id = $_.ID
		#$id
		Write-Progress -Activity "GBIF - $espece" -Status "$PercentComplete% achevé" -PercentComplete $PercentComplete

	$feature = '{
		"type": "Feature",
		"properties": {
			"ID": "'+ $id +'"
		},
		"geometry": {
			"coordinates": [
				'+ $long +',
				'+ $lat +'
			],
			"type": "Point"
		},
		"id": "'+ $id +'"
	},'

	$feature | Add-Content "./BDD/GBIF/$espece.geojson"
	
	$CurrentItem++
	$PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
	}
	
	$geojson = Get-Content "./BDD/GBIF/$espece.geojson"
	$geojson[-1] = $geojson[-1] -replace ',', ''
	$geojson | Set-Content "./BDD/GBIF/$espece.geojson"
	"]}" | Add-Content "./BDD/GBIF/$espece.geojson"
}

### SAUVEGARDE GIT
git config --local user.email "cigalesdefrance@outlook.fr"
git config --local user.name "CigalesdeFrance-dev"
git add .
git commit -m "[Bot] Création des fichiers GeoJSON"
git push -f

$bdd_codes = Import-Csv "BDD-CODES.csv"

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
		
		"     > $espece"
		
		# Charger les données
		$csv = Import-Csv -Path "./BDD/$bdd_nom/$fichier"
		
		if ($csv.Count -eq 0) {
		
			# CSV vide donc on ignore
			
		} else {
			
			# Filtrer les lignes avec altitude manquante
			$alt_to_maj = $csv | Where-Object { -not $_.ALTITUDE -or $_.ALTITUDE -eq "" }
			
			# si un seul élément à mettre à jour
			if ($alt_to_maj -isnot [System.Collections.IEnumerable]) { $alt_to_maj = @($alt_to_maj) }
			
			# Diviser en groupes de 100 éléments maximum
			$group_size = 100
			$groups = @()
			for ($i = 0; $i -lt $alt_to_maj.Count; $i += $group_size) {
				$endIndex = [Math]::Min($i + $group_size - 1, $alt_to_maj.Count - 1)
				$group_alt = $alt_to_maj[$i..$endIndex]
				$groups += ,$group_alt
			}
			
			foreach ($group in $groups) {
				
				$latitudes = ($group | ForEach-Object { $_.LATITUDE }) -join "|"
				$longitudes = ($group | ForEach-Object { $_.LONGITUDE }) -join "|"
				
				$url = "https://data.geopf.fr/altimetrie/1.0/calcul/alti/rest/elevation.json?lon=$longitudes&lat=$latitudes&resource=ign_rge_alti_wld"
				
				$response = Invoke-RestMethod -Uri $url -Method Get
				
				# Pause pour respecter la limite de 5 requêtes/sec (https://geoservices.ign.fr/documentation/services/services-geoplateforme/altimetrie)
				Start-Sleep -Milliseconds 250
				
				# Mettre à jour les altitudes dans le group
				for ($i = 0; $i -lt $response.elevations.Count; $i++) {
				
					$altitude = $response.elevations[$i].z					
					if ($altitude -lt 0) { $altitude = -99999 } # si <0 (erreur, les Cigales sont terrestres) alors saisie d'une altitude facilement repérable a posteriori
					$group[$i].ALTITUDE = $altitude
				}
			}

   			# Vérification
      			foreach ($ligne in $csv) { if ($ligne.ALTITUDE -lt 0) { $ligne.ALTITUDE = -99999 } }
			
			# Sauvegarder dans le fichier d'origine
			$csv | Export-Csv -Path "./BDD/$bdd_nom/$fichier" -NoTypeInformation
			
		}
	}
}

### SAUVEGARDE GIT
git config user.name 'github-actions[bot]'
git config user.email 'github-actions[bot]@users.noreply.github.com'
git add .
git commit -m "[Bot] Calcul de l'altitude"
git push origin main -f

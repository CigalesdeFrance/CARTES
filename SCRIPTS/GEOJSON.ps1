### CREATION DES GEOJSON
$bdd_codes = Import-Csv "BDD-CODES.csv"

$bdd_codes | ForEach-Object {
	$bdd_nom = $_.BDD_NOM
	$bdd_min = $_.BDD_MIN
	$icon = $_.ICON
	$bdd_url = $_.BDD_URL
	
	$files = Get-ChildItem "./BDD/$bdd_nom/" -Filter *.csv
	
	foreach ($f in $files){
		$fichier = $f.Name
		$espece = $f.Name -replace ".csv"
		
		$csv = Import-Csv "./BDD/$bdd_nom/$fichier"
		$TotalItems = $csv.Count
		$CurrentItem = 0
		$PercentComplete = 0
		
		$geojson = '{
"type": "FeatureCollection",
"name": "'+ $espece +'",
"features": ['
		
		Set-Content "./BDD/$bdd_nom/$espece.geojson" $geojson
		
		$csv | ForEach-Object {
			$lat = $_.Latitude
			$long = $_.Longitude
			$id = $_.ID
			#$id
			Write-Progress -Activity "$bdd_nom - $espece" -Status "$PercentComplete% achevé" -PercentComplete $PercentComplete
			
			$feature = '{"type": "Feature", "properties": {"ID": "'+ $id +'"},"geometry": {"coordinates": ['+ $long +','+ $lat +'],"type": "Point"},"id": "'+ $id +'"},'
			
			$feature | Add-Content "./BDD/$bdd_nom/$espece.geojson"
			
			$CurrentItem++
			$PercentComplete = [int](($CurrentItem / $TotalItems) * 100)
		}
		
		$geojson = Get-Content "./BDD/$bdd_nom/$espece.geojson"
		$geojson[-1] = $geojson[-1] -replace ',$', ''
		$geojson | Set-Content "./BDD/$bdd_nom/$espece.geojson"
		"]}" | Add-Content "./BDD/$bdd_nom/$espece.geojson"
	}
}

### SAUVEGARDE GIT
git config user.name 'github-actions[bot]'
git config user.email 'github-actions[bot]@users.noreply.github.com'
git add .
git commit -m "[Bot] Création des fichiers GeoJSON"
git push origin main -f
$cigales_codes = Import-Csv "CIGALES-CODES.csv"

Remove-item "./BDD/INPN/*.csv"
Remove-item "./BDD/INATURALIST/*.csv"
Remove-Item "./BDD/GBIF/*.csv"

$cigales_codes | ForEach-Object {
	$code = $_.CODE
	$nom = $_.NOM_SCIENTIFIQUE
	#$onem = $_.ONEM
	$faune_france = $_.FAUNE_FRANCE
	$inpn = $_.INPN
	$inaturalist = $_.INATURALIST
	$observation = $_.OBSERVATION
	$gbif = $_.GBIF
	
	# FAUNE-FRANCE
	"Faune-France - $nom"
	if ($faune_france -eq "") {
		"  > L'espèce n'existe pas dans Faune-France"
		Invoke-WebRequest -Uri "https://raw.githubusercontent.com/CigalesdeFrance/CARTES/main/BDD/FAUNE-FRANCE/null.png" -OutFile "./BDD/FAUNE-FRANCE/$code.png"
	}
	else {
		Invoke-WebRequest -Uri "https://www.faune-france.org/index.php?m_id=95&sp_tg=19&sp_DChoice=all&sp_SChoice=species&sp_PChoice=all&sp_FChoice=map&sp_S=$faune_france" -OutFile "./BDD/FAUNE-FRANCE/$code.png" 
	}
	
	# INPN
	"INPN - $nom"
	if ($inpn -eq "") {
		"  > L'espèce n'existe pas dans INPN"
		Add-Content "./BDD/INPN/$code.csv" "Latitude,Longitude,ID"
	}
	else {
		$totalRecords = (Invoke-WebRequest "https://openobs.mnhn.fr/biocache-service/occurrences/search?fq=taxonConceptID:$inpn" | ConvertFrom-Json).totalRecords
		if ($totalRecords -eq 0) {
			"  > L'espèce est présente dans INPN mais ne possède aucune donnée" 
			Add-Content "./BDD/INPN/$code.csv" "Latitude,Longitude,ID"
		}
		else {
			Add-Content "./BDD/INPN/$code-coord.csv" "Latitude,Longitude"
			Add-Content "./BDD/INPN/$code-id.csv" "ID"
			$pages = [math]::floor($totalRecords/300)
			for ($num=0;$num -le $pages;$num++) {
				if ($num -eq 0) {$startIndex=0} else {$startIndex = ($num*300)}
				#$startIndex
				"page $num sur $pages"
				$json = (Invoke-WebRequest "https://openobs.mnhn.fr/biocache-service/occurrences/search?fq=taxonConceptID:$inpn&startIndex=$startIndex&pageSize=300" | ConvertFrom-Json)
				$json_filter = $json.occurrences -match "latLong"
				$latLong = $json_filter.latLong | Add-Content "./BDD/INPN/$code-coord.csv"
				$id = $json_filter.uuid | Add-Content "./BDD/INPN/$code-id.csv" 
			}
			
			$coord = Get-content "./BDD/INPN/$code-coord.csv" 
			$id = Get-content "./BDD/INPN/$code-id.csv"
			$(for($index=0;$index -lt $coord.Count;$index++){$coord[$index] + "," + $id[$index]}) | Add-Content "./BDD/INPN/$code.csv"
			(Get-Content "./BDD/INPN/$code.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/INPN/$code.csv"
			Remove-item "./BDD/INPN/$code-id.csv"
			Remove-item "./BDD/INPN/$code-coord.csv"
		}
	}
	
	# INATURALIST
	"Inaturalist - $nom"
	if ($inaturalist -eq "") {
		"  > L'espèce n'existe pas dans Inaturalist"
		Add-Content "./BDD/INATURALIST/$code.csv" "Latitude,Longitude,ID"
	}
	else {
		$total_results = (Invoke-WebRequest "https://api.inaturalist.org/v1/observations?&place_id=6753&taxon_id=$inaturalist" | ConvertFrom-Json).total_results
		if ($total_results -eq 0) {
			"  > L'espèce est présente dans Inaturalist mais ne possède aucune donnée"
			Add-Content "./BDD/INATURALIST/$code.csv" "Latitude,Longitude,ID"		
		}
		else {
			Add-Content "./BDD/INATURALIST/$code-coord.csv" "Latitude,Longitude"
			Add-Content "./BDD/INATURALIST/$code-id.csv" "ID"
			
			$pages = [math]::ceiling($total_results/200)
			for ($num=1;$num -le $pages;$num++) {
				"page $num sur $pages"
				(Invoke-WebRequest "https://api.inaturalist.org/v1/observations?&place_id=6753&taxon_id=$inaturalist&page=$num&per_page=200" | ConvertFrom-Json).results.location | Add-Content "./BDD/INATURALIST/$code-coord.csv" 
				(Invoke-WebRequest "https://api.inaturalist.org/v1/observations?&place_id=6753&taxon_id=$inaturalist&page=$num&per_page=200" | ConvertFrom-Json).results.id | Add-Content "./BDD/INATURALIST/$code-id.csv" 
			}		
			
			$coord = Get-content "./BDD/INATURALIST/$code-coord.csv" 
			$id = Get-content "./BDD/INATURALIST/$code-id.csv"
			$(for($index=0;$index -lt $coord.Count;$index++){$coord[$index] + "," + $id[$index]}) | Add-Content "./BDD/INATURALIST/$code.csv"
			(Get-Content "./BDD/INATURALIST/$code.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/INATURALIST/$code.csv"
			Remove-item "./BDD/INATURALIST/$code-id.csv"
			Remove-item "./BDD/INATURALIST/$code-coord.csv"
		}
	}
	
	# OBSERVATION.ORG
	"Observation.org - $nom"
	if ($observation -eq "") {
		"  > L'espèce n'existe pas dans Observation"
		Add-Content "./BDD/OBSERVATION/$code.csv" "Latitude,Longitude,ID"
	}
	else {
		[xml]$data = (invoke-webrequest -Uri "https://france.observation.org/kmlloc/soort_get_xml_points.php?soort=$observation")
		$observation = $data.markers.line.point
		if ($observation.count -eq 0) {
			"  > L'espèce est présente dans Observation mais ne possède aucune donnée"
			Add-Content "./BDD/OBSERVATION/$code.csv" "Latitude,Longitude,ID"
		}
		else {
			$observation | Out-File "observation.txt"
			(Get-Content "observation.txt" | Select-Object -Skip 2) | Set-Content "observation.txt"
			$observation = Get-Content "observation.txt"
			$observation[0] = "Latitude,Longitude,ID"
			$observation = $observation -replace " ",","
			$observation | Out-File "./BDD/OBSERVATION/$code.csv"
			Remove-Item "observation.txt" 
		}
	}
	
	# GBIF
	"GBIF - $nom"
	if ($GBIF -eq "") {
		"  > L'espèce n'existe pas dans GBIF"
		Add-Content "./BDD/GBIF/$code.csv" "Latitude,Longitude,ID"
	}
	else {
		$count = (Invoke-WebRequest "https://api.gbif.org/v1/occurrence/search?country=FR&taxon_key=$gbif" | ConvertFrom-Json).count
		if ($count -eq 0)  {
			"  > L'espèce est présente dans GBIF mais ne possède aucune donnée"
			Add-Content "./BDD/GBIF/$code.csv" "Latitude,Longitude,ID"
		}
		else {
			Add-Content "./BDD/GBIF/$code-coord.csv" "Latitude,Longitude"
			Add-Content "./BDD/GBIF/$code-id.csv" "ID"
			$pages = [math]::floor($count/300)
			for ($num=0;$num -le $pages;$num++) {
				if ($num -eq 0) {$offset=0} else {$offset = ($num*300)}
				#$offset
				"page $num sur $pages"
				$json = (Invoke-WebRequest "https://api.gbif.org/v1/occurrence/search?country=FR&taxon_key=$gbif&offset=$offset&limit=300" | ConvertFrom-Json)
				$json_filter = $json.results -match "decimalLatitude"
				$latLong = $json_filter.latLong | Add-Content "./BDD/GBIF/$code-coord.csv"
				$id = $json_filter.uuid | Add-Content "./BDD/GBIF/$code-id.csv" 
				
				$lat = $json_filter.decimalLatitude | Add-Content "./BDD/GBIF/$code-lat.csv" 
				$long = $json_filter.decimalLongitude | Add-Content "./BDD/GBIF/$code-long.csv" 
				$id = $json_filter.key | Add-Content "./BDD/GBIF/$code-id.csv" 
			}
			
			$lat = Get-content "./BDD/GBIF/$code-lat.csv" 
			$long = Get-content "./BDD/GBIF/$code-long.csv" 
			$(for($index=0;$index -lt $lat.Count;$index++){$lat[$index] + "," + $long[$index]}) | Add-Content "./BDD/GBIF/$code-coord.csv"
			(Get-Content "./BDD/GBIF/$code-coord.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/GBIF/$code-coord.csv"
			Remove-item "./BDD/GBIF/$code-lat.csv" 
			Remove-item "./BDD/GBIF/$code-long.csv" 
			
			$coord = Get-content "./BDD/GBIF/$code-coord.csv" 
			$id = Get-content "./BDD/GBIF/$code-id.csv"
			$(for($index=0;$index -lt $coord.Count;$index++){$coord[$index] + "," + $id[$index]}) | Add-Content "./BDD/GBIF/$code.csv"
			(Get-Content "./BDD/GBIF/$code.csv") | ? {$_.trim() -ne "" } | Set-Content "./BDD/GBIF/$code.csv"
			Remove-item "./BDD/GBIF/$code-id.csv"
			Remove-item "./BDD/GBIF/$code-coord.csv"
		}
	}				
}

### CREATION DES KML
# INPN
$files = Get-ChildItem "./BDD/INPN/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"
	$kml =
	"<?xml version=`"1.0`" encoding=`"UTF-8`"?><kml xmlns=`"http://www.opengis.net/kml/2.2`">
	<Document>
	<Style id=`"inpn`"><IconStyle><scale>0.3</scale><Icon><href>https://maps.google.com/mapfiles/kml/paddle/ylw-circle-lv.png</href></Icon></IconStyle></Style>
	<name>$espece</name>
	<Folder>
	<name>INPN</name>
	$(Import-Csv "./BDD/INPN/$fichier" | foreach {'<Placemark><description>https://openobs.mnhn.fr/openobs-hub/occurrences/{2}</description><styleUrl>#inpn</styleUrl><Point><coordinates>{1},{0}</coordinates></Point></Placemark>' -f $_.Latitude, $_.Longitude, $_.ID})
	</Folder>
	</Document>
	</kml>"
	
	$kml | Out-File -Force -Encoding ascii ("./BDD/INPN/$espece.kml")
}

# OBSERVATION
$files = Get-ChildItem "./BDD/OBSERVATION/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"
	$kml =
	"<?xml version=`"1.0`" encoding=`"UTF-8`"?><kml xmlns=`"http://www.opengis.net/kml/2.2`">
	<Document>
	<Style id=`"observation`"><IconStyle><scale>0.3</scale><Icon><href>https://maps.google.com/mapfiles/kml/paddle/red-circle-lv.png</href></Icon></IconStyle></Style>
	<name>$espece</name>
	<Folder>
	<name>OBSERVATION</name>
	$(Import-Csv "./BDD/OBSERVATION/$fichier" | foreach {'<Placemark><description>https://france.observation.org/{2}</description><styleUrl>#observation</styleUrl><Point><coordinates>{1},{0}</coordinates></Point></Placemark>' -f $_.Latitude, $_.Longitude, $_.ID})
	</Folder>
	</Document>
	</kml>"
	
	$kml | Out-File -Force -Encoding ascii ("./BDD/OBSERVATION/$espece.kml")
}

# INATURALIST
$files = Get-ChildItem "./BDD/INATURALIST/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"
	$kml =
	"<?xml version=`"1.0`" encoding=`"UTF-8`"?><kml xmlns=`"http://www.opengis.net/kml/2.2`">
	<Document>
	<Style id=`"inaturalist`"><IconStyle><scale>0.3</scale><Icon><href>https://maps.google.com/mapfiles/kml/paddle/grn-circle-lv.png</href></Icon></IconStyle></Style>
	<name>$espece</name>
	<Folder>
	<name>INATURALIST</name>
	$(Import-Csv "./BDD/INATURALIST/$fichier" | foreach {'<Placemark><description>https://www.inaturalist.org/observations/{2}</description><styleUrl>#inaturalist</styleUrl><Point><coordinates>{1},{0}</coordinates></Point></Placemark>' -f $_.Latitude, $_.Longitude, $_.ID})
	</Folder>
	</Document>
	</kml>"
	
	$kml | Out-File -Force -Encoding ascii ("./BDD/INATURALIST/$espece.kml")
}

# GBIF
$files = Get-ChildItem "./BDD/GBIF/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"
	$kml =
	"<?xml version=`"1.0`" encoding=`"UTF-8`"?><kml xmlns=`"http://www.opengis.net/kml/2.2`">
	<Document>
	<Style id=`"gbif`"><IconStyle><scale>0.3</scale><Icon><href>https://maps.google.com/mapfiles/kml/paddle/blu-circle-lv.png</href></Icon></IconStyle></Style>
	<name>$espece</name>
	<Folder>
	<name>GBIF</name>
	$(Import-Csv "./BDD/GBIF/$fichier" | foreach {'<Placemark><description>https://www.gbif.org/occurrence/{2}</description><styleUrl>#gbif</styleUrl><Point><coordinates>{1},{0}</coordinates></Point></Placemark>' -f $_.Latitude, $_.Longitude, $_.ID})
	</Folder>
	</Document>
	</kml>"
	
	$kml | Out-File -Force -Encoding ascii ("./BDD/GBIF/$espece.kml")
}

### SAUVEGARDE DE L'ONEM

$regex = '<a href="([^"]*)">(.[a-z].+)</a>.([a-z].+)<br>'

foreach($line in Get-Content ./BDD/ONEM/index.html) {
    if($line -match $regex){
		$url = $matches[1]
		$sci1 = $matches[2]
		$sci = $sci1 -replace " ","_"
		$ver = $matches[3]
		Invoke-WebRequest -Uri $url -OutFile "sp.html"
		$Source = Get-Content -path "sp.html" -raw
		$Source -match 'tools/cartowiki/CACHE/(.*).jpg'
		$Sourceurl = $matches[1]
        Echo $sci1
		Invoke-WebRequest -Uri "http://www.onem-france.org/cigales/tools/cartowiki/CACHE/$Sourceurl.jpg" -OutFile "./BDD/ONEM/$sci.jpg"

    }
}

Remove-Item "sp.html"

### SAUVEGARDE GIT
git config --local user.email "cigalesdefrance@outlook.fr"
git config --local user.name "CigalesdeFrance-dev"
git add .
git commit -m "[Bot] Téléchargement des données + kml"
git push -f

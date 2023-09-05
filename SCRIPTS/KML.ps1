### CREATION DES KML + GEOJSON
# INPN
$files = Get-ChildItem "./BDD/INPN/" -Filter *.csv
foreach ($f in $files){
	$fichier = $f.Name
	$espece = $f.Name -replace ".csv"

	# KML
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

	# KML
	$kml =
	"<?xml version=`"1.0`" encoding=`"UTF-8`"?><kml xmlns=`"http://www.opengis.net/kml/2.2`">
	<Document>
	<Style id=`"observation`"><IconStyle><scale>0.3</scale><Icon><href>https://maps.google.com/mapfiles/kml/paddle/blu-circle-lv.png</href></Icon></IconStyle></Style>
	<name>$espece</name>
	<Folder>
	<name>OBSERVATION</name>
	$(Import-Csv "./BDD/OBSERVATION/$fichier" | foreach {'<Placemark><description>https://observation.org/observation/{2}</description><styleUrl>#observation</styleUrl><Point><coordinates>{1},{0}</coordinates></Point></Placemark>' -f $_.Latitude, $_.Longitude, $_.ID})
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

	# KML
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

	# KML
	$kml =
	"<?xml version=`"1.0`" encoding=`"UTF-8`"?><kml xmlns=`"http://www.opengis.net/kml/2.2`">
	<Document>
	<Style id=`"gbif`"><IconStyle><scale>0.3</scale><Icon><href>https://maps.google.com/mapfiles/kml/paddle/red-circle-lv.png</href></Icon></IconStyle></Style>
	<name>$espece</name>
	<Folder>
	<name>GBIF</name>
	$(Import-Csv "./BDD/GBIF/$fichier" | foreach {'<Placemark><description>https://www.gbif.org/occurrence/{2}</description><styleUrl>#gbif</styleUrl><Point><coordinates>{1},{0}</coordinates></Point></Placemark>' -f $_.Latitude, $_.Longitude, $_.ID})
	</Folder>
	</Document>
	</kml>"
	
	$kml | Out-File -Force -Encoding ascii ("./BDD/GBIF/$espece.kml")
}

### SAUVEGARDE GIT
git config --local user.email "cigalesdefrance@outlook.fr"
git config --local user.name "CigalesdeFrance-dev"
git add .
git commit -m "[Bot] Création des fichiers KML"
git push -f
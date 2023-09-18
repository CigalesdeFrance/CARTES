### CREATION DES KML
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
		
		$kml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
<kml xmlns=`"http://www.opengis.net/kml/2.2`">
	<Document>
		<Style id=`"$bdd_min`">
			<IconStyle>
				<scale>0.3</scale>
				<Icon><href>$icon</href></Icon>
			</IconStyle>
		</Style>
		<name>$espece</name>
		<Folder>
			<name>$bdd_nom</name>$(Import-Csv "./BDD/$bdd_nom/$fichier" | foreach {'
			<Placemark>
				<styleUrl>#'+ $bdd_min +'</styleUrl>
				<description>'+ $bdd_url +'{2}</description>
				<Point><coordinates>{1},{0}</coordinates></Point>
			</Placemark>' -f $_.Latitude, $_.Longitude, $_.ID})
		</Folder>
	</Document>
</kml>"
		
		$kml | Out-File -Force -Encoding ascii ("./BDD/$bdd_nom/$espece.kml")
	}
}


### SAUVEGARDE GIT
git config --local user.email "cigalesdefrance@outlook.fr"
git config --local user.name "CigalesdeFrance-dev"
git add .
git commit -m "[Bot] Création des fichiers KML"
git push origin main -f
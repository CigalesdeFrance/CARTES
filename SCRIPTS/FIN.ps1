$cigales_codes = Import-Csv "CIGALES-CODES.csv"

### SAUVEGARDE DES CARTES
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
git commit -m "[Bot] Téléchargement et création des cartes statiques"
git push -f
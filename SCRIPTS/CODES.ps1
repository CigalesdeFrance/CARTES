$cigales_codes = Import-CSV "CIGALES-CODES.csv"

$ff_erreurs = "Faune-France :"
$inpn_erreurs = "INPN :"
$inat_erreurs = "iNaturalist :"
$obs_erreurs = "Observation :"
$gbif_erreurs = "GBIF :"
$cof_erreurs = "COF :"
$fe_erreurs = "Fauna-Europea :"

$cigales_codes | ForEach-Object {
	$code = $_.CODE
	$nom = $_.NOM_SCIENTIFIQUE
	$faune_france = $_.FAUNE_FRANCE
	$inpn = $_.INPN
	$inaturalist = $_.INATURALIST
	$observation = $_.OBSERVATION
	$gbif = $_.GBIF
	$cof = $_.CATALOGUE_OF_LIFE
	$fe = $_.FAUNA_EUROPEA

	echo "Vérification de $nom"
	
	if ($code -eq "Oligoglena_tibialis") { $nom = "Cicadivetta tibialis" } # corrections taxonomiques entrée
	
	# FAUNE-FRANCE
	if ($faune_france -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Faune-France" }
	elseif ($code -eq "Cicada_barbara_lusitanica") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas officiellement" -ForegroundColor Yellow -NoNewline;Write-Host " dans Faune-France" } # faux-positif
	else {		
		Invoke-WebRequest -Uri "https://www.faune-france.org/index.php?m_id=94&sp_tg=19&sp_DOffset=1&sp_SChoice=family&sp_Family=1511&sp_SChoice=species&sp_PChoice=all&sp_FDisplay=DATE_PLACE_SPECIES&sp_S=$faune_france" -OutFile "./BDD/FAUNE-FRANCE/code.html"
		$Source = Get-Content -path "./BDD/FAUNE-FRANCE/code.html" -raw
		$Source -match '<span class="sci_name">\((.*?)\)</span>' | Out-Null
		$Sourcecode = $matches[1]
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Faune-France est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
			Write-Host "  > Le code espèce de $nom dans Faune-France est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
			$ff_erreurs = $ff_erreurs + " " + $nom
			$ff_erreurs > "./BDD/FAUNE-FRANCE/erreurs.txt"
		}
	}
	
	# OBSERVATION
	if ($observation -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Observation.org" }
	else {		
		Invoke-WebRequest -Uri "https://observation.org/species/$observation/" -OutFile "./BDD/OBSERVATION/code.html"
		$Source = Get-Content -path "./BDD/OBSERVATION/code.html" -raw
		$Source -match '<i class="species-scientific-name">(.*?)</i>' | Out-Null
		$Sourcecode = $matches[1]
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Observation.org est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
			Write-Host "  > Le code espèce de $nom dans Observation.org est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
			$obs_erreurs = $obs_erreurs + " " + $nom
			$obs_erreurs > "./BDD/OBSERVATION/erreurs.txt"
		}
	}
	
	if ($nom -eq "Cicadivetta tibialis") { $nom = "Oligoglena tibialis" } # corrections taxonomiques sortie

	# INPN
	if ($inpn -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans l'INPN" }
	else {		
		$Sourcecode = (Invoke-WebRequest "https://odata-inpn.mnhn.fr/taxa/$inpn" | ConvertFrom-Json).names.binomial
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans l'INPN est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
			Write-Host "  > Le code espèce de $nom dans l'INPN est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
			$inpn_erreurs = $inpn_erreurs + " " + $nom
			$inpn_erreurs > "./BDD/INPN/erreurs.txt"
		}
	}
	
	# INATURALIST
	if ($inaturalist -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans iNaturalist" }
	else {		
		$Sourcecode = (Invoke-WebRequest "https://api.inaturalist.org/v1/taxa/$inaturalist" | ConvertFrom-Json).results.name
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans iNaturalist est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
			Write-Host "  > Le code espèce de $nom dans iNaturalist est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
			$inat_erreurs = $inat_erreurs + " " + $nom
			$inat_erreurs > "./BDD/INATURALIST/erreurs.txt"
		}
	}
	
	# GBIF
	if ($gbif -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans GBIF" }
	else {		
		$Sourcecode = (Invoke-WebRequest "https://api.gbif.org/v1/species/$gbif" | ConvertFrom-Json).canonicalName
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans GBIF est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
			Write-Host "  > Le code espèce de $nom dans GBIF est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
			$gbif_erreurs = $gbif_erreurs + " " + $nom
			$gbif_erreurs > "./BDD/GBIF/erreurs.txt"
		}
	}
	
	# CATALOGUE OF LIFE
	if ($code -eq "Tibicina_tomentosa") { $nom = "Tibicina picta" } # corrections taxonomiques entrée
	if ($cof -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Catalogue of Life" }
	else {		
		$Sourcecode = (Invoke-WebRequest "https://api.checklistbank.org/dataset/9916/taxon/$cof" | ConvertFrom-Json).name.scientificName
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Catalogue of Life est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
			Write-Host "  > Le code espèce de $nom dans Catalogue of Life est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
			$cof_erreurs = $cof_erreurs + " " + $nom
			$cof_erreurs > "./BDD/CATALOGUE_OF_LIFE/erreurs.txt"
		}
	}
	if ($nom -eq "Tibicina picta") { $nom = "Tibicina tomentosa" } # corrections taxonomiques sortie
	
	# FAUNA-EUROPEA
	if ($fe -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Fauna-Europea" }
	else {		
		Invoke-WebRequest -Uri "https://www.eu-nomen.eu/portal/taxon.php?GUID=urn:lsid:faunaeur.org:taxname:$fe" -OutFile "./BDD/FAUNA-EUROPEA/code.html"
		$Source = Get-Content -path "./BDD/FAUNA-EUROPEA/code.html" -raw
		$Source -match '<H1><i>(.*?)</i>' | Out-Null
		$Sourcecode = $matches[1]
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Fauna-Europea est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
			Write-Host "  > Le code espèce de $nom dans Fauna-Europea est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
			$fe_erreurs = $fe_erreurs + " " + $nom
			$fe_erreurs > "./BDD/FAUNA-EUROPEA/erreurs.txt"
		}
	}

# fin de foreach
}
echo "##################################################################################"
if (-not(Test-Path -Path "./BDD/FAUNE-FRANCE/erreurs.txt"  -PathType Leaf)) { Write-Host "  > Tous les codes espèces de Faune-France sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host " dans Faune-France"
	$ff_txt = (Get-Content "./BDD/FAUNE-FRANCE/erreurs.txt") + "`n`n"
	Remove-item "./BDD/FAUNE-FRANCE/code.html"
	Remove-item "./BDD/FAUNE-FRANCE/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/INPN/erreurs.txt"  -PathType Leaf)) { Write-Host "  > Tous les codes espèces de l'INPN sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host " dans l'INPN"
	$inpn_txt = (Get-Content "./BDD/INPN/erreurs.txt") + "`n`n"
	Remove-item "./BDD/INPN/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/INATURALIST/erreurs.txt" -PathType Leaf)) { Write-Host "  > Tous les codes espèces de iNaturalist sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans iNaturalist"
	$inat_txt = (Get-Content "./BDD/INATURALIST/erreurs.txt") + "`n`n"
	Remove-item "./BDD/INATURALIST/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/OBSERVATION/erreurs.txt" -PathType Leaf)) { Write-Host "  > Tous les codes espèces de Observation.org sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans Observation.org"
	$obs_txt = (Get-Content "./BDD/OBSERVATION/erreurs.txt") + "`n`n"
	Remove-item "./BDD/OBSERVATION/code.html"
	Remove-item "./BDD/OBSERVATION/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/GBIF/erreurs.txt" -PathType Leaf)) { Write-Host "  > Tous les codes espèces de GBIF sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans GBIF"
	$gbif_txt = (Get-Content "./BDD/GBIF/erreurs.txt") + "`n`n"
	Remove-item "./BDD/GBIF/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/CATALOGUE_OF_LIFE/erreurs.txt" -PathType Leaf)) { Write-Host "  > Tous les codes espèces de Catalogue of Life sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans Catalogue of Life"
	$cof_txt = (Get-Content "./BDD/CATALOGUE_OF_LIFE/erreurs.txt") + "`n`n"
	Remove-item "./BDD/CATALOGUE_OF_LIFE/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/FAUNA-EUROPEA/erreurs.txt" -PathType Leaf)) { Write-Host "  > Tous les codes espèces de Fauna-Europea sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans Fauna-Europea"
	$fe_txt = Get-Content "./BDD/FAUNA-EUROPEA/erreurs.txt"
	Remove-item "./BDD/FAUNA-EUROPEA/erreurs.txt"
}

$erreurs = $ff_txt + $inpn_txt + $inat_txt + $obs_txt + $gbif_txt + $cof_txt + $fe_txt

if ($erreurs -eq $null) {Write-Host "Tous les codes espèces sont corrects !" -ForegroundColor Green}
else {
	Write-Host "Les erreurs des bases de données sont : " -ForegroundColor Red
	echo $erreurs
}
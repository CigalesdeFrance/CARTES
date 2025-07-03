$cigales_codes = Import-CSV "CIGALES-CODES.csv"

# Test des URL
try { $INPN_url = (Invoke-WebRequest -Uri 'https://openobs.mnhn.fr/biocache-service/occurrences/search' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse } catch { $INPN_url = New-Object -TypeName PSObject -Property @{ StatusCode = "NOK"; Message = "Le site est inaccessible" } }
try { $INATURALIST_url = (Invoke-WebRequest -Uri 'https://api.inaturalist.org/v1/docs/' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse } catch { $INATURALIST_url = New-Object -TypeName PSObject -Property @{ StatusCode = "NOK"; Message = "Le site est inaccessible" } }
try { $OBSERVATION_url = (Invoke-WebRequest -Uri 'https://observation.org/api/v1/docs/' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse } catch { $OBSERVATION_url = New-Object -TypeName PSObject -Property @{ StatusCode = "NOK"; Message = "Le site est inaccessible" } }
try { $GBIF_url = (Invoke-WebRequest -Uri 'https://api.gbif.org/v1/occurrence/search' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse } catch { $GBIF_url = New-Object -TypeName PSObject -Property @{ StatusCode = "NOK"; Message = "Le site est inaccessible" } }
try { $FF_url = (Invoke-WebRequest -Uri 'https://www.faune-france.org' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse } catch { $FF_url = New-Object -TypeName PSObject -Property @{ StatusCode = "NOK"; Message = "Le site est inaccessible" } }
try { $WAD_url = (Invoke-WebRequest -Uri 'https://hoppers.speciesfile.org/' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse } catch { $WAD_url = New-Object -TypeName PSObject -Property @{ StatusCode = "NOK"; Message = "Le site est inaccessible" } }
try { $FE_url = (Invoke-WebRequest -Uri 'https://www.eu-nomen.eu/portal/index.php' -SkipHttpErrorCheck -ErrorAction Stop).BaseResponse } catch { $FE_url = New-Object -TypeName PSObject -Property @{ StatusCode = "NOK"; Message = "Le site est inaccessible" } }

$ff_erreurs = "Faune-France :"
$inpn_erreurs = "INPN :"
$wad_erreurs = "WAD :"
$inat_erreurs = "iNaturalist :"
$obs_erreurs = "Observation :"
$gbif_erreurs = "GBIF :"
$col_erreurs = "COL :"
$fe_erreurs = "Fauna-Europea :"

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
	
	echo "Vérification de $nom"
	
	# FAUNE-FRANCE
	if ($FF_url.StatusCode -eq "OK") {
		if ($faune_france -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Faune-France" }
		elseif ($code -eq "Cicada_barbara") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas officiellement" -ForegroundColor Yellow -NoNewline;Write-Host " dans Faune-France" } # faux-positif
		else {		
			Invoke-WebRequest -Uri "https://www.faune-france.org/index.php?m_id=94&sp_tg=19&sp_DOffset=1&sp_SChoice=family&sp_Family=1511&sp_SChoice=species&sp_PChoice=all&sp_FDisplay=DATE_PLACE_SPECIES&sp_S=$faune_france" -OutFile "./BDD/FAUNE-FRANCE/code.html"
			$Source = Get-Content -path "./BDD/FAUNE-FRANCE/code.html" -raw
			Remove-item "./BDD/FAUNE-FRANCE/code.html"
			$Source -match '<span class="sci_name">\((.*?)\)</span>' | Out-Null
			$Sourcecode = $matches[1]
			
			if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Faune-France est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
			else {
				Write-Host "  > Le code espèce de $nom dans Faune-France est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
				$ff_erreurs = $ff_erreurs + " " + $nom
				$ff_erreurs > "./BDD/FAUNE-FRANCE/erreurs.txt"
			}
		}
	}
	else {
		"  > Faune-France est inaccessible"
	}
	
	# OBSERVATION
	if ($OBSERVATION_url.StatusCode -eq "OK") {
		if ($observation -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Observation.org" }
		else {		
			$Sourcecode = (Invoke-RestMethod -Uri "https://observation.org/api/v1/species/$observation/" -Method Get).scientific_name
			
			if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Observation.org est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
			else {
				Write-Host "  > Le code espèce de $nom dans Observation.org est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
				$obs_erreurs = $obs_erreurs + " " + $nom
				$obs_erreurs > "./BDD/OBSERVATION/erreurs.txt"
			}
		}
	}
	else {
		"  > L'API d'Observation.org est inaccessible"
	}
	
	if ($INPN_url.StatusCode -eq "OK") {
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
	}
	else {
		"  > L'API de l'INPN est inaccessible"
	}
	
	if ($nom -eq "Platypleura kaempferi") { $nom = "Planopleura kaempferi" } # corrections taxonomiques entrée
	
	# WAD - World Auchenorrhyncha Database
	if ($WAD_url.StatusCode -eq "OK") {
		if ($wad -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans World Auchenorrhyncha Database" }
		else {		
			$Sourcecode_json = (Invoke-WebRequest "https://sfg.taxonworks.org/api/v1/otus/$wad/inventory/taxonomy.json?project_token=ZEJhFp9sq8kBfks15qAbAg" | ConvertFrom-Json).name
			$Sourcecode_json -match "<i>(.*)<\/i>"  | Out-Null
			$Sourcecode = $matches[1]
			
			if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans World Auchenorrhyncha Database est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
			else {
				Write-Host "  > Le code espèce de $nom dans World Auchenorrhyncha Database est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
				$wad_erreurs = $wad_erreurs + " " + $nom
				$wad_erreurs > "./BDD/WAD/erreurs.txt"
			}
		}
	}
	else {
		"  > WAD est inaccessible"
	}
	
	if ($nom -eq "Planopleura kaempferi") { $nom = "Platypleura kaempferi" } # corrections taxonomiques sortie
	
	# INATURALIST
	if ($INATURALIST_url.StatusCode -eq "OK") {
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
	}
	else {
		"  > L'API d'iNaturalist est inaccessible"
	}
	
	# GBIF
	if ($GBIF_url.StatusCode -eq "OK") {
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
	}
	else {
		"  > L'API de GBIF est inaccessible"
	}
	
	<#  	# CATALOGUE OF LIFE
		if ($col -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Catalogue of Life" }
		else {		
		$Sourcecode = (Invoke-WebRequest "https://api.checklistbank.org/dataset/9916/taxon/$col" | ConvertFrom-Json).name.scientificName
		
		if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Catalogue of Life est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
		else {
		Write-Host "  > Le code espèce de $nom dans Catalogue of Life est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
		}
	} #>
	
	# FAUNA-EUROPEA
	if ($FE_url.StatusCode -eq "OK") {
		if ($fauna_europea -eq "") { Write-Host "  > $nom "-NoNewline; Write-Host "n'existe pas" -ForegroundColor Yellow -NoNewline;Write-Host " dans Fauna-Europea" }
		else {		
			Invoke-WebRequest -Uri "https://www.eu-nomen.eu/portal/taxon.php?GUID=urn:lsid:faunaeur.org:taxname:$fauna_europea" -OutFile "./BDD/FAUNA-EUROPEA/code.html"
			$Source = Get-Content -path "./BDD/FAUNA-EUROPEA/code.html" -raw
			Remove-item "./BDD/FAUNA-EUROPEA/code.html"
			$Source -match '<H1><i>(.*?)</i>' | Out-Null
			$Sourcecode = $matches[1]
			
			if ($nom -eq $Sourcecode) { Write-Host "  > Le code espèce de $nom dans Fauna-Europea est "-NoNewline; Write-Host "correct" -ForegroundColor Green }
			else {
				Write-Host "  > Le code espèce de $nom dans Fauna-Europea est "-NoNewline; Write-Host "incorrect" -ForegroundColor Red
				$fe_erreurs = $fe_erreurs + " " + $nom
				$fe_erreurs > "./BDD/FAUNA-EUROPEA/erreurs.txt"
			}
		}
	}
	else {
		"  > Fauna-Europea est inaccessible"
	}
	
	# fin de foreach
}
echo "##################################################################################"
if (-not(Test-Path -Path "./BDD/FAUNE-FRANCE/erreurs.txt"  -PathType Leaf)) { 
	Write-Host "  > Tous les codes espèces de Faune-France sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green
} 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host " dans Faune-France"
	$ff_txt = (Get-Content "./BDD/FAUNE-FRANCE/erreurs.txt") + "`n`n"
	Remove-item "./BDD/FAUNE-FRANCE/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/INPN/erreurs.txt"  -PathType Leaf)) { Write-Host "  > Tous les codes espèces de l'INPN sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host " dans l'INPN"
	$inpn_txt = (Get-Content "./BDD/INPN/erreurs.txt") + "`n`n"
	Remove-item "./BDD/INPN/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/WAD/erreurs.txt" -PathType Leaf)) { Write-Host "  > Tous les codes espèces de World Auchenorrhyncha Database sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans World Auchenorrhyncha Database"
	$wad_txt = (Get-Content "./BDD/WAD/erreurs.txt") + "`n`n"
	Remove-item "./BDD/WAD/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/INATURALIST/erreurs.txt" -PathType Leaf)) { Write-Host "  > Tous les codes espèces de iNaturalist sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green } 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans iNaturalist"
	$inat_txt = (Get-Content "./BDD/INATURALIST/erreurs.txt") + "`n`n"
	Remove-item "./BDD/INATURALIST/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/OBSERVATION/erreurs.txt" -PathType Leaf)) {
	Write-Host "  > Tous les codes espèces de Observation.org sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green
} 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans Observation.org"
	$obs_txt = (Get-Content "./BDD/OBSERVATION/erreurs.txt") + "`n`n"
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
	$col_txt = (Get-Content "./BDD/CATALOGUE_OF_LIFE/erreurs.txt") + "`n`n"
	Remove-item "./BDD/CATALOGUE_OF_LIFE/erreurs.txt"
}

if (-not(Test-Path -Path "./BDD/FAUNA-EUROPEA/erreurs.txt" -PathType Leaf)) {
	Write-Host "  > Tous les codes espèces de Fauna-Europea sont "-NoNewline; Write-Host "corrects" -ForegroundColor Green
} 
else {
	Write-Host "  > Quelques codes espèces sont "-NoNewline; Write-Host "en erreur" -ForegroundColor Red -NoNewline;Write-Host "  dans Fauna-Europea"
	$fe_txt = Get-Content "./BDD/FAUNA-EUROPEA/erreurs.txt"
	Remove-item "./BDD/FAUNA-EUROPEA/erreurs.txt"
}

$erreurs = $ff_txt + $inpn_txt + $wad_txt + $inat_txt + $obs_txt + $gbif_txt + $col_txt + $fe_txt

if ($erreurs -eq $null) {Write-Host "Tous les codes espèces sont corrects !" -ForegroundColor Green}
else {
	Write-Host "Les erreurs des bases de données sont : " -ForegroundColor Red
	echo $erreurs
}
var espece = location.search.substring(1);
$("#choix option[espece='" + espece + "']").attr("selected","selected");

var choix = document.getElementById('choix');
choix.onchange = function() {
	
	var espece = this.options[this.selectedIndex].getAttribute('espece');
	
	carte_interactive.innerHTML = '<button class="detail"><a href="../">➤ Carte interactive</a></button>';
	
	// MISE A JOUR DE L'URL EN TEMPS REEL //
	if (espece !== null) {
		var change_url = { Title: espece, Url: 'index.html?'+ espece	};
		history.pushState(change_url, change_url.Title, change_url.Url);

	
		// MISE A JOUR DES CARTES + intégration si l'espèce n'existe pas dans la BDD //
		carte_interactive.innerHTML = '<button class="detail"><a href="../index.html?' + espece + '">➤ Carte interactive</a></button>';
		fiche_espece.innerHTML = '<button class="detail"><a href="https://www.cigalesdefrance.fr/espece:' + espece + '" target="_blank">➤ Fiche espèce</a></button>';
		
	};
	
	var ff_url = 'https://cartes.cigalesdefrance.fr/BDD/FAUNE-FRANCE/IMG/' + espece + '.png';
	var onem_url = 'https://cartes.cigalesdefrance.fr/BDD/ONEM/' + espece + '.jpg';
	var gbif_url = 'https://cartes.cigalesdefrance.fr/BDD/GBIF-EUROPE/'+ espece + '.png';
	var pheno_url = 'https://cartes.cigalesdefrance.fr/STATISTIQUES/PHENOLOGIE/'+ espece + '.png';
	var alt_url = 'https://cartes.cigalesdefrance.fr/STATISTIQUES/ALTITUDE/'+ espece + '.png';
	
	check_ff(ff_url);
	function check_ff(ff_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', ff_url, false);
        http.send();
        if (http.status != 404) {
			console.log("URL de Faune-France accessible ✅");
            ffmapdiv.innerHTML = '<img class="ffmap" src="'+ ff_url +'" alt="Carte de la répartition de l\'espèce provenant de Faune-France">';
		}
        else {
			console.log("URL de Faune-France inaccessible ⛔");
			ffmapdiv.innerHTML = '<img class="ffmap" src="https://cartes.cigalesdefrance.fr/BDD/FAUNE-FRANCE/IMG/null.png"/ alt="Carte vide provenant de Faune-France">';
		}
	}
	
	check_onem(onem_url);
	function check_onem(onem_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', onem_url, false);
        http.send();
        if (http.status != 404) {
			console.log("URL de ONEM accessible ✅");
            onemdiv.innerHTML = '<img class="onem" src="'+ onem_url +'" alt="Carte de la répartition de l\'espèce provenant de l\'ONEM">';
		}
        else {
			console.log("URL de ONEM inaccessible ⛔");
			onemdiv.innerHTML = '<img class="onem" src="https://cartes.cigalesdefrance.fr/BDD/ONEM/null.jpg" alt="Carte vide provenant de l\'ONEM">';
		}
	}
	
	check_gbif(gbif_url);
	function check_gbif(gbif_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', gbif_url, false);
        http.send();
        if (http.status != 404) {
			console.log("URL de GBIF accessible ✅");
            gbifdiv.innerHTML = '<img class="gbif" src="'+ gbif_url +'" alt="Carte de la répartition de l\'espèce provenant de GBIF">';
		}
        else {
			console.log("URL de GBIF inaccessible ⛔");
			gbifdiv.innerHTML = '<img class="gbif" src="https://cartes.cigalesdefrance.fr/BDD/GBIF-EUROPE/null.png" alt="Carte vide provenant de GBIF">';
		}
	}

	check_pheno(pheno_url);
	function check_pheno(pheno_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', pheno_url, false);
        http.send();
        if (http.status != 404) {
			console.log("Phénologie accessible ✅");
            phenodiv.innerHTML = '<img class="gbif" style="max-width: 80%;" src="'+ pheno_url +'" alt="Phénologie des observations">';
		}
        else {
			console.log("Phénologie inaccessible ⛔");
			phenodiv.innerHTML = '<img class="gbif" src="https://cartes.cigalesdefrance.fr/STATISTIQUES/PHENOLOGIE/null.png" alt="Aucune phénologie">';
		}
	}

	check_alt(alt_url);
	function check_alt(alt_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', alt_url, false);
        http.send();
        if (http.status != 404) {
			console.log("Altitudes accessibles ✅");
            altdiv.innerHTML = '<img class="gbif" style="max-width: 80%;" src="'+ alt_url +'" alt="Altitudes des observations">';
		}
        else {
			console.log("Altitudes inaccessibles ⛔");
			altdiv.innerHTML = '<img class="gbif" src="https://cartes.cigalesdefrance.fr/STATISTIQUES/ALTITUDE/null.png" alt="Aucune altitude">';
		}
	}
	
	};
	choix.onchange();

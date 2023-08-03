var espece = location.search.substring(1);
$("#choix option[espece='" + espece + "']").attr("selected","selected");

var choix = document.getElementById('choix');
choix.onchange = function() {
	
	var espece = this.options[this.selectedIndex].getAttribute('espece');
	
	// MISE A JOUR DE L'URL EN TEMPS REEL //
	if (espece !== null) {
		var change_url = { Title: espece, Url: 'index.html?'+ espece	};
		history.pushState(change_url, change_url.Title, change_url.Url);
	}
	
	// MISE A JOUR DES CARTES + intégration si l'espèce n'existe pas dans la BDD //
	carte_interactive.innerHTML = '<button><a href="../index.html?' + espece + '">➤ Carte interactive</a></button>';
	
	var ff_url = 'https://cartes.cigalesdefrance.fr/BDD/FAUNE-FRANCE/' + espece + '.png';
	var onem_url = 'https://cartes.cigalesdefrance.fr/BDD/ONEM/' + espece + '.jpg';
	var gbif_url = 'https://cartes.cigalesdefrance.fr/BDD/GBIF-EUROPE/'+ espece + '.png';
	
	check_ff(ff_url);
	function check_ff(ff_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', ff_url, false);
        http.send();
        if (http.status != 404) {
			console.log("URL de Faune-France accessible ✅");
            ffmapdiv.innerHTML = '<img class="ffmap" src="'+ ff_url +'"/>';
		}
        else {
			console.log("URL de Faune-France inaccessible ⛔");
			ffmapdiv.innerHTML = '<img class="ffmap" src="https://cartes.cigalesdefrance.fr/BDD/FAUNE-FRANCE/null.png"/>';
		}
	}
	
	check_onem(onem_url);
	function check_onem(onem_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', onem_url, false);
        http.send();
        if (http.status != 404) {
			console.log("URL de ONEM accessible ✅");
            onemdiv.innerHTML = '<img class="onem" src="'+ onem_url +'"/>';
		}
        else {
			console.log("URL de ONEM inaccessible ⛔");
			onemdiv.innerHTML = '<img class="onem" src="https://cartes.cigalesdefrance.fr/BDD/ONEM/null.jpg"/>';
		}
	}
	
	check_gbif(gbif_url);
	function check_gbif(gbif_url) {
        var http = new XMLHttpRequest();
        http.open('HEAD', gbif_url, false);
        http.send();
        if (http.status != 404) {
			console.log("URL de GBIF accessible ✅");
            gbifdiv.innerHTML = '<img class="gbif" src="'+ gbif_url +'"/>';
		}
        else {
			console.log("URL de ONEM inaccessible ⛔");
			gbifdiv.innerHTML = '<img class="gbif" src="https://cartes.cigalesdefrance.fr/BDD/GBIF-EUROPE/null.png"/>';
		}
	}
	
	
	};
	choix.onchange();
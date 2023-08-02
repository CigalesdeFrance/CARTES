var espece = location.search.substring(1);
$("#choix option[espece='" + espece + "']").attr("selected","selected");

var choix = document.getElementById('choix');
choix.onchange = function() {
	//title.innerHTML = this.options[this.selectedIndex].text;
	//sp.innerHTML = this.options[this.selectedIndex].getAttribute('espece');
	var espece = this.options[this.selectedIndex].getAttribute('espece');
	
	
	carte_interactive.innerHTML = '<button><a href="https://cartes.cigalesdefrance.fr/index.html?' + espece + '">➤ Carte interactive</a></button>';
	ffmapdiv.innerHTML = '<img class="ffmap" src="https://cartes.cigalesdefrance.fr/BDD/FAUNE-FRANCE/' + espece + '.png"/>'
	onemdiv.innerHTML = '<img class="onem" src="https://cartes.cigalesdefrance.fr/BDD/ONEM/'+ espece + '.jpg"/>';
	gbifdiv.innerHTML = '<img class="gbif" src="https://cartes.cigalesdefrance.fr/BDD/GBIF-EUROPE/'+ espece + '.png"/>';
	
};
choix.onchange();


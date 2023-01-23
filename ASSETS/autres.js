var espece = location.search.substring(1);
$("#choix option[espece='" + espece + "']").attr("selected","selected");

var choix = document.getElementById('choix');
choix.onchange = function() {
	//title.innerHTML = this.options[this.selectedIndex].text;
	//sp.innerHTML = this.options[this.selectedIndex].getAttribute('espece');
	var espece = this.options[this.selectedIndex].getAttribute('espece');
	
	
	carte_interactive.innerHTML = '<button><a href="../index.html?' + espece + '">🡲 Carte interactive</a></button>';
	ffmapdiv.innerHTML = '<img class="ffmap" style="z-index:1" src="../ASSETS/fond.jpg"><img class="ffmap" style="z-index:2" src="../BDD/FAUNE-FRANCE/' + espece + '.png">';
	onemdiv.innerHTML = '<img class="onem" src="../BDD/ONEM/'+ espece + '.jpg">';
	
	
};
choix.onchange();
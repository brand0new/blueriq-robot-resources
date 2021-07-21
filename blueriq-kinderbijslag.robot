# Gebruik dit soort test voornamelijk om regressie te testen van verschillende paden door de applicatie heen
# Het is namelijk (nog) niet mogelijk om direct naar een bepaalde niet-exposed flow te springen met een bijbehorend profiel.
# Hiervoor is het Blueriq Test Center in ontwikkeling.
# ROBOT bied - met deze library - een relatief toegankelijke tool om Blueriq applicaties te testen zonder gebruik te maken van de GUI.

*** Settings ***
Resource         blueriq.resource

*** Variables ***
# Het is mogelijk om variabelen aan te maken en deze waardes te geven. 
# Hieronder een aantal voorbeelden van een mogelijke opzet.
# De test wordt robuuster afhankelijk van de opzet en de daar vooruitkomende afhankelijkheden tussen test onderling

${SERVER}        http://localhost
${PORT}          140
${PROJECT}       export-Kinderbijslag
${FLOW}          Start
${URL}           /runtime/server/api/v2/start?project=${PROJECT}&flow=${FLOW}
${SID}           

*** Test Cases ***
Bereken kinderbijslag voor één kind
    [Documentation]       Gegevens van de aanvrager worden opgegeven.
    ...                   "Registratie" wordt gevalideerd op het tweede scherm.
    ...                   Er wordt één kind toegevoegd en wordt gekeken of de totale kindertoeslag op 
    ...                   het juiste bedrag uitkomt.

    ${SID}                BQ - Create Session    $username

    BQ - Start            BQsession       ${SID}   
    BQ - Load Session     
    BQ - Set Value        Voornaam        Jan
    BQ - Set Value        Achternaam      Janssen
    BQ - Set Value        Straat          Straat
    BQ - Set Value        Geslacht        Man
    BQ - Set Value        Huisnummer      1
    BQ - Set Value        Postcode        1111AA
    BQ - Set Value        Woonplaats      Amsterdam
    BQ - Set Value        Land            Nederland
    BQ - Press Button     Verder                       
    BQ - Check Text       Jan Janssen
    BQ - Press Button     "Kind toevoegen"
    BQ - Set Value        "Wordt de vrouw uit het gezin op grond van artikel 198 van Boek 1 van het Burgelijk Wetboek als zijn/haar moeder aangemerkt?"    Ja
    BQ - Set Value        "Behoort het kind tot uw huishouden?"               Ja
    BQ - Set Value        "Woonde uw kind de eerste dag van het kalenderkwartaal in Nederland?"    Ja
    BQ - Set Value        Voornaam        Jan jr
    BQ - Set Value        Geboortedatum   05-06-2020
    BQ - Press Button     Verder
    BQ - Check Text       Jan jr
    BQ - Press Button     "Bereken kinderbijslag"
    BQ - Check Value      "Kinderbijslag totaal"   188,57

# De testcase hierboven zou gebruikt kunnen worden om de regressie van het berekenen van de kinderbijslag functionaliteit te borgen.
# Deze testcase is niet opgeknipt kleinere test omdat het functioneren en juist afleiden van de totale kinderbijslag al in het model kan worden gedaan.
# Daarnaast is het doel om te valideren dat de interactie tussen gebruiker en domeinmodel - middels pagina modellen - blijft werken zoals verwacht.
# Hier zouden meer validatie aan toegevoegd kunnen. In dit besluit moet worden meegenomen of het mogelijk is om de logica al in de Studio te valideren.
#
# Voor vragen en/of opmerkingen kun je terecht bij:
# Louis Wouters      (l.wouters@blueriq.com)
# Brandon Verzuu     (b.verzuu@blueriq.com)
#
# Voor meer informatie omtrent de UI REST API (v2) raadpleeg onze community site: https://bit.ly/3hU0lmZ
### Blueriq ROBOT Library ###
# Hieronder zijn standaard Keywords gemaakt voor het ROBOT testautomatiseringsframework (https://robotframework.org/)
# Om gebruik te kunnen maken van deze library moeten onderstaande libraries gedownload worden. (https://packaging.python.org/tutorials/installing-packages/)
# Het is ook mogelijk om gebruik te maken van de ROBOT editor RIDE. (https://github.com/robotframework/RIDE)
#
# (GithubLink?)
# Version: 1.0.0.
#
# Developers / Maintainers
# Louis Wouters         (l.wouters@blueriq.com)
# Brandon Verzuu        (b.verzuu@blueriq.com)
#

*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    JSONLibrary
Library    String
Library    OperatingSystem    
Library    DateTime
Library    XML

*** Variables ***
&{BQ}       alias=    subscriptionId=    sessionId=    page=    event=    eventResponse=    csrf=

*** Keywords ***

BQ - Create Session
    [Documentation]            Met keyword maak je verbinding met de API server
    ...                        Zonder dit kan je geen post/get reqeust uitvoeren op de server
    [Arguments]                ${username}

    ${currentSession}          Create Session      BQsession     ${SERVER}:${PORT}
    ${header}                  Create dictionary   Content-Type=application/json;charset=UTF-8
    
    ${Resp}                    Post On Session     BQsession     url=${URL}    headers=${header}
    Should be equal as strings     ${Resp.status_code}           200
    
    ${postUrl}                 Post On Session     BQsession     url=${URL}
    Should be equal as strings     ${postUrl.status_code}        200
    
    ${subscriptionId}          Set Variable        ${postUrl.json()['sessionId']}
    [Return]                   ${subscriptionId}

BQ - Login   
    [Documentation]            Inloggen op een sessie
    ${postUrl}                 Post On Session    ${BQ.alias}    url=/runtime/server/api/v2/login?username=Aanvrager&password=1
    Should be equal as strings     ${postUrl.status_code}        204

BQ - Close Session
    [Documentation]            Sluiten van een Blueriq sessie.
    ...                        Dit is essentieel voor het bewust omgaan met beschikbare middelen.
    ${loadResponse}            Post On Session    ${BQ.alias}     url=/runtime/server/api/v2/session/${BQ.sessionId}/close
    Should Be Equal As Strings    ${loadResponse.status_code}     200

BQ - Start
    [Documentation]            Start een Blueriq instantie.
    [arguments]                ${alias}    ${sessionId}
    Set to Dictionary          ${BQ}    sessionId=${sessionId}    alias=${alias}    subscriptionId=${sessionId}
    BQ - Load Session

BQ - Start Flow
    [Documentation]            Start een nieuwe flow in een bestaande Blueriq sessie.
    [Arguments]                ${alias}    ${sessionId}     ${flowName}
    Set to Dictionary          ${BQ}    sessionId=${sessionId}    alias=${alias}    subscriptionId=${sessionId}
    ${loadResponse}            Post On Session     ${BQ.alias}    url=/runtime/server/api/v2/session/${BQ.sessionId}/flow/${flowName}
    
BQ - Activate Main Session
    BQ - Set Session           ${BQ.subscriptionId}

BQ - Load Session
    [documentation]               Laad paginamodel in inclusief CSRF token
    ${loadResponse}               Post on Session    ${BQ.alias}    url=/runtime/server/api/v2/session/${BQ.sessionId}/load   
    Should be equal as strings    ${loadResponse.status_code}    200    msg=Laden pagina mislukt: sessionId="${BQ.sessionId}"
    Set To Dictionary             ${BQ}    page    ${loadResponse.json()}
    ${csrfToken}                  Get Value From Json       ${loadResponse.json()}    $..csrfToken
    ${header}                     Create Dictionary    X-CSRF-Token=${csrfToken}[0]          
    Update Session                ${BQ.alias}    headers=${header}
    Log                           csrftoken ${csrftoken}
    BQ - Create Event
    
# BQ - Load Session
#    [documentation]               Laad paginamodel in
#    ${loadResponse}               Post on Session    ${BQ.alias}    url=/runtime/server/api/v2/session/${BQ.sessionId}/load   
#    Should be equal as strings    ${loadResponse.status_code}    200    msg=Laden pagina mislukt: sessionId="${BQ.sessionId}"
#    Set To Dictionary             ${BQ}    page    ${loadResponse.json()}
#    BQ - Create Event
  
BQ - Set Session
    [documentation]            Switch de focus van de requests naar een andere (deel)sessie
    [arguments]                ${sessionId}
    ${BQ.sessionId}            Set Variable    ${sessionId}
    BQ - Load Session

BQ - Activate Widget
    [documentation]            Een Blueriq subscription kan bestaan uit meerdere deelsessies. 
    ...                        Om ervoor te zorgen dat de commando's naar de juiste deelsessie gaan moet
    ...                        deze sessie geactiveerd worden.
    [arguments]                ${widgetName}  
       
    # Vind widget op de pagina
    ${widget}    BQ - Get Unique Element by JSON filter    name == ${widgetName} & contentStyle == "dashboard_flowwidget"    ${BQ.page}[elements]
    
    # Verkrijg sessionId van de widget
    ${widgetInfo}                 Post on Session    ${BQ.alias}    url=/runtime/server/api/v2/session/${BQ.sessionId}/widget/WidgetInfo_${widgetName}
    Should be Equal as Strings    200    ${widgetInfo.status_code}    msg=Widget laden mislukt: ${widgetName}
    ${widgetSessionId}            Set Variable    ${widgetInfo.json()}[sessionId]

    # Laad widget
    BQ - Set Session           ${widgetSessionId} 

BQ - Start Task
    [Documentation]            Zoekt naar de taaknaam en drukt op de knop aan het begin van die rij.
    [arguments]                ${taskName}
    
    # zoek het element waarvan de text overeenkomt
    ${element}                 BQ - Get Element by JSON filter    text == ${taskName}
    ${tableRowKey}    @{rest}  Split string from Right     ${element}[key]    -    2
    ${startButtonKey}          Set Variable                ${tableRowKey}-C0-B0
    BQ - Press Button          ${startButtonKey}           key

BQ - Press Button
    [documentation]            Klik op een knop, standaard wordt gematched op de caption,
    ...                        maar er kan bijvoorbeeld ook op functionalKey worden gezocht door een 2e argument mee te geven
    ...                        als containerKey wordt meegegeven wordt er gezocht op een unieke match binnen deze container
    [arguments]                ${matchValue}    ${matchBy}=caption    ${occurrence}=${EMPTY}    ${containerKey}=${EMPTY}
    
    # zoek de juiste button
    IF    "${containerKey}"=="${EMPTY}"
        IF    "${occurrence}"=="${EMPTY}"
            ${button}          BQ - Get Unique Element by JSON filter    type == button & ${matchBy} == ${matchValue}    ${BQ.page}[elements]
        ELSE
            ${button}          BQ - Get Element by Occurrence            type == button & ${matchBy} == ${matchValue}    ${occurrence}
        END
    ELSE
        ${containerChildren}   BQ - Get Container children        ${containerKey}
        ${button}              BQ - Get Unique Element by JSON filter        type == button & ${matchBy} == ${matchValue}    ${containerChildren}
    END

    # Controleer of de knop actief is (not disabled)
    Should Be Equal As Strings    ${button}[disabled]    False    msg=Knop is niet actief: ${matchValue}
   
    # Druk op de knop   
    BQ - Trigger Event            ${button}[functionalKey]
           
BQ - Set Value
    [documentation]            Vul de waarde van een attribuut in, standaard wordt gematched op de questionText,
     ...                       maar er kan bijvoorbeeld ook op functionalKey worden gezocht door een 2e argument mee te geven
     ...                       als containerKey wordt meegegeven wordt er gezocht op een unieke match binnen deze container
    [arguments]    ${matchValue}    ${value}    ${matchBy}=questionText    ${occurrence}=${EMPTY}    ${containerKey}=${EMPTY}
    
    # zoek het juiste veld
    IF    "${containerKey}"=="${EMPTY}"
        IF    "${occurrence}"=="${EMPTY}"
            ${field}           BQ - Get Unique Element by JSON filter    type == field & ${matchBy} == ${matchValue}    ${BQ.page}[elements]
        ELSE
            ${field}           BQ - Get Element by Occurrence            type == field & ${matchBy} == ${matchValue}    ${occurrence}
        END
    ELSE
        ${containerChildren}   BQ - Get Container children       ${containerKey}
        ${field}               BQ - Get Unique Element by JSON filter        type == field & ${matchBy} == ${matchValue}    ${containerChildren}
    END

    ${value}                   BQ - Convert Display Value to Internal Value      ${field}    ${value}   
    
    # Voeg dit veld toe aan het event
    ${value}                    Create List        ${value}
    ${fieldEvent}               Create Dictionary  key=${field}[functionalKey]    values=${value}
    Append To List              ${BQ.event}        ${fieldEvent}   
    
    # In het geval van een refresh, trigger event
    IF    ${field}[refresh]   
        BQ - Trigger Event    ${field}[functionalKey]
    END
    

BQ - Get Value
    [documentation]            Haal de waarde op van een attribuut
    ...                        deze functie werkt nog niet voor multivalued attributen 
    [arguments]                ${matchValue}    ${matchBy}=questionText
    
    # zoek het element
    ${element}                 BQ - Get Unique Element by JSON filter    type == field & ${matchBy} == ${matchValue}    ${BQ.page}[elements]
    ${filledValue}             Set Variable    ${element}[values]
    ${filledValue}             Get from List    ${filledValue}    0
    [Return]                   ${filledValue}
    
BQ - Check Value
    [documentation]            Controleer de waarde van een attribuut
    ...                        deze functie werkt nog niet voor multivalued attributen 
    [arguments]                ${matchValue}    ${checkValue}    ${matchBy}=questionText
    
    # zoek het element
    ${element}                 BQ - Get Unique Element by JSON filter    type == field & ${matchBy} == ${matchValue}    ${BQ.page}[elements]
    
    ${checkValue}              BQ - Convert Display Value to Internal Value    ${element}    ${checkValue}
    ${filledValue}             Set Variable    ${element}[values]
    Should Contain             ${filledValue}    ${checkValue}    msg=${checkValue} ontbreekt bij ${matchValue}

BQ - Check Text
    [documentation]           Controleert of een tekst voorkomt in het paginamodel van de huidige sessie 
    [arguments]               ${text}    ${attribuut}=page
    ${pagina}                 Convert JSON to String    ${BQ.${attribuut}}
    Should Contain            ${pagina}    ${text}    msg=${text} niet gevonden in paginamodel: ${pagina}

BQ - Create Event
    [Documentation]           Initialiseer het event, deze lijst wordt aangevuld telkens als BQ - Set Value wordt aangeroepen.
    ${event}                  Create List
    Set To Dictionary         ${BQ}    event=${event}
    
BQ - Get Domain Value
    [Documentation]            Functie om de interne waarde behorende bij een displayValue te vinden
    [arguments]                ${element}    ${displayValue}
    ${domain}                  Set Variable    ${element}[domain]
    ${domainValue}    @{rest}  Get Value From Json    ${element}[domain]    $[?(displayValue == ${displayValue})]
    Should Not Be Empty        ${domainValue}    msg=Waarde valt buiten het domein: "${displayValue}"
    [return]                   ${domainValue}[value]
    
BQ - Convert Display Value to Internal Value
    [documentation]            Als het veld een waardelijst heeft, wordt de display value omgezet naar een internal value
    [arguments]                ${element}    ${displayValue}

    IF    ${element}[hasDomain]
        ${domainValue}    BQ - Get Domain Value    ${element}    ${displayValue}
    ELSE
        Return From Keyword    ${displayValue}
    END

    [return]                   ${domainValue}

BQ - Trigger Event
    [Documentation]            Verstuur de aanpassingen op de pagina naar Blueriq
    [arguments]                ${elementKey}
        
    # Voeg de niet aangepaste velden toe aan het event
    ${editedFieldsKeys}        Create List
    FOR    ${editedField}    IN    @{BQ.event}
        Append to List  ${editedFieldsKeys}    ${editedField.key}
    END

    ${writableFields}          Get Value From Json    ${BQ.page}[elements]    $[?(type == field & readonly == false)]
    ${workaround}              Create Dictionary    workaround=${writableFields}  # deze regel is blijkbaar nodig
    FOR    ${writableField}    IN    @{writableFields}
        IF    "${writableField.functionalKey}" not in ${editedFieldsKeys}
            ${field}     Create Dictionary    key=${writableField.functionalKey}    values=${writableField.get('values')}
            Append To List    ${BQ.event}    ${field}
        END
    END

    ${event}                   Create Dictionary    fields=${BQ.event}    elementKey=${elementKey}
   
    # Verstuur event
    ${eventResponse}           Post on Session    ${BQ.alias}    url=/runtime/server/api/v2/session/${BQ.sessionId}/event    json=${event}
    Should be equal as strings    ${eventResponse.status_code}    200    msg=Versturen event mislukt: trigger="${elementKey}"
    
    # Haal de laatste sessie uit de response, eventueel eerder voorkomende sessies worden gesloten
    @{sessionList}             Get Value From Json       ${eventResponse.json()}    $..sessionId
    ${sessionId}               Get From List             ${sessionList}    -1      
    Set To Dictionary          ${BQ}    eventResponse    ${eventResponse.json()}
    BQ - Set Session           ${sessionId}

BQ - Get Element by Occurrence
    [arguments]                ${filter}    ${occurrence}
    @{elements}                BQ - Get Elements by JSON filter    ${filter}    ${BQ.page}[elements]
    FOR     ${element}    IN   @{elements}
        ${elementName}    ${elementOccurrence}    Split String From Right    ${element}[functionalKey]    _    1
        Exit For Loop If       ${occurrence}==${elementOccurrence}      
    END

    [return]                   ${element}
        
BQ - Get Unique Element by JSON filter
    [arguments]                    ${filter}    ${elements}=${BQ.page}[elements]
    ${firstElement}    @{rest}     BQ - Get Elements by JSON filter    ${filter}    ${elements} 
    Should be Empty    ${rest}     msg=Element meerdere keren gevonden: ${filter} in ${elements}. Gebruik keyword "BQ - Get Element by Occurrence" om het juiste element aan te duiden.
    [return]                       ${firstElement}

BQ - Get Element by JSON filter
    [Documentation]                Checkt NIET of er meerdere voorkomens zijn en geeft de eerste match terug
    [arguments]                    ${filter}    ${elements}=${BQ.page}[elements]
    ${firstElement}    @{rest}     BQ - Get Elements by JSON filter    ${filter}    ${elements}
    [return]                       ${firstElement}

BQ - Get Elements by JSON filter
    [arguments]                ${filter}    ${elements}
    ${matchingElements}        Get Value From Json    ${elements}    $[?(${filter})]
    Should Not Be Empty        ${matchingElements}    msg=Element niet gevonden: ${filter} in ${elements}
    [return]                   @{matchingElements}

BQ - Write Page to File
    [documentation]            Hier wordt een event getriggered met een niet bestaande eventtrigger om te zorgen dat alle nog niet opgestuurde velden worden ingevuld in Blueriq.
    ...                        daarna wordt de pagina opgeslagen

    BQ - Trigger Event         dummywaarde
    ${page}                    Convert JSON To String    ${BQ.page}
    ${datetime}                Get Current Date    result_format=datetime
    Create File                ${EXECDIR}/BQ_page_${datetime.year}.${datetime.month}.${datetime.day}__${datetime.hour}_${datetime.minute}_${datetime.second}_${datetime.microsecond}.json  ${page}

BQ - Press Button with header
    [documentation]            Standaard wordt gematched op de caption, 
    ...                        ${header}= onder welke kop deze knop zit 
    ...                        ${matchValue}= naam van de knop
    [arguments]                ${header}    ${matchValue}    ${matchBy}=caption
    
    # onder welke header 
    ${element}                 BQ - Get Unique Element by JSON filter    displayName == "${header}"    ${BQ.page}[elements]
    ${tableRowKey}             Set Variable    ${element}[key]
    ${newTableRowKey}          Set Variable    ${tableRowKey}-C0-B1
    ${button}                  BQ - Get Unique Element by JSON filter    key == ${newTableRowKey}    ${BQ.page}[elements]
    
    # knop zoeken 
    ${buttonName}                 Set Variable    ${button}[caption]
    Should Be Equal As Strings    ${buttonName}    ${matchValue}    msg=Heeft niet de juiste knop gevonden: ${matchValue}
     
    # of die wel actief ie
    ${disabled}                   Set Variable    ${button}[disabled]
    Should Be Equal As Strings    ${disabled}    False    msg=Knop is niet actief: ${matchValue}     
    
    # click erop
    ${functionalKey}              Set Variable    ${button}[functionalKey]
    BQ - Trigger Event            ${functionalKey} 

BQ - Get Container children
    [Arguments]                ${containerKey}    ${elements}=${BQ.page}[elements]
    ${children}                Create List
    FOR    ${element}    IN    @{elements}
        IF    '${element}[key]'.startswith(${containerKey}+"-")
            Append To List     ${children}    ${element}
        END  
    END

    Log                        ${children}    
    [Return]                   ${children}

*** Settings ***
Library    RPA.Tables
Library    String
Library    OperatingSystem
Library    SeleniumLibrary  
Library    Collections
Library    ../utils/remover_acentos.py

*** Variables ***
${CSV_FILE}      ${CURDIR}/LOCALIDADES.CSV
${SELECT_ESTADO}         //select[@ng-model="Estado"]
${SELECT_MUNICIPIO}    //select[@ng-model="Municipio"]
${BOTAO_PESQUISAR}    //input[@ng-model="pesquisaValue"]/following-sibling::button
${LISTA_FICHA_ESTABELECIMENTO}     //tr//a
${BOTAO_IMPRIMIR}     //span[@class="glyphicon glyphicon-print"]
${CHECK_FICHA_COMPLETA}     //input[@ng-model="todos"]




&{ESTADOS}
    ...  BA=BAHIA
    ...  MG=MINAS GERAIS
    ...  RJ=RIO DE JANEIRO
    ...  SP=SAO PAULO
    ...  PR=PARANA

*** Keywords ***
Abrir o navegador 
    Open Browser    https://cnes.datasus.gov.br/pages/estabelecimentos/consulta.jsp    chrome
    Maximize Browser Window

Leitura do arquivo CSV e informações
    ${tabela}=    Get File    ${CSV_FILE}
    @{leitura}     Create List     ${tabela}
    @{linhas}    Split To Lines   @{leitura}    1

    FOR  ${linha}  IN  @{linhas}
        @{split}    Split String    ${linha}    ,
        ${ufs}    Set Variable    ${split[0]}
        ${municipios}    Set Variable    ${split[1]}
    
        Pesquisa de estabelecimentos     ${ufs}    ${municipios}
    END
    
Pesquisa de estabelecimentos
    [Arguments]  ${estado_abreviado}   ${municipios}
    ${estado_completo}  Set Variable  ${ESTADOS["${estado_abreviado.upper()}"]}
    ${municipios}     Convert To Uppercase  ${municipios}
    ${municipios_normalizado}     Remover Acentos    ${municipios}

    Wait Until Page Contains Element    ${SELECT_ESTADO}   
    Select From List By Label    ${SELECT_ESTADO}    ${estado_completo}
    Sleep    5s
    Select From List By Label    ${SELECT_MUNICIPIO}    ${municipios_normalizado}
    Sleep    5s
    Click Element    ${BOTAO_PESQUISAR}
    Sleep    5s
    Percorrer a lista de estabelecimentos     ${estado_completo} 


Percorrer a lista de estabelecimentos
    [Arguments]  ${estado_completo} 

    ${quantidade_estabelecimentos}  Set Variable  1
    ${pagina_atual}   Set Variable  1
    ${estabelecimentos_por_pagina}     Set Variable  10
    ${NUM_PAGINAS}   Set Variable  6

    FOR  ${pagina_atual}  IN RANGE    1     ${NUM_PAGINAS}

        @{nova_lista_estabelecimentos}    Get WebElements    ${LISTA_FICHA_ESTABELECIMENTO}

        Wait Until Page Contains Element    ${LISTA_FICHA_ESTABELECIMENTO}

        Sleep    5s

        FOR  ${estabelecimento}  IN  @{nova_lista_estabelecimentos}
            Sleep    10s

            ${link_estabelecimento}    Get Element Attribute    ${estabelecimento}    href

            Execute JavaScript  window.open('${link_estabelecimento}', '_blank')
            Sleep  5s  

            ${janela_atual} =  Get Window Handles
            Switch Window  ${janela_atual}[1]  
            
            Sleep    10s

            Obter informações de um estabelecimento     ${estado_completo} 

            ${quantidade_estabelecimentos}=  Evaluate  ${quantidade_estabelecimentos} + 1

            IF  ${quantidade_estabelecimentos} > ${estabelecimentos_por_pagina}
                ${quantidade_estabelecimentos}  Set Variable  1
                ${pagina_atual}=  Evaluate  ${pagina_atual} + 1
                Click Element    //a[@class="ng-scope"]/span[contains(text(),${pagina_atual})]
                Sleep    10s
                

            END
            Run Keyword If    ${pagina_atual} > ${NUM_PAGINAS}    Exit For Loop
        END
    END
    
Obter informações de um estabelecimento  
    [Arguments]     ${estado_completo} 
    Sleep    10s
 
    ${CNES}=  Get Value    //input[@id="cnes"]

    Sleep    5s

    Click Element    ${BOTAO_IMPRIMIR}
    Sleep    5s

    Select Checkbox    ${CHECK_FICHA_COMPLETA}
    Sleep    5s

    Click Element       //div[@class="panel-footer"]//button
    Sleep    5s

    Manipulação de arquivos     ${estado_completo}     ${CNES}
    Sleep    5s
    
    Close Window

    ${janela_atual} =  Get Window Handles
    
    Switch Window  ${janela_atual}[0]  
    
    Sleep    10s


    
Manipulação de arquivos
    [Arguments]     ${estado_completo}  ${nome_arquivo}

    ${path}     Set Variable  C:/Users/pablo/Downloads

    ${diretorio_existe} =  Run Keyword And Return Status     Directory Should Exist     ${path}/${estado_completo}

    IF  ${diretorio_existe} is False
        Create Directory    ${path}/${estado_completo}
    END

    Sleep    10s

    Move File   ${path}/fichaCompletaEstabelecimento.pdf   ${path}/${estado_completo}/${nome_arquivo}.pdf

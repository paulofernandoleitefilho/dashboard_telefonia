# ============================================================
# Dashboard de Telemática - Hospital Universitário
# Shiny + Plotly (R)
# ============================================================
# O QUE ESTE APP FAZ
# -------------------
# 1) Permite carregar duas planilhas: "Somatorio2024.xlsx" e "Setores.xlsx".
# 2) Cruza os dados pela coluna "Origem" (Somatorio2024) com "Origem"
#    (Setores), trazendo o "Setor" correspondente a cada ramal.
# 3) Mostra filtros no menu lateral: Ramal/Setor (Top 20 por ocorrências)
#    e Quantidade tarifada (valor da fatura).
# 4) Três abas centrais: Lista geral de ramais, Gráficos de barras
#    e Gráficos de pizza - todas responsivas aos filtros.
# 5) Estatística descritiva dos dados filtrados.
#
# COMO USAR
# ---------
# 1. Abra este arquivo no RStudio.
# 2. Rode uma única vez para instalar os pacotes necessários:
#
#    install.packages(c("shiny","shinydashboard","plotly","readxl",
#                        "dplyr","DT","lubridate","scales","tidyr","stringr"))
#
# 3. Clique em "Run App" (ou rode shiny::runApp() no console).
#    O RStudio abrirá o dashboard em uma janela; clique em "Open in Browser"
#    para exibi-lo no Google Chrome.
# 4. No menu lateral, carregue as duas planilhas .xlsx.
#
# IMPORTANTE - NOMES DE COLUNAS ESPERADOS
# ----------------------------------------
#   Somatorio2024.xlsx -> "Origem", "Qtd_Ocorrencias",
#                          "Somatorio_Valor_Fatura" e uma coluna de
#                          data chamada "Data" (usada para calcular
#                          automaticamente o Mês e o Dia da Semana).
#                          Se sua planilha já tiver colunas prontas
#                          chamadas "Mes" e "Dia_Semana", elas também
#                          serão reconhecidas.
#   Setores.xlsx        -> "Origem", "Setor"
#
#   Se os nomes reais das suas colunas forem diferentes, basta ajustar
#   os valores na seção "AJUSTE AQUI" logo abaixo (não precisa mexer
#   no resto do código).
# ============================================================

library(shiny)
library(shinydashboard)
library(plotly)
library(readxl)
library(dplyr)
library(DT)
library(lubridate)
library(scales)
library(tidyr)
library(stringr)

options(shiny.maxRequestSize = 50 * 1024^2) # permite arquivos ate 50MB

# ------------------------------------------------------------
# AJUSTE AQUI: nomes das colunas nas planilhas originais
# ------------------------------------------------------------
COL_ORIGEM       <- "Origem"
COL_QTD_OCORR    <- "Qtd_Ocorrencias"
COL_VALOR_FATURA <- "Somatorio_Valor_Fatura"
COL_DATA         <- "Data"          # usada para derivar mes e dia da semana
COL_SETOR        <- "Setor"

MESES_PT <- c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
              "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")
DIAS_PT  <- c("Domingo","Segunda-feira","Terca-feira","Quarta-feira",
              "Quinta-feira","Sexta-feira","Sabado")

# ============================== UI ===========================
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Telematica HU - Dashboard de Ramais", titleWidth = 320),
  dashboardSidebar(
    width = 320,
    h4("1. Carregar Planilhas", style = "padding-left:15px;"),
    fileInput("file_somatorio", "Somatorio2024.xlsx", accept = ".xlsx", width = "90%"),
    fileInput("file_setores", "Setores.xlsx", accept = ".xlsx", width = "90%"),
    hr(),
    h4("2. Filtros", style = "padding-left:15px;"),
    uiOutput("ui_filtro_ramal"),
    uiOutput("ui_filtro_valor"),
    hr(),
    div(style = "padding-left:15px;",
        actionButton("btn_limpar", "Limpar filtros", icon = icon("eraser"), width = "90%"))
  ),
  dashboardBody(
    tags$head(tags$style(HTML("
      .content-wrapper, .right-side {background-color:#f4f6f9;}
      .box {border-top-color:#3c8dbc;}
      @media (max-width: 768px) {
        .box {margin-bottom: 10px;}
      }

      /* ---- Ajuste de legibilidade dos VALORES dos filtros ---- */
      /* As caixas de rolagem dos filtros (Ramal, Mes, Dia) tem fundo
         branco; forcamos o texto de cada opcao para preto para
         garantir contraste, sem alterar os titulos do menu lateral
         (que continuam claros, pois ficam sobre o fundo escuro). */
      .filtro-caixa {
        background: #ffffff !important;
      }
      .filtro-caixa .checkbox {
        white-space: normal;
        word-wrap: break-word;
      }
      .filtro-caixa label,
      .filtro-caixa .checkbox label,
      .filtro-caixa .checkbox-inline,
      .filtro-caixa span,
      .filtro-caixa input[type='checkbox'] + span {
        color: #000000 !important;
      }

      /* Slider de Quantidade Tarifada: numeros com fundo claro e
         texto preto para ficarem visiveis sobre o menu escuro */
      .main-sidebar .irs--shiny .irs-single,
      .main-sidebar .irs--shiny .irs-from,
      .main-sidebar .irs--shiny .irs-to {
        background: #ffffff !important;
        color: #000000 !important;
        border: 1px solid #d2d6de;
      }
      .main-sidebar .irs--shiny .irs-single:after,
      .main-sidebar .irs--shiny .irs-from:after,
      .main-sidebar .irs--shiny .irs-to:after {
        border-top-color: #ffffff !important;
      }
      .main-sidebar .irs-min,
      .main-sidebar .irs-max {
        color: #000000 !important;
        background: #e9ecef !important;
      }
      .main-sidebar .irs-grid-text {
        color: #000000 !important;
      }

      /* Botoes 'Marcar todos' / 'Desmarcar todos' - fundo claro e
         texto preto para ficarem legiveis sobre o menu escuro */
      .main-sidebar .btn-default {
        background-color: #ecf0f1 !important;
        color: #000000 !important;
        border-color: #d2d6de !important;
      }
      .main-sidebar .btn-default:hover,
      .main-sidebar .btn-default:focus {
        background-color: #dfe4e6 !important;
        color: #000000 !important;
      }
    "))),
    fluidRow(
      valueBoxOutput("vb_total_ramais", width = 3),
      valueBoxOutput("vb_total_ocorrencias", width = 3),
      valueBoxOutput("vb_total_valor", width = 3),
      valueBoxOutput("vb_media_valor", width = 3)
    ),
    fluidRow(
      column(width = 12,
             div(style = "background:#eef3f7; border:1px solid #d2d6de; border-radius:4px;
                           padding:8px 14px; margin-bottom:10px; font-size:13px; color:#000;",
                 uiOutput("filtro_status_ui")))
    ),
    tabsetPanel(
      id = "abas",
      tabPanel("Lista geral de ramais",
        br(),
        fluidRow(
          box(width = 12, title = "Estatistica Descritiva (dados filtrados)",
              status = "primary", solidHeader = TRUE, collapsible = TRUE,
              tableOutput("tabela_estatisticas"))
        ),
        fluidRow(
          box(width = 12, title = "Cruzamento Origem x Setor",
              status = "primary", solidHeader = TRUE,
              DTOutput("tabela_geral"))
        )
      ),
      tabPanel("Graficos de barras",
        br(),
        fluidRow(
          box(width = 6, title = "Ocorrencias por Ramal (Top 20)",
              status = "info", solidHeader = TRUE,
              plotlyOutput("bar_ocorrencias", height = 420)),
          box(width = 6, title = "Valor Tarifado por Ramal (Top 20)",
              status = "info", solidHeader = TRUE,
              plotlyOutput("bar_valor", height = 420))
        )
      ),
      tabPanel("Graficos de pizza",
        br(),
        fluidRow(
          box(width = 6, title = "Participacao nas Ocorrencias (Top 20 Ramais)",
              status = "warning", solidHeader = TRUE,
              plotlyOutput("pie_ocorrencias", height = 420)),
          box(width = 6, title = "Participacao no Valor Tarifado (Top 20 Ramais)",
              status = "warning", solidHeader = TRUE,
              plotlyOutput("pie_valor", height = 420))
        )
      )
    )
  )
)

# ============================== SERVER ===========================
server <- function(input, output, session) {

  # Deixa todo grafico plotly interativo: zoom, pan, hover, barra de ferramentas
  # e botao de reset. Aplicado em TODOS os graficos do dashboard.
  interativo <- function(p) {
    p %>%
      layout(hovermode = "closest") %>%
      config(
        displayModeBar = TRUE,
        scrollZoom = TRUE,
        displaylogo = FALSE,
        modeBarButtonsToRemove = list("lasso2d", "select2d")
      )
  }

  # ---------- Leitura das planilhas ----------
  dados_somatorio_raw <- reactive({
    req(input$file_somatorio)
    df <- read_excel(input$file_somatorio$datapath)
    names(df) <- str_trim(names(df))
    df
  })

  dados_setores_raw <- reactive({
    req(input$file_setores)
    df <- read_excel(input$file_setores$datapath)
    names(df) <- str_trim(names(df))
    df
  })

  # ---------- Preparacao e cruzamento das planilhas ----------
  dados_base <- reactive({
    df <- dados_somatorio_raw()
    setores <- dados_setores_raw()

    validate(
      need(COL_ORIGEM %in% names(df),
           paste("A coluna", COL_ORIGEM, "nao foi encontrada em Somatorio2024.xlsx")),
      need(COL_ORIGEM %in% names(setores),
           paste("A coluna", COL_ORIGEM, "nao foi encontrada em Setores.xlsx")),
      need(COL_SETOR %in% names(setores),
           paste("A coluna", COL_SETOR, "nao foi encontrada em Setores.xlsx"))
    )

    df[[COL_ORIGEM]] <- as.character(df[[COL_ORIGEM]])
    setores[[COL_ORIGEM]] <- as.character(setores[[COL_ORIGEM]])

    # Deriva Mes e Dia da Semana a partir da coluna de data, se existir
    if (COL_DATA %in% names(df)) {
      df[[COL_DATA]] <- suppressWarnings(as.Date(df[[COL_DATA]]))
      df$Mes        <- factor(MESES_PT[month(df[[COL_DATA]])], levels = MESES_PT)
      df$Dia_Semana <- factor(DIAS_PT[wday(df[[COL_DATA]])], levels = DIAS_PT)
    } else {
      if (!"Mes" %in% names(df)) df$Mes <- NA
      if (!"Dia_Semana" %in% names(df)) {
        if ("Dia" %in% names(df)) df$Dia_Semana <- df$Dia else df$Dia_Semana <- NA
      }
    }

    if (!COL_QTD_OCORR %in% names(df)) df[[COL_QTD_OCORR]] <- NA
    if (!COL_VALOR_FATURA %in% names(df)) df[[COL_VALOR_FATURA]] <- NA

    merged <- left_join(df, setores[, c(COL_ORIGEM, COL_SETOR)], by = COL_ORIGEM)
    merged[[COL_SETOR]][is.na(merged[[COL_SETOR]])] <- "Setor nao identificado"
    merged
  })

  # ---------- Top 20 ramais por Qtd_Ocorrencias (referencia fixa) ----------
  top20_origem <- reactive({
    dados_base() %>%
      group_by(.data[[COL_ORIGEM]]) %>%
      summarise(total = sum(.data[[COL_QTD_OCORR]], na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>%
      slice_head(n = 20) %>%
      pull(.data[[COL_ORIGEM]])
  })

  # ---------- Filtros dinamicos no menu lateral ----------
  # ----- Ramal: agora exibido como LISTA CORRIDA (checkboxes com rolagem) -----
  # Inclui o Setor de cada ramal (vindo do cruzamento com Setores.xlsx) para
  # que o usuario ja veja, direto no filtro, a qual setor cada ramal pertence.
  top20_origem_com_total <- reactive({
    dados_base() %>%
      group_by(.data[[COL_ORIGEM]]) %>%
      summarise(total = sum(.data[[COL_QTD_OCORR]], na.rm = TRUE),
                setor = dplyr::first(.data[[COL_SETOR]]), .groups = "drop") %>%
      arrange(desc(total)) %>%
      slice_head(n = 20)
  })

  # Escolhas de cada filtro centralizadas em reactives, reaproveitadas pelos
  # botoes "Marcar todos" / "Desmarcar todos" e pelo botao "Limpar filtros".
  ramal_escolhas <- reactive({
    df <- top20_origem_com_total()
    setNames(
      df[[COL_ORIGEM]],
      paste0(df[[COL_ORIGEM]], " - ", df$setor, "  (", comma(df$total), " ocorr.)")
    )
  })


  output$ui_filtro_ramal <- renderUI({
    req(dados_base())
    escolhas <- ramal_escolhas()
    tagList(
      tags$label("Filtro de Ramais / Setor (Top 20 por Ocorrencias)"),
      div(style = "margin-bottom:6px;",
          actionButton("btn_ramal_marcar", "Marcar todos",
                       icon = icon("check-square"), class = "btn-xs btn-default",
                       style = "margin-right:4px;"),
          actionButton("btn_ramal_desmarcar", "Desmarcar todos",
                       icon = icon("square"), class = "btn-xs btn-default")
      ),
      div(class = "filtro-caixa",
          style = "height:230px; overflow-y:auto; border:1px solid #d2d6de;
                    border-radius:4px; padding:6px; margin-bottom:10px;",
          checkboxGroupInput("filtro_ramal", label = NULL,
                              choices = escolhas, selected = unname(escolhas),
                              width = "100%"))
    )
  })

  output$ui_filtro_valor <- renderUI({
    req(dados_base())
    v <- dados_base()[[COL_VALOR_FATURA]]
    v <- v[!is.na(v)]
    if (length(v) == 0) v <- c(0, 1)
    sliderInput("filtro_valor", "Filtro de Quantidade Tarifada (R$)",
                min = floor(min(v)), max = ceiling(max(v)),
                value = c(floor(min(v)), ceiling(max(v))), width = "90%")
  })

  # ---------- Botoes "Marcar todos" / "Desmarcar todos" de cada filtro ----------
  observeEvent(input$btn_ramal_marcar, {
    updateCheckboxGroupInput(session, "filtro_ramal", selected = unname(ramal_escolhas()))
  })
  observeEvent(input$btn_ramal_desmarcar, {
    updateCheckboxGroupInput(session, "filtro_ramal", selected = character(0))
  })

  # ---------- Botao "Limpar filtros": restaura tudo marcado + slider no maximo ----------
  observeEvent(input$btn_limpar, {
    updateCheckboxGroupInput(session, "filtro_ramal", selected = unname(ramal_escolhas()))

    v <- dados_base()[[COL_VALOR_FATURA]]; v <- v[!is.na(v)]
    if (length(v) > 0) {
      updateSliderInput(session, "filtro_valor", value = c(floor(min(v)), ceiling(max(v))))
    }
  })

  # ---------- Dados filtrados (alimentam as 3 abas) ----------
  # Os dois filtros (Ramal e Quantidade Tarifada) sao SEMPRE combinados
  # entre si por interseccao (E logico / AND): o resultado final so contem
  # registros que atendem a TODOS os filtros ao mesmo tempo. Dentro de cada
  # filtro, os valores marcados se combinam por OU logico (ex.: marcar os
  # ramais 1001 e 1002 traz os dois).
  dados_filtrados <- reactive({
    df <- dados_base()
    req(df)

    ramal_sel <- input$filtro_ramal
    if (is.null(ramal_sel)) ramal_sel <- character(0)

    # 1) Filtro por Ramal (Origem)
    df <- df %>% filter(.data[[COL_ORIGEM]] %in% ramal_sel)

    # 2) Filtro por Quantidade Tarifada (intervalo) - combinado (AND) com
    #    o filtro de Ramal. Registros sem valor tarifado sao excluidos
    #    quando este filtro esta ativo, para manter a interseccao coerente.
    if (!is.null(input$filtro_valor) && !all(is.na(df[[COL_VALOR_FATURA]]))) {
      df <- df %>% filter(
        !is.na(.data[[COL_VALOR_FATURA]]) &
        .data[[COL_VALOR_FATURA]] >= input$filtro_valor[1] &
        .data[[COL_VALOR_FATURA]] <= input$filtro_valor[2]
      )
    }

    df
  })

  # ---------- Barra de status: confirma visualmente que os filtros estao
  # sendo aplicados. Atualiza a cada clique em qualquer filtro. ----------
  output$filtro_status_ui <- renderUI({
    req(dados_base())
    n_ramal_sel <- length(input$filtro_ramal)
    n_ramal_tot <- length(ramal_escolhas())
    n_linhas    <- nrow(dados_filtrados())

    HTML(paste0(
      "<strong>Filtros ativos:</strong> ",
      "Ramais ", n_ramal_sel, " de ", n_ramal_tot, " &nbsp;|&nbsp; ",
      "Valor R$ ", format(input$filtro_valor[1], big.mark = "."), " a R$ ",
      format(input$filtro_valor[2], big.mark = "."), " &nbsp;|&nbsp; ",
      "<strong>", comma(n_linhas), " registro(s) encontrados</strong>"
    ))
  })

  # ---------- Cartoes de indicadores (topo) ----------
  output$vb_total_ramais <- renderValueBox({
    valueBox(length(unique(dados_filtrados()[[COL_ORIGEM]])), "Ramais no filtro",
             icon = icon("phone"), color = "blue")
  })
  output$vb_total_ocorrencias <- renderValueBox({
    valueBox(comma(sum(dados_filtrados()[[COL_QTD_OCORR]], na.rm = TRUE)),
             "Total de Ocorrencias", icon = icon("chart-bar"), color = "green")
  })
  output$vb_total_valor <- renderValueBox({
    valueBox(dollar(sum(dados_filtrados()[[COL_VALOR_FATURA]], na.rm = TRUE),
                    prefix = "R$ ", big.mark = ".", decimal.mark = ","),
             "Valor Tarifado Total", icon = icon("dollar-sign"), color = "yellow")
  })
  output$vb_media_valor <- renderValueBox({
    m <- mean(dados_filtrados()[[COL_VALOR_FATURA]], na.rm = TRUE)
    valueBox(dollar(ifelse(is.nan(m), 0, m), prefix = "R$ ", big.mark = ".", decimal.mark = ","),
             "Valor Medio por Registro", icon = icon("calculator"), color = "purple")
  })

  # ---------- Aba 1: Lista geral de ramais ----------
  output$tabela_geral <- renderDT({
    df <- dados_filtrados() %>%
      select(all_of(COL_ORIGEM), all_of(COL_SETOR)) %>%
      distinct() %>%
      arrange(.data[[COL_ORIGEM]])
    datatable(df, rownames = FALSE, filter = "top",
              options = list(pageLength = 15))
  })

  output$tabela_estatisticas <- renderTable({
    df <- dados_filtrados()
    data.frame(
      Indicador = c("N. de Ramais", "Total de Ocorrencias", "Media de Ocorrencias/Ramal",
                    "Desvio Padrao das Ocorrencias", "Valor Tarifado Total (R$)",
                    "Valor Tarifado Medio (R$)", "Mediana do Valor Tarifado (R$)"),
      Valor = c(
        length(unique(df[[COL_ORIGEM]])),
        round(sum(df[[COL_QTD_OCORR]], na.rm = TRUE), 0),
        round(mean(df[[COL_QTD_OCORR]], na.rm = TRUE), 2),
        round(sd(df[[COL_QTD_OCORR]], na.rm = TRUE), 2),
        round(sum(df[[COL_VALOR_FATURA]], na.rm = TRUE), 2),
        round(mean(df[[COL_VALOR_FATURA]], na.rm = TRUE), 2),
        round(median(df[[COL_VALOR_FATURA]], na.rm = TRUE), 2)
      )
    )
  })

  # ---------- Aba 2: Graficos de barras ----------
  output$bar_ocorrencias <- renderPlotly({
    df <- dados_filtrados() %>%
      group_by(.data[[COL_ORIGEM]]) %>%
      summarise(total = sum(.data[[COL_QTD_OCORR]], na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>% slice_head(n = 20)
    validate(need(nrow(df) > 0, "Sem dados para os filtros selecionados."))
    plot_ly(df, x = ~reorder(.data[[COL_ORIGEM]], -total), y = ~total, type = "bar",
            marker = list(color = "#3c8dbc"),
            hovertemplate = paste("Ramal: %{x}<br>Ocorrencias: %{y}<extra></extra>")) %>%
      layout(xaxis = list(title = "Ramal (Origem)"), yaxis = list(title = "Ocorrencias")) %>%
      interativo()
  })

  output$bar_valor <- renderPlotly({
    df <- dados_filtrados() %>%
      group_by(.data[[COL_ORIGEM]]) %>%
      summarise(total = sum(.data[[COL_VALOR_FATURA]], na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>% slice_head(n = 20)
    validate(need(nrow(df) > 0, "Sem dados para os filtros selecionados."))
    plot_ly(df, x = ~reorder(.data[[COL_ORIGEM]], -total), y = ~total, type = "bar",
            marker = list(color = "#dd4b39"),
            hovertemplate = paste("Ramal: %{x}<br>Valor: R$ %{y:,.2f}<extra></extra>")) %>%
      layout(xaxis = list(title = "Ramal (Origem)"), yaxis = list(title = "Valor Tarifado (R$)")) %>%
      interativo()
  })

  # ---------- Aba 3: Graficos de pizza ----------
  output$pie_ocorrencias <- renderPlotly({
    df <- dados_filtrados() %>%
      group_by(.data[[COL_ORIGEM]]) %>%
      summarise(total = sum(.data[[COL_QTD_OCORR]], na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>% slice_head(n = 20)
    validate(need(nrow(df) > 0, "Sem dados para os filtros selecionados."))
    plot_ly(df, labels = ~.data[[COL_ORIGEM]], values = ~total, type = "pie",
            textinfo = "label+percent",
            hovertemplate = paste("%{label}<br>Ocorrencias: %{value}<extra></extra>")) %>%
      layout(showlegend = TRUE) %>%
      interativo()
  })

  output$pie_valor <- renderPlotly({
    df <- dados_filtrados() %>%
      group_by(.data[[COL_ORIGEM]]) %>%
      summarise(total = sum(.data[[COL_VALOR_FATURA]], na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>% slice_head(n = 20)
    validate(need(nrow(df) > 0, "Sem dados para os filtros selecionados."))
    plot_ly(df, labels = ~.data[[COL_ORIGEM]], values = ~total, type = "pie",
            textinfo = "label+percent",
            hovertemplate = paste("%{label}<br>Valor: R$ %{value:,.2f}<extra></extra>")) %>%
      layout(showlegend = TRUE) %>%
      interativo()
  })

}

shinyApp(ui, server)

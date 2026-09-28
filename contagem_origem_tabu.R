# ============================================================
# Script: Contagem distinta de "Origem" usando lista Tabu
# Objetivo:
#   1) Ler a coluna "Origem" do arquivo Relatorio-jan-set-2024.xlsx
#   2) Usar uma "lista Tabu" para registrar valores já lidos e
#      evitar recontagem (cada valor novo é comparado com a lista
#      antes de ser processado)
#   3) Contar quantas vezes cada valor de Origem aparece e somar
#      a coluna "Valor fatura" para cada um deles
#   4) Ordenar o resultado numericamente do menor para o maior
#   5) Exportar o resultado para um novo arquivo .xlsx
# ============================================================

# ---- 1. Pacotes necessários ---------------------------------
# readxl  -> ler arquivos .xlsx
# writexl -> exportar data frames para .xlsx
pacotes <- c("readxl", "writexl")
for (p in pacotes) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}
library(readxl)
library(writexl)

# ---- 2. Caminhos de entrada e saída --------------------------
# Ajuste o caminho abaixo para o local onde o arquivo está salvo

setwd("d:\\Projetos_de_TI_2026\\5-Telefonia"); getwd()

#arquivo_entrada <- "Relatorio-jan-set-2024.xlsx"
#arquivo_entrada <- "Relatorio-jan-dez-2025.xlsx"
arquivo_entrada <- "Relatorio-jan-ago-2026.xlsx"

arquivo_saida   <- "Origem_Distintos_Somatorios.xlsx"

# ---- 3. Leitura da planilha -----------------------------------
dados <- read_excel(arquivo_entrada, sheet = "PROCAPE")

# Confere se as colunas esperadas existem
colunas_necessarias <- c("Origem", "Valor fatura")
if (!all(colunas_necessarias %in% names(dados))) {
  stop("O arquivo não contém as colunas esperadas: 'Origem' e 'Valor fatura'.")
}

origem <- dados$Origem
valor  <- dados$`Valor fatura`

# ---- 4. Estruturas de controle ---------------------------------
lista_tabu        <- c()   # valores de Origem já lidos (a "lista Tabu")
valores_distintos <- c()   # valores distintos encontrados, na ordem de leitura
contagens         <- c()   # quantidade de ocorrências de cada valor distinto
somatorios        <- c()   # soma de "Valor fatura" para cada valor distinto

# ---- 5. Varredura da coluna Origem -------------------------------
# Para cada valor lido:
#   - se NÃO estiver na lista Tabu -> é um valor novo: cadastra e inicia contagem
#   - se JÁ estiver na lista Tabu  -> valor repetido: apenas atualiza contagem/soma
#     (a checagem contra a lista Tabu é o que evita a recontagem)
for (i in seq_along(origem)) {

  valor_atual <- origem[i]

  if (!(valor_atual %in% lista_tabu)) {

    # Valor novo -> adiciona à lista Tabu e cria um novo registro
    lista_tabu        <- c(lista_tabu, valor_atual)
    valores_distintos <- c(valores_distintos, valor_atual)
    contagens         <- c(contagens, 1)
    somatorios        <- c(somatorios, valor[i])

  } else {

    # Valor já lido -> localiza a posição já registrada e atualiza
    posicao <- which(valores_distintos == valor_atual)
    contagens[posicao]  <- contagens[posicao] + 1
    somatorios[posicao] <- somatorios[posicao] + valor[i]
  }
}

# ---- 6. Montagem do resultado ------------------------------------
resultado <- data.frame(
  Origem                  = valores_distintos,
  Qtd_Ocorrencias         = contagens,
  Somatorio_Valor_Fatura  = somatorios
)

# ---- 7. Ordenação numérica crescente ------------------------------
resultado <- resultado[order(resultado$Origem), ]
rownames(resultado) <- NULL

# ---- 8. Conferência no console ------------------------------------
cat("Quantidade de valores distintos encontrados em 'Origem':",
    length(valores_distintos), "\n\n")
print(resultado)

# ---- 9. Exportação para .xlsx -------------------------------------
write_xlsx(resultado, arquivo_saida)
cat("\nArquivo exportado com sucesso em:", arquivo_saida, "\n")

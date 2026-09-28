# 📞 Dashboard de Telefonia e Telemática HU

Um sistema em **R** desenvolvido para processamento, consolidação e visualização interativa de dados de bilhetagem telefônica e telemática hospitalar. 

O projeto conta com uma etapa de ETL/pré-processamento de chamadas (usando o conceito de **Lista Tabu** para desduplicação e soma eficiente de ocorrências) e um **Dashboard interativo em R Shiny** para análise visual de consumo e custos por ramal e setor.

---

## 📌 Funcionalidades Principal

- **Pré-Processamento e Agregação de Dados (`contagem_origem_tabu.R`)**:
  - Leitura e varredura de relatórios de telefonia (`.xlsx`).
  - Utilização de algoritmo com **Lista Tabu** para registrar valores únicos de ramais de origem, evitando recontagens e calculando a quantidade total de ocorrências e soma dos valores faturados por ramal.
  - Exportação de dados consolidados ordenados para planilhas Excel.

- **Dashboard Interativo (`Dashboard de bilhetagem.R`)**:
  - **Cruzamento de Dados**: Associa os ramais faturados aos respectivos setores da instituição através da leitura do arquivo `Setores.xlsx`.
  - **Filtros Dinâmicos**: Seleção por Ramal/Setor (Top 20 com maior volume de chamadas) e por intervalo de valor tarifado ($R\$$.
  - **Indicadores Rápidos (KPIs)**: Exibição de total de ramais ativos no filtro, quantidade total de ocorrências, valor tarifado acumulado e valor médio por chamada/registro.
  - **Visões Interativas**:
    - 📊 **Lista Geral de Ramais**: Tabela interativa (DataTables) com pesquisa e estatística descritiva (média, desvio padrão, mediana).
    - 📈 **Gráficos de Barras**: Top 20 ramais por quantidade de ocorrências e por valor tarifado.
    - 🍕 **Gráficos de Pizza (Pie Charts)**: Distribuição percentual de uso e faturamento por ramal.

---

## 📁 Estrutura de Arquivos

```text
.
├── contagem_origem_tabu.R      # Script de pré-processamento/agrupamento dos dados faturados
├── Dashboard de bilhetagem.R   # Aplicação R Shiny com a interface e gráficos Plotly
└── README.md                   # Documentação do projeto
```

---

## 🛠️ Pré-requisitos e Instalação

Para executar este projeto, você precisará ter o [R](https://www.r-project.org/) e o [RStudio](https://posit.co/download/rstudio-desktop/) instalados no seu computador.

### Pacotes do R Necessários

Abra o RStudio e instale as dependências necessárias executando o comando abaixo:

```R
install.packages(c(
  "shiny",
  "shinydashboard",
  "plotly",
  "readxl",
  "writexl",
  "dplyr",
  "DT",
  "lubridate",
  "scales",
  "tidyr",
  "stringr"
))
```

---

## 📊 Formato dos Arquivos de Entrada

O sistema espera arquivos no formato Excel (`.xlsx`) com as seguintes colunas obrigatórias:

### 1. Relatório / Somatório de Fatura (`Somatorio2024.xlsx` ou gerado via script)
- `Origem`: Identificador/Número do ramal chamador.
- `Qtd_Ocorrencias`: Número de ligações realizadas pelo ramal.
- `Somatorio_Valor_Fatura`: Valor total tarifado (R$).
- `Data` *(opcional)*: Data do registro para derivação automática de mês e dia da semana.

### 2. Mapeamento de Setores (`Setores.xlsx`)
- `Origem`: Número do ramal chamador.
- `Setor`: Nome do setor/departamento vinculado ao ramal.

---

## 🚀 Como Executar

### Passagem 1: Processar o relatório bruto (Opcional)
Se você possui um relatório bruto de telefonia e deseja agregar os totais por ramal:
1. Abra o arquivo `contagem_origem_tabu.R`.
2. Ajuste o caminho de trabalho (`setwd`) e o nome do arquivo de entrada `.xlsx`.
3. Execute o script. Ele gerará o arquivo `Origem_Distintos_Somatorios.xlsx`.

### Passagem 2: Rodar o Dashboard Interativo
1. Abra o arquivo `Dashboard de bilhetagem.R` no RStudio.
2. Clique no botão **Run App** no canto superior direito do editor (ou digite `shiny::runApp()` no console).
3. No painel lateral do Dashboard:
   - Faça o upload do arquivo de dados faturados (`Somatorio2024.xlsx` ou `Origem_Distintos_Somatorios.xlsx`).
   - Faça o upload da planilha de mapeamento (`Setores.xlsx`).
4. Utilize os filtros laterais para navegar pelos gráficos e tabelas interativas.

---

## 🖥️ Tecnologia Utilizada

- **Linguagem**: R
- **Interface**: `shiny`, `shinydashboard`
- **Visualização de Dados**: `plotly`, `DT`

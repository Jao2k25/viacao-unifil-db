# Simulador de Banco de Dados para Viação UniFil

Este repositório contém o esquema de banco de dados e scripts de teste para um simulador de sistema de uma empresa de viação, desenvolvido como um projeto acadêmico na UniFil.

## Visão Geral

O projeto simula as operações essenciais de uma empresa de ônibus, incluindo o gerenciamento de frotas, rotas, agendamento de viagens, e o processo de compra e cancelamento de passagens. Ele foi projetado para demonstrar o uso de bancos de dados relacionais (MySQL) com foco em integridade de dados, otimização de consultas e automação de processos via procedimentos armazenados e triggers.

## Estrutura do Projeto

*   `modelo_fisico_viacao_unifil.sql`: Contém o script SQL para a criação do banco de dados, tabelas, definição de chaves primárias e estrangeiras, índices, views, procedimentos armazenados e triggers.
*   `queries_teste_viacao_unifil.sql`: Contém scripts SQL para inserção de dados de teste e exemplos de consultas para verificar as funcionalidades do sistema, incluindo a compra e cancelamento de passagens.

## Tecnologias Utilizadas

*   **Banco de Dados:** MySQL
*   **Linguagem:** SQL
*   **Ambiente de Desenvolvimento:** Visual Studio Code (VS Code)

## Como Configurar e Executar

Para configurar e executar este projeto em seu ambiente local, siga os passos abaixo:

### Pré-requisitos

Certifique-se de ter o MySQL Server instalado e configurado em sua máquina. Recomenda-se o uso do **Visual Studio Code** com extensões apropriadas para gerenciamento de bancos de dados (ex: "MySQL" ou "SQL Tools").

### Passos para Configuração

1.  **Clone o Repositório:**

    ```bash
    git clone https://github.com/seu-usuario/viacao-unifil-db.git
    cd viacao-unifil-db
    ```

2.  **Abra no Visual Studio Code:**

    Abra a pasta clonada (`viacao-unifil-db`) no VS Code.

3.  **Conecte-se ao MySQL via VS Code (ou cliente de sua preferência):**

    Utilize as extensões do VS Code para MySQL ou seu cliente MySQL preferido (MySQL Workbench, DBeaver, etc.) para se conectar ao seu servidor MySQL local.

4.  **Crie o Banco de Dados e as Tabelas:**

    Execute o script `modelo_fisico_viacao_unifil.sql` para criar o banco de dados `viacao_unifil` e todas as suas tabelas, procedimentos e triggers. No VS Code, você pode abrir o arquivo e executar as queries diretamente se tiver a extensão de banco de dados configurada.

    ```sql
    SOURCE /caminho/para/o/seu/repositorio/viacao-unifil-db/modelo_fisico_viacao_unifil.sql;
    ```

    *   **Nota:** Certifique-se de substituir `/caminho/para/o/seu/repositorio/` pelo caminho real onde você clonou o repositório.

5.  **Insira Dados de Teste e Execute Consultas:**

    Após a criação do esquema, execute o script `queries_teste_viacao_unifil.sql` para popular o banco de dados com dados de exemplo e testar as funcionalidades implementadas. Assim como o script anterior, você pode executá-lo diretamente pelo VS Code.

    ```sql
    SOURCE /caminho/para/o/seu/repositorio/viacao-unifil-db/queries_teste_viacao_unifil.sql;
    ```

## Funcionalidades Implementadas

*   **Gerenciamento de Entidades:** Tabelas para `onibus`, `assento`, `rota`, `viagem`, `cliente` e `passagem`.
*   **Procedimentos Armazenados:**
    *   `verificar_assentos_disponiveis(id_viagem)`: Retorna os assentos disponíveis para uma viagem específica.
    *   `comprar_passagem(id_viagem, id_assento, id_cliente, valor_pago)`: Simula a compra de uma passagem, gerando um código localizador único e verificando a disponibilidade do assento.
    *   `cancelar_passagem(id_passagem)`: Permite o cancelamento de uma passagem, atualizando seu status.
*   **Triggers:**
    *   `before_viagem_insert`: Impede a criação de viagens com ônibus em manutenção.
    *   `before_viagem_insert_check_disponibilidade`: Previne conflitos de horário, garantindo que um ônibus não seja alocado para duas viagens simultaneamente.
*   **Views:**
    *   `viagens_disponiveis`: Uma view para consulta rápida de viagens agendadas e a quantidade de assentos disponíveis.

## Contribuição

Sinta-se à vontade para explorar o código, sugerir melhorias ou reportar problemas. Contribuições são sempre bem-vindas!

## Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

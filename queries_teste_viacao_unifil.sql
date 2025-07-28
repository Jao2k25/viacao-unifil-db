-- Selecionar o banco de dados
USE viacao_unifil;

-- Inserir dados de teste nas tabelas

-- Inserir ônibus
INSERT INTO onibus (placa, modelo, capacidade, ano_fabricacao, em_manutencao) VALUES
('ABC-1234', 'Mercedes-Benz O-500', 42, 2020, FALSE),
('DEF-5678', 'Volvo B270F', 38, 2019, FALSE),
('GHI-9012', 'Marcopolo Paradiso', 46, 2021, FALSE),
('JKL-3456', 'Scania K360', 40, 2018, FALSE);

-- Inserir assentos para o ônibus 1
INSERT INTO assento (id_onibus, numero, tipo, posicao) VALUES
(1, 1, 'executivo', 'janela'),
(1, 2, 'executivo', 'corredor'),
(1, 3, 'executivo', 'janela'),
(1, 4, 'executivo', 'corredor'),
(1, 5, 'comum', 'janela'),
(1, 6, 'comum', 'corredor'),
(1, 7, 'comum', 'janela'),
(1, 8, 'comum', 'corredor'),
(1, 9, 'comum', 'janela'),
(1, 10, 'comum', 'corredor'),
(1, 11, 'comum', 'janela'),
(1, 12, 'comum', 'corredor');

-- Inserir assentos para o ônibus 2
INSERT INTO assento (id_onibus, numero, tipo, posicao) VALUES
(2, 1, 'executivo', 'janela'),
(2, 2, 'executivo', 'corredor'),
(2, 3, 'comum', 'janela'),
(2, 4, 'comum', 'corredor'),
(2, 5, 'comum', 'janela'),
(2, 6, 'comum', 'corredor'),
(2, 7, 'comum', 'janela'),
(2, 8, 'comum', 'corredor');

-- Inserir rotas
INSERT INTO rota (cidade_origem, cidade_destino, distancia_km, duracao_estimada) VALUES
('Londrina', 'Maringá', 115.0, '01:30:00'),
('Londrina', 'Curitiba', 380.0, '05:00:00'),
('Maringá', 'Cascavel', 290.0, '03:45:00'),
('Curitiba', 'Foz do Iguaçu', 650.0, '08:30:00');

-- Inserir viagens
INSERT INTO viagem (id_rota, id_onibus, data_partida, hora_partida, preco_base, status) VALUES
(1, 1, CURDATE(), '08:00:00', 45.90, 'agendada'),
(2, 2, CURDATE(), '09:30:00', 52.50, 'agendada'),
(3, 3, CURDATE(), '10:15:00', 38.75, 'agendada'),
(4, 4, CURDATE(), '14:00:00', 65.20, 'agendada');

-- Inserir clientes
INSERT INTO cliente (nome, cpf, data_nascimento, email, telefone, endereco) VALUES
('João Silva', '123.456.789-00', '1985-03-15', 'joao.silva@email.com', '(43)99999-1111', 'Rua das Flores, 123, Londrina'),
('Maria Oliveira', '987.654.321-00', '1990-07-22', 'maria.oliveira@email.com', '(43)99999-2222', 'Av. Paraná, 456, Londrina'),
('Pedro Santos', '456.789.123-00', '1992-11-01', 'pedro.santos@email.com', '(41)88888-3333', 'Rua das Palmeiras, 789, Curitiba'),
('Ana Pereira', '789.123.456-00', '1988-05-20', 'ana.pereira@email.com', '(44)77777-4444', 'Rua dos Coqueiros, 10, Maringá');

-- Testar o procedimento de verificação de assentos disponíveis
CALL verificar_assentos_disponiveis(1);

-- Testar a compra de passagens
-- Cliente 1 compra passagem na viagem 1, assento 1
-- Vamos obter o id_assento correto para o assento número 1 do ônibus 1
SELECT id_assento INTO @id_assento_onibus1_num1 FROM assento WHERE id_onibus = 1 AND numero = 1;
CALL comprar_passagem(1, @id_assento_onibus1_num1, 1, 45.90, @codigo1, @mensagem1);
SELECT @codigo1 AS codigo_localizador, @mensagem1 AS mensagem;

-- Cliente 2 compra passagem na viagem 1, assento 3
-- Vamos obter o id_assento correto para o assento número 3 do ônibus 1
SELECT id_assento INTO @id_assento_onibus1_num3 FROM assento WHERE id_onibus = 1 AND numero = 3;
CALL comprar_passagem(1, @id_assento_onibus1_num3, 2, 45.90, @codigo2, @mensagem2);
SELECT @codigo2 AS codigo_localizador, @mensagem2 AS mensagem;

-- Cliente 3 compra passagem na viagem 2, assento 1
-- Vamos obter o id_assento correto para o assento número 1 do ônibus 2
SELECT id_assento INTO @id_assento_onibus2_num1 FROM assento WHERE id_onibus = 2 AND numero = 1;
CALL comprar_passagem(2, @id_assento_onibus2_num1, 3, 52.50, @codigo3, @mensagem3);
SELECT @codigo3 AS codigo_localizador, @mensagem3 AS mensagem;

-- Verificar assentos disponíveis após as compras
CALL verificar_assentos_disponiveis(1);

-- Testar a tentativa de comprar um assento já ocupado (deve falhar)
-- Cliente 4 tenta comprar passagem na viagem 1, assento 1 (já ocupado pelo cliente 1)
-- Usando o id_assento correto para o assento 1 do ônibus 1
CALL comprar_passagem(1, @id_assento_onibus1_num1, 4, 45.90, @codigo4, @mensagem4);
SELECT @codigo4 AS codigo_localizador, @mensagem4 AS mensagem;

-- Testar o cancelamento de passagem
-- Cancelar a passagem do cliente 1 na viagem 1
SELECT id_passagem INTO @id_passagem_cancelar FROM passagem WHERE codigo_localizador = @codigo1;
CALL cancelar_passagem(@id_passagem_cancelar, @mensagem_cancelamento);
SELECT @mensagem_cancelamento AS mensagem;

-- Verificar assentos disponíveis após o cancelamento
CALL verificar_assentos_disponiveis(1);

-- Agora o cliente 4 deve conseguir comprar o assento 1 na viagem 1
-- Usando o id_assento correto para o assento 1 do ônibus 1
CALL comprar_passagem(1, @id_assento_onibus1_num1, 4, 45.90, @codigo5, @mensagem5);
SELECT @codigo5 AS codigo_localizador, @mensagem5 AS mensagem;

-- Consultar a view de viagens disponíveis
SELECT * FROM viagens_disponiveis;

-- Consultar todas as passagens vendidas
SELECT
    p.id_passagem,
    c.nome AS cliente,
    CONCAT(r.cidade_origem, ' → ', r.cidade_destino) AS rota,
    v.data_partida,
    v.hora_partida,
    CONCAT(a.numero, ' (', a.tipo, ', ', a.posicao, ')') AS assento,
    p.status,
    p.codigo_localizador
FROM
    passagem p
    JOIN cliente c ON p.id_cliente = c.id_cliente
    JOIN viagem v ON p.id_viagem = v.id_viagem
    JOIN assento a ON p.id_assento = a.id_assento
    JOIN rota r ON v.id_rota = r.id_rota
ORDER BY
    v.data_partida, v.hora_partida;

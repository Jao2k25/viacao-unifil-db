-- Criação do banco de dados para a Viação UniFil
DROP DATABASE IF EXISTS viacao_unifil;
CREATE DATABASE viacao_unifil;
USE viacao_unifil;

-- Tabela de Ônibus
CREATE TABLE onibus (
    id_onibus INT AUTO_INCREMENT PRIMARY KEY,
    placa VARCHAR(10) NOT NULL UNIQUE,
    modelo VARCHAR(50) NOT NULL,
    capacidade INT NOT NULL,
    ano_fabricacao INT NOT NULL,
    em_manutencao BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_capacidade CHECK (capacidade > 0),
    CONSTRAINT chk_ano_fabricacao CHECK (ano_fabricacao >= 2000)
) ENGINE=InnoDB;

-- Tabela de Assentos
CREATE TABLE assento (
    id_assento INT AUTO_INCREMENT PRIMARY KEY,
    id_onibus INT NOT NULL,
    numero INT NOT NULL,
    tipo ENUM('comum', 'preferencial', 'executivo') DEFAULT 'comum',
    posicao ENUM('corredor', 'janela') NOT NULL,
    CONSTRAINT fk_assento_onibus FOREIGN KEY (id_onibus) REFERENCES onibus(id_onibus) ON DELETE CASCADE,
    CONSTRAINT uq_assento_onibus UNIQUE (id_onibus, numero)
) ENGINE=InnoDB;

-- Tabela de Rotas
CREATE TABLE rota (
    id_rota INT AUTO_INCREMENT PRIMARY KEY,
    cidade_origem VARCHAR(50) NOT NULL,
    cidade_destino VARCHAR(50) NOT NULL,
    distancia_km DECIMAL(6,2) NOT NULL,
    duracao_estimada TIME NOT NULL,
    CONSTRAINT chk_distancia CHECK (distancia_km > 0),
    CONSTRAINT chk_cidades CHECK (cidade_origem <> cidade_destino)
) ENGINE=InnoDB;

-- Tabela de Viagens
CREATE TABLE viagem (
    id_viagem INT AUTO_INCREMENT PRIMARY KEY,
    id_rota INT NOT NULL,
    id_onibus INT NOT NULL,
    data_partida DATE NOT NULL,
    hora_partida TIME NOT NULL,
    preco_base DECIMAL(8,2) NOT NULL,
    status ENUM('agendada', 'em_andamento', 'concluida', 'cancelada') DEFAULT 'agendada',
    CONSTRAINT fk_viagem_rota FOREIGN KEY (id_rota) REFERENCES rota(id_rota),
    CONSTRAINT fk_viagem_onibus FOREIGN KEY (id_onibus) REFERENCES onibus(id_onibus),
    CONSTRAINT chk_preco CHECK (preco_base > 0)
) ENGINE=InnoDB;

-- Tabela de Clientes
CREATE TABLE cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    email VARCHAR(100) UNIQUE,
    telefone VARCHAR(20) NOT NULL,
    endereco VARCHAR(200) NOT NULL,
    CONSTRAINT chk_cpf CHECK (LENGTH(cpf) = 14)
) ENGINE=InnoDB;

-- Tabela de Passagens (CORRIGIDA: REMOVIDA A RESTRIÇÃO UNIQUE uq_viagem_assento)
CREATE TABLE passagem (
    id_passagem INT AUTO_INCREMENT PRIMARY KEY,
    id_viagem INT NOT NULL,
    id_assento INT NOT NULL,
    id_cliente INT NOT NULL,
    data_compra DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_pago DECIMAL(8,2) NOT NULL,
    status ENUM('reservada', 'paga', 'cancelada', 'utilizada') DEFAULT 'reservada',
    codigo_localizador VARCHAR(10) NOT NULL UNIQUE,
    CONSTRAINT fk_passagem_viagem FOREIGN KEY (id_viagem) REFERENCES viagem(id_viagem),
    CONSTRAINT fk_passagem_assento FOREIGN KEY (id_assento) REFERENCES assento(id_assento),
    CONSTRAINT fk_passagem_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    -- CONSTRAINT uq_viagem_assento UNIQUE (id_viagem, id_assento), -- ESTA LINHA FOI REMOVIDA
    CONSTRAINT chk_valor CHECK (valor_pago > 0)
) ENGINE=InnoDB;

-- Implementação das restrições de integridade

-- Índices para otimização de consultas:
CREATE INDEX idx_viagem_data ON viagem(data_partida, hora_partida);
CREATE INDEX idx_passagem_status ON passagem(status);
CREATE INDEX idx_cliente_nome ON cliente(nome);
CREATE INDEX idx_onibus_manutencao ON onibus(em_manutencao);

-- Procedimento para verificar disponibilidade de assentos:
DELIMITER //
DROP PROCEDURE IF EXISTS verificar_assentos_disponiveis;
CREATE PROCEDURE verificar_assentos_disponiveis(IN p_id_viagem INT)
BEGIN
    SELECT a.id_assento, a.numero, a.tipo, a.posicao
    FROM assento a
    JOIN onibus o ON a.id_onibus = o.id_onibus
    JOIN viagem v ON v.id_onibus = o.id_onibus
    WHERE v.id_viagem = p_id_viagem
    AND a.id_assento NOT IN (
        SELECT p.id_assento
        FROM passagem p
        WHERE p.id_viagem = p_id_viagem
        AND p.status IN ('reservada', 'paga')
    )
    ORDER BY a.numero;
END //
DELIMITER ;

-- Procedimento para comprar passagem:
DELIMITER //
DROP PROCEDURE IF EXISTS comprar_passagem;
CREATE PROCEDURE comprar_passagem(
    IN p_id_viagem INT,
    IN p_id_assento INT,
    IN p_id_cliente INT,
    IN p_valor_pago DECIMAL(8,2),
    OUT p_codigo_localizador VARCHAR(10),
    OUT p_mensagem VARCHAR(100)
)
BEGIN
    DECLARE assento_disponivel INT DEFAULT 0;
    DECLARE onibus_viagem INT;
    DECLARE assento_onibus INT;

    -- Iniciar transação
    START TRANSACTION;

    -- Verificar se o assento pertence ao ônibus da viagem
    SELECT v.id_onibus INTO onibus_viagem
    FROM viagem v
    WHERE v.id_viagem = p_id_viagem;

    SELECT a.id_onibus INTO assento_onibus
    FROM assento a
    WHERE a.id_assento = p_id_assento;

    IF onibus_viagem <> assento_onibus THEN
        SET p_mensagem = 'Erro: O assento não pertence ao ônibus desta viagem';
        ROLLBACK;
    ELSE
        -- Verificar se o assento está disponível
        SELECT COUNT(*) INTO assento_disponivel
        FROM passagem p
        WHERE p.id_viagem = p_id_viagem
        AND p.id_assento = p_id_assento
        AND p.status IN ('reservada', 'paga');

        IF assento_disponivel > 0 THEN
            SET p_mensagem = 'Erro: Assento já está ocupado';
            ROLLBACK;
        ELSE
            -- Gerar código localizador (combinação de letras e números)
            SET p_codigo_localizador = CONCAT(
                CHAR(65 + FLOOR(RAND() * 26)),
                CHAR(65 + FLOOR(RAND() * 26)),
                FLOOR(RAND() * 10),
                FLOOR(RAND() * 10),
                CHAR(65 + FLOOR(RAND() * 26)),
                FLOOR(RAND() * 10),
                FLOOR(RAND() * 10),
                CHAR(65 + FLOOR(RAND() * 26)),
                FLOOR(RAND() * 10),
                CHAR(65 + FLOOR(RAND() * 26))
            );

            -- Inserir a passagem
            INSERT INTO passagem (id_viagem, id_assento, id_cliente, valor_pago, status, codigo_localizador)
            VALUES (p_id_viagem, p_id_assento, p_id_cliente, p_valor_pago, 'paga', p_codigo_localizador);

            SET p_mensagem = 'Passagem comprada com sucesso';
            COMMIT;
        END IF;
    END IF;
END //
DELIMITER ;

-- Procedimento para cancelar passagem:
DELIMITER //
DROP PROCEDURE IF EXISTS cancelar_passagem;
CREATE PROCEDURE cancelar_passagem(
    IN p_id_passagem INT,
    OUT p_mensagem VARCHAR(100)
)
BEGIN
    DECLARE status_atual VARCHAR(20);

    -- Iniciar transação
    START TRANSACTION;

    -- Verificar status atual da passagem
    SELECT status INTO status_atual
    FROM passagem
    WHERE id_passagem = p_id_passagem;

    IF status_atual IS NULL THEN
        SET p_mensagem = 'Erro: Passagem não encontrada';
        ROLLBACK;
    ELSEIF status_atual = 'cancelada' THEN
        SET p_mensagem = 'Erro: Passagem já está cancelada';
        ROLLBACK;
    ELSEIF status_atual = 'utilizada' THEN
        SET p_mensagem = 'Erro: Não é possível cancelar uma passagem já utilizada';
        ROLLBACK;
    ELSE
        -- Atualizar status para cancelada
        UPDATE passagem
        SET status = 'cancelada'
        WHERE id_passagem = p_id_passagem;

        SET p_mensagem = 'Passagem cancelada com sucesso';
        COMMIT;
    END IF;
END //
DELIMITER ;

-- Trigger para verificar se o ônibus não está em manutenção antes de criar uma viagem
DELIMITER //
DROP TRIGGER IF EXISTS before_viagem_insert;
CREATE TRIGGER before_viagem_insert
BEFORE INSERT ON viagem
FOR EACH ROW
BEGIN
    DECLARE onibus_manutencao BOOLEAN;

    SELECT em_manutencao INTO onibus_manutencao
    FROM onibus
    WHERE id_onibus = NEW.id_onibus;

    IF onibus_manutencao = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Não é possível criar viagem com ônibus em manutenção';
    END IF;
END //
DELIMITER ;

-- Trigger para verificar se o ônibus não está já alocado para outra viagem no mesmo horário (CORRIGIDO)
DELIMITER //
DROP TRIGGER IF EXISTS before_viagem_insert_check_disponibilidade;
CREATE TRIGGER before_viagem_insert_check_disponibilidade
BEFORE INSERT ON viagem
FOR EACH ROW
BEGIN
    DECLARE conflito INT;
    DECLARE rota_duracao_estimada TIME; -- Variável para armazenar a duração da rota

    -- Obter a duração estimada da rota associada à nova viagem
    SELECT duracao_estimada INTO rota_duracao_estimada
    FROM rota
    WHERE id_rota = NEW.id_rota;

    SELECT COUNT(*) INTO conflito
    FROM viagem
    WHERE id_onibus = NEW.id_onibus
    AND data_partida = NEW.data_partida
    AND (
        (NEW.hora_partida BETWEEN hora_partida AND ADDTIME(hora_partida, rota_duracao_estimada))
        OR
        (hora_partida BETWEEN NEW.hora_partida AND ADDTIME(NEW.hora_partida, rota_duracao_estimada))
    );

    IF conflito > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conflito de horário: ônibus já alocado para outra viagem neste período';
    END IF;
END //
DELIMITER ;

-- View para consulta rápida de viagens disponíveis:
CREATE VIEW viagens_disponiveis AS
SELECT
    v.id_viagem,
    r.cidade_origem,
    r.cidade_destino,
    v.data_partida,
    v.hora_partida,
    v.preco_base,
    o.modelo AS modelo_onibus,
    o.capacidade,
    (
        SELECT COUNT(*)
        FROM passagem p
        WHERE p.id_viagem = v.id_viagem
        AND p.status IN ('reservada', 'paga')
    ) AS assentos_ocupados,
    (
        o.capacidade - (
            SELECT COUNT(*)
            FROM passagem p
            WHERE p.id_viagem = v.id_viagem
            AND p.status IN ('reservada', 'paga')
        )
    ) AS assentos_disponiveis
FROM viagem v
JOIN rota r ON v.id_rota = r.id_rota
JOIN onibus o ON v.id_onibus = o.id_onibus
WHERE v.status = 'agendada'
AND v.data_partida >= CURDATE()
ORDER BY v.data_partida, v.hora_partida;

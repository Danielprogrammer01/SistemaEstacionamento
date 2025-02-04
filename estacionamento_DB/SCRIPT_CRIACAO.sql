CREATE SCHEMA IF NOT EXISTS `wallpark_db`;
USE wallpark_db;

CREATE TABLE cliente(

idCliente INT PRIMARY KEY AUTO_INCREMENT,
nomeCliente VARCHAR(20) NOT NULL,
cpf VARCHAR(14) NOT NULL,
dtNascimento DATE

);

CREATE TABLE login(

idLogin INT PRIMARY KEY AUTO_INCREMENT,
usuario VARCHAR(100) NOT NULL,
senha VARCHAR(255) NOT NULL,
cliente_idCliente INT NOT NULL,
FOREIGN KEY (cliente_idCliente)
REFERENCES cliente(idCliente)
	ON UPDATE CASCADE
    ON DELETE CASCADE 


);

CREATE TABLE veiculo(

placa VARCHAR(10) PRIMARY KEY,
modelo VARCHAR(100) NOT NULL,
cor VARCHAR(14) NOT NULL,
ano YEAR NOT NULL,
porteVeiculo ENUM('Pequeno', 'Médio', 'Grande') NOT NULL,
tipoVeiculo ENUM('Moto', 'Carro') NOT NULL,
cliente_idCliente INT NOT NULL,
	FOREIGN KEY (cliente_idCliente)
    REFERENCES cliente(idCliente)
    ON UPDATE CASCADE
    ON DELETE CASCADE

);

CREATE TABLE vaga (

idVaga INT PRIMARY KEY AUTO_INCREMENT,
numeroVaga INT NOT NULL,
statusVaga ENUM('Livre', 'Ocupada', 'Reservada') NOT NULL DEFAULT 'Livre',
tipoVaga ENUM('Moto', 'Carro') NOT NULL
 
);

CREATE TABLE registroDeEstacionamento (
    idRegistro INT PRIMARY KEY AUTO_INCREMENT,
    dataEntrada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dataSaida DATETIME NULL,
	duracaoHoras DECIMAL(5,2) NULL, -- Armazena a duração calculada
    valor DECIMAL(10,2) NULL, -- Armazena o valor calculado
    formaPagamento ENUM('À Vista', 'Cartão de Débito', 'Cartão de Crédito', 'Mensal') NOT NULL,
    veiculo_placa VARCHAR(10) NOT NULL,
    cliente_idCliente INT NOT NULL,
    vaga_idVaga INT NOT NULL,
    FOREIGN KEY (veiculo_placa) REFERENCES veiculo(placa),
    FOREIGN KEY (cliente_idCliente) REFERENCES cliente(idCliente),
    FOREIGN KEY (vaga_idVaga) REFERENCES vaga(idVaga),
    
      -- Chave composta para validar registros únicos de estacionamento
    CONSTRAINT fk_registro_completo UNIQUE (veiculo_placa, vaga_idVaga, dataEntrada)
);

DELIMITER $$

CREATE TRIGGER calcular_duracao_valor 
AFTER UPDATE ON registroDeEstacionamento
FOR EACH ROW
BEGIN
    DECLARE tempo DECIMAL(5,2); -- Variável renomeada de 'duracao' para 'tempo'
    DECLARE valor DECIMAL(10,2);

    -- Calcular o tempo em horas (segundos convertidos para horas)
    SET tempo = TIMESTAMPDIFF(SECOND, OLD.dataEntrada, COALESCE(NEW.dataSaida, NOW())) / 3600.0;

    -- Calcular o valor com base no tempo e tipo de veículo
    SET valor = CASE
        WHEN tempo * 60 <= 30 THEN 0 -- Isento até 30 minutos
        WHEN tempo <= 4 AND (SELECT tipoVeiculo FROM veiculo WHERE placa = NEW.veiculo_placa) = 'Carro' THEN 13.00 -- Carro até 4h
        WHEN tempo <= 1 AND (SELECT tipoVeiculo FROM veiculo WHERE placa = NEW.veiculo_placa) = 'Moto' THEN 6.00 -- Moto até 1h
        ELSE (
            (CASE
                WHEN (SELECT tipoVeiculo FROM veiculo WHERE placa = NEW.veiculo_placa) = 'Carro' THEN 13.00
                ELSE 6.00
            END)
            + CEIL(tempo - (CASE
                WHEN (SELECT tipoVeiculo FROM veiculo WHERE placa = NEW.veiculo_placa) = 'Carro' THEN 4
                ELSE 1
            END)) * 1.00
        ) -- R$1 por hora ou fração adicional
    END;

    -- Atualizar o tempo e o valor calculado na tabela
    UPDATE registroDeEstacionamento
    SET duracaoHoras = tempo, valor = valor
    WHERE idRegistro = OLD.idRegistro;
END $$

DELIMITER ;





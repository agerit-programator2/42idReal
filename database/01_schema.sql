-- =====================================================================
-- 42idReal - MariaDB schema
-- Demo databáze pro Delphi sample aplikaci na testování scriptingu
-- =====================================================================

CREATE DATABASE IF NOT EXISTS idreal_demo
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_czech_ci;

USE idreal_demo;

-- ---------------------------------------------------------------------
-- Tabulka zákazníků - demo entita, na které se testují scripty
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    code             VARCHAR(20)   NOT NULL,
    name             VARCHAR(100)  NOT NULL,
    email            VARCHAR(100)  NULL,
    phone            VARCHAR(30)   NULL,
    credit_limit     DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(5,2)  NOT NULL DEFAULT 0,
    total_orders     INT           NOT NULL DEFAULT 0,
    is_vip           TINYINT(1)    NOT NULL DEFAULT 0,
    notes            TEXT          NULL,
    created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_customers_code (code)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabulka scriptů - definice uživatelských scriptů pro eventy formulářů
-- ---------------------------------------------------------------------
-- form_name  : identifikátor formuláře (např. 'CustomerEdit')
-- event_name : typ eventu:
--               OnFieldChange  - po změně hodnoty pole (field_name = pole)
--               OnBeforeSave   - před uložením záznamu (může save zrušit)
--               OnValidate     - validace jednoho pole (field_name = pole)
--               OnAfterLoad    - po načtení záznamu do formuláře
-- field_name : pro OnFieldChange / OnValidate - název pole, jinak NULL
-- script_code: vlastní tělo Pascal Scriptu
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS scripts;
CREATE TABLE scripts (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    form_name    VARCHAR(60)  NOT NULL,
    event_name   VARCHAR(30)  NOT NULL,
    field_name   VARCHAR(60)  NULL,
    description  VARCHAR(200) NULL,
    script_code  MEDIUMTEXT   NOT NULL,
    enabled      TINYINT(1)   NOT NULL DEFAULT 1,
    exec_order   INT          NOT NULL DEFAULT 100,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_scripts_lookup (form_name, event_name, field_name, enabled)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Log běhu scriptů - pomáhá při ladění
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS script_log;
CREATE TABLE script_log (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    script_id  INT          NULL,
    form_name  VARCHAR(60)  NOT NULL,
    event_name VARCHAR(30)  NOT NULL,
    field_name VARCHAR(60)  NULL,
    success    TINYINT(1)   NOT NULL,
    message    TEXT         NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_script_log_created (created_at)
) ENGINE=InnoDB;

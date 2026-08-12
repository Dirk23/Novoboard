/*!40101 SET @OLD_CHARACTER_SET_CLIENT = @@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS = @@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION = @@COLLATION_CONNECTION */;
SET NAMES utf8mb4;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS = 0 */;
/*!40101 SET @OLD_SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO', SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES = @@SQL_NOTES, SQL_NOTES = 0 */;


# Tabellen-Dump app_users
# ------------------------------------------------------------

DROP TABLE IF EXISTS `app_users`;

CREATE TABLE `app_users` (
                             `id`              BIGINT NOT NULL AUTO_INCREMENT,
                             `tenant_id`       BIGINT DEFAULT NULL,
                             `username`        VARCHAR(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
                             `display_name`    VARCHAR(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
                             `email`           VARCHAR(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'NULL = keine E-Mailadresse hinterlegt',
                             `role`            VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
                             `password_hash`   VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
                             `must_change_pw`  TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = Benutzer muss beim nächsten Login Passwort ändern',
                             `auth_source`     VARCHAR(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'local' COMMENT 'local, ldap oder anderer Provider',
                             `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             `updated_at`      DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                             PRIMARY KEY (`id`),
                             UNIQUE KEY `username_unique` (`username`),
                             UNIQUE KEY `email_unique` (`email`),
                             KEY `tenant_id` (`tenant_id`),
                             CONSTRAINT `app_users_ibfk_1`
                                 FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
                             CONSTRAINT `chk_tenant_null` CHECK (
                                     (`tenant_id` IS NULL AND `role` = 'superadmin')
                                     OR (`tenant_id` IS NOT NULL)
                                 )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


# Tabellen-Dump audit_log
# ------------------------------------------------------------

DROP TABLE IF EXISTS `audit_log`;

CREATE TABLE `audit_log`
(
    `id`           bigint                                  NOT NULL AUTO_INCREMENT,
    `tenant_id`    bigint                                  NOT NULL,
    `actor_id`     bigint                                           DEFAULT NULL,
    `event_time`   datetime                                NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `entity_type`  varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `entity_id`    bigint                                  NOT NULL,
    `action`       varchar(50) COLLATE utf8mb4_unicode_ci  NOT NULL,
    `details_json` json                                    NOT NULL DEFAULT (json_object()),
    PRIMARY KEY (`id`),
    KEY `tenant_id` (`tenant_id`, `event_time`),
    KEY `entity_type` (`entity_type`, `entity_id`),
    CONSTRAINT `audit_log_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump bundle_templates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `bundle_templates`;

CREATE TABLE `bundle_templates`
(
    `id`          bigint NOT NULL AUTO_INCREMENT,
    `bundle_id`   bigint NOT NULL,
    `template_id` bigint NOT NULL,
    `order_index` int    NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY `bundle_id` (`bundle_id`, `template_id`),
    KEY `template_id` (`template_id`),
    KEY `bundle_id_2` (`bundle_id`, `order_index`),
    CONSTRAINT `bundle_templates_ibfk_1` FOREIGN KEY (`bundle_id`) REFERENCES `checklist_bundles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `bundle_templates_ibfk_2` FOREIGN KEY (`template_id`) REFERENCES `checklist_templates` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump checklist_bundles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `checklist_bundles`;

CREATE TABLE `checklist_bundles`
(
    `id`              bigint                                              NOT NULL AUTO_INCREMENT,
    `tenant_id`       bigint                                              NOT NULL,
    `key_name`        varchar(100) COLLATE utf8mb4_unicode_ci             NOT NULL,
    `title`           varchar(200) COLLATE utf8mb4_unicode_ci             NOT NULL,
    `description`     text COLLATE utf8mb4_unicode_ci,
    `color_hex`       char(7) COLLATE utf8mb4_unicode_ci                  NOT NULL DEFAULT '#6c757d',
    `is_active`       tinyint(1)                                          NOT NULL DEFAULT '1',
    `conditions_json` json                                                NOT NULL DEFAULT (json_object()),
    `kind`            enum ('on','off','both') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'on',
    PRIMARY KEY (`id`),
    UNIQUE KEY `tenant_id` (`tenant_id`, `key_name`),
    CONSTRAINT `checklist_bundles_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump checklist_items
# ------------------------------------------------------------

DROP TABLE IF EXISTS `checklist_items`;

CREATE TABLE `checklist_items`
(
    `id`          bigint                                                       NOT NULL AUTO_INCREMENT,
    `template_id` bigint                                                       NOT NULL,
    `parent_id`   bigint                                                                DEFAULT NULL,
    `title`       varchar(200) COLLATE utf8mb4_unicode_ci                      NOT NULL,
    `description` text COLLATE utf8mb4_unicode_ci,
    `kind`        enum ('todo','verify','document') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'todo',
    `is_required` tinyint(1)                                                   NOT NULL DEFAULT '1',
    `order_index` int                                                          NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    KEY `template_id` (`template_id`),
    KEY `parent_id` (`parent_id`),
    CONSTRAINT `checklist_items_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `checklist_templates` (`id`),
    CONSTRAINT `checklist_items_ibfk_2` FOREIGN KEY (`parent_id`) REFERENCES `checklist_items` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump checklist_templates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `checklist_templates`;

CREATE TABLE `checklist_templates`
(
    `id`          bigint                                                              NOT NULL AUTO_INCREMENT,
    `tenant_id`   bigint                                                              NOT NULL,
    `key_name`    varchar(100) COLLATE utf8mb4_unicode_ci                             NOT NULL,
    `title`       varchar(200) COLLATE utf8mb4_unicode_ci                             NOT NULL,
    `description` text COLLATE utf8mb4_unicode_ci,
    `is_active`   tinyint(1)                                                          NOT NULL DEFAULT '1',
    `color_hex`   char(7) COLLATE utf8mb4_unicode_ci                                  NOT NULL DEFAULT '#0d6efd',
    `flow`        enum ('onboarding','offboarding','both') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'both',
    PRIMARY KEY (`id`),
    UNIQUE KEY `tenant_id` (`tenant_id`, `key_name`),
    CONSTRAINT `checklist_templates_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump custom_fields
# ------------------------------------------------------------

DROP TABLE IF EXISTS `custom_fields`;

CREATE TABLE `custom_fields`
(
    `id`          bigint                                                                             NOT NULL AUTO_INCREMENT,
    `tenant_id`   bigint                                                                             NOT NULL,
    `context`     enum ('employee','process','system_account','task') COLLATE utf8mb4_unicode_ci     NOT NULL,
    `field_key`   varchar(100) COLLATE utf8mb4_unicode_ci                                            NOT NULL,
    `label`       varchar(150) COLLATE utf8mb4_unicode_ci                                            NOT NULL,
    `data_type`   enum ('text','number','date','boolean','select','json') COLLATE utf8mb4_unicode_ci NOT NULL,
    `config_json` json                                                                               NOT NULL DEFAULT (json_object()),
    PRIMARY KEY (`id`),
    UNIQUE KEY `tenant_id` (`tenant_id`, `context`, `field_key`),
    CONSTRAINT `custom_fields_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump custom_values
# ------------------------------------------------------------

DROP TABLE IF EXISTS `custom_values`;

CREATE TABLE `custom_values`
(
    `id`          bigint                                                                         NOT NULL AUTO_INCREMENT,
    `field_id`    bigint                                                                         NOT NULL,
    `entity_type` enum ('employee','process','system_account','task') COLLATE utf8mb4_unicode_ci NOT NULL,
    `entity_id`   bigint                                                                         NOT NULL,
    `value_text`  text COLLATE utf8mb4_unicode_ci,
    `value_json`  json DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `field_id` (`field_id`),
    KEY `entity_type` (`entity_type`, `entity_id`),
    CONSTRAINT `custom_values_ibfk_1` FOREIGN KEY (`field_id`) REFERENCES `custom_fields` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump documents
# ------------------------------------------------------------

DROP TABLE IF EXISTS `documents`;

CREATE TABLE `documents`
(
    `id`         bigint                                                                         NOT NULL AUTO_INCREMENT,
    `process_id` bigint                                                                         NOT NULL,
    `kind`       enum ('welcome_sheet','offboarding_report','other') COLLATE utf8mb4_unicode_ci NOT NULL,
    `file_path`  varchar(500) COLLATE utf8mb4_unicode_ci                                        NOT NULL,
    `created_at` datetime                                                                       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_by` bigint                                                                         NOT NULL,
    PRIMARY KEY (`id`),
    KEY `process_id` (`process_id`),
    KEY `created_by` (`created_by`),
    CONSTRAINT `documents_ibfk_1` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`),
    CONSTRAINT `documents_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `app_users` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump email_queue
# ------------------------------------------------------------

DROP TABLE IF EXISTS `email_queue`;

CREATE TABLE `email_queue`
(
    `id`         bigint                                                     NOT NULL AUTO_INCREMENT,
    `tenant_id`  bigint                                                     NOT NULL,
    `to_email`   varchar(320) COLLATE utf8mb4_unicode_ci                    NOT NULL,
    `to_name`    varchar(200) COLLATE utf8mb4_unicode_ci                             DEFAULT NULL,
    `subject`    varchar(300) COLLATE utf8mb4_unicode_ci                    NOT NULL,
    `body_html`  mediumtext COLLATE utf8mb4_unicode_ci                      NOT NULL,
    `body_text`  mediumtext COLLATE utf8mb4_unicode_ci,
    `created_at` datetime                                                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `send_after` datetime                                                            DEFAULT NULL,
    `status`     enum ('queued','sent','failed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'queued',
    `attempts`   tinyint                                                    NOT NULL DEFAULT '0',
    `last_error` text COLLATE utf8mb4_unicode_ci,
    `sent_at`    datetime                                                            DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `tenant_id` (`tenant_id`, `status`, `created_at`),
    KEY `idx_email_queue_dispatch` (`status`, `send_after`, `tenant_id`, `created_at`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump employees
# ------------------------------------------------------------

DROP TABLE IF EXISTS `employees`;

CREATE TABLE `employees`
(
    `id`                   bigint NOT NULL AUTO_INCREMENT,
    `tenant_id`            bigint NOT NULL,
    `personal_nr`          varchar(50) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `vorname`              varchar(100) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    `nachname`             varchar(100) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    `team`                 varchar(150) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    `zimmer_nr`            varchar(50) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `rufnummer`            varchar(50) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `kuerzel`              varchar(20) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `berufsgruppe`         varchar(150) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    `berufsgruppe_term_id` bigint                                                   DEFAULT NULL,
    `externe_id`           varchar(100) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    `lanr`                 varchar(20) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `token_uid`            varchar(100) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    `sollzahl_patienten`   int                                                      DEFAULT NULL,
    `eintritt`             date                                                     DEFAULT NULL,
    `austritt`             date                                                     DEFAULT NULL,
    `kontakt_json`         json   NOT NULL                                          DEFAULT (json_object()),
    `anrede`               enum ('Herr','Frau','Divers') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `titel`                varchar(100) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    `facharzttitel`        text COLLATE utf8mb4_unicode_ci                           DEFAULT NULL,
    `geschlecht`           enum ('m','w','d') COLLATE utf8mb4_unicode_ci            DEFAULT NULL,
    `pate`                 varchar(200) COLLATE utf8mb4_unicode_ci                  DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `tenant_id` (`tenant_id`, `personal_nr`),
    KEY `employees_bgterm_fk` (`berufsgruppe_term_id`),
    CONSTRAINT `employees_bgterm_fk` FOREIGN KEY (`berufsgruppe_term_id`) REFERENCES `tenant_tax_terms` (`id`),
    CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump offboarding_suggestions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `offboarding_suggestions`;

CREATE TABLE `offboarding_suggestions`
(
    `id`            bigint                                                        NOT NULL AUTO_INCREMENT,
    `tenant_id`     bigint                                                        NOT NULL,
    `sam`           varchar(150) COLLATE utf8mb4_unicode_ci                       NOT NULL,
    `display_name`  varchar(200) COLLATE utf8mb4_unicode_ci                                DEFAULT NULL,
    `upn`           varchar(200) COLLATE utf8mb4_unicode_ci                                DEFAULT NULL,
    `mail`          varchar(200) COLLATE utf8mb4_unicode_ci                                DEFAULT NULL,
    `ad_dn`         varchar(500) COLLATE utf8mb4_unicode_ci                                DEFAULT NULL,
    `expires_at`    datetime                                                      NOT NULL,
    `discovered_at` datetime                                                      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `source_json`   json                                                          NOT NULL DEFAULT (json_object()),
    `status`        enum ('new','created','dismissed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'new',
    `process_id`    bigint                                                                 DEFAULT NULL,
    `actor_id`      bigint                                                                 DEFAULT NULL,
    `acted_at`      datetime                                                               DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_sam` (`tenant_id`, `sam`),
    KEY `process_id` (`process_id`),
    KEY `actor_id` (`actor_id`),
    KEY `tenant_id_2` (`tenant_id`, `status`, `expires_at`),
    CONSTRAINT `offboarding_suggestions_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`),
    CONSTRAINT `offboarding_suggestions_ibfk_2` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`),
    CONSTRAINT `offboarding_suggestions_ibfk_3` FOREIGN KEY (`actor_id`) REFERENCES `app_users` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump permissions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `permissions`;

CREATE TABLE `permissions`
(
    `id`    bigint                                  NOT NULL AUTO_INCREMENT,
    `perm`  varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
    `descr` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `perm` (`perm`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump process_assignments
# ------------------------------------------------------------

DROP TABLE IF EXISTS `process_assignments`;

CREATE TABLE `process_assignments`
(
    `id`         bigint NOT NULL AUTO_INCREMENT,
    `process_id` bigint NOT NULL,
    `fach_id`    bigint NOT NULL,
    `role_id`    bigint NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `process_id` (`process_id`, `fach_id`, `role_id`),
    KEY `pa_fach_term_fk` (`fach_id`),
    KEY `pa_role_term_fk` (`role_id`),
    CONSTRAINT `pa_fach_term_fk` FOREIGN KEY (`fach_id`) REFERENCES `tenant_tax_terms` (`id`),
    CONSTRAINT `pa_role_term_fk` FOREIGN KEY (`role_id`) REFERENCES `tenant_tax_terms` (`id`),
    CONSTRAINT `process_assignments_ibfk_1` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump process_checklists
# ------------------------------------------------------------

DROP TABLE IF EXISTS `process_checklists`;

CREATE TABLE `process_checklists`
(
    `id`          bigint   NOT NULL AUTO_INCREMENT,
    `process_id`  bigint   NOT NULL,
    `template_id` bigint   NOT NULL,
    `selected_by` bigint   NOT NULL,
    `selected_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `process_id` (`process_id`, `template_id`),
    KEY `template_id` (`template_id`),
    KEY `selected_by` (`selected_by`),
    CONSTRAINT `process_checklists_ibfk_1` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`),
    CONSTRAINT `process_checklists_ibfk_2` FOREIGN KEY (`template_id`) REFERENCES `checklist_templates` (`id`),
    CONSTRAINT `process_checklists_ibfk_3` FOREIGN KEY (`selected_by`) REFERENCES `app_users` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump process_credentials
# ------------------------------------------------------------

DROP TABLE IF EXISTS `process_credentials`;

CREATE TABLE `process_credentials`
(
    `id`          bigint                                  NOT NULL AUTO_INCREMENT,
    `process_id`  bigint                                  NOT NULL,
    `field_key`   varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `field_label` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
    `field_kind`  varchar(20) COLLATE utf8mb4_unicode_ci  NOT NULL DEFAULT 'text',
    `value_plain` text COLLATE utf8mb4_unicode_ci         NOT NULL,
    `value_text`  text COLLATE utf8mb4_unicode_ci,
    `created_at`  datetime                                NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_proc_key` (`process_id`, `field_key`),
    KEY `idx_proc` (`process_id`),
    CONSTRAINT `fk_pc_process` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `process_credentials_ibfk_1` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump process_relation_assignments
# ------------------------------------------------------------

DROP TABLE IF EXISTS `process_relation_assignments`;

CREATE TABLE `process_relation_assignments`
(
    `id`            bigint NOT NULL AUTO_INCREMENT,
    `process_id`    bigint NOT NULL,
    `relation_id`   bigint NOT NULL,
    `left_term_id`  bigint NOT NULL,
    `right_term_id` bigint NOT NULL,
    PRIMARY KEY (`id`),
    KEY `relation_id` (`relation_id`),
    KEY `left_term_id` (`left_term_id`),
    KEY `right_term_id` (`right_term_id`),
    KEY `process_id` (`process_id`, `relation_id`),
    CONSTRAINT `process_relation_assignments_ibfk_1` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `process_relation_assignments_ibfk_2` FOREIGN KEY (`relation_id`) REFERENCES `tenant_tax_relations` (`id`),
    CONSTRAINT `process_relation_assignments_ibfk_3` FOREIGN KEY (`left_term_id`) REFERENCES `tenant_tax_terms` (`id`),
    CONSTRAINT `process_relation_assignments_ibfk_4` FOREIGN KEY (`right_term_id`) REFERENCES `tenant_tax_terms` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump process_step_log
# ------------------------------------------------------------

DROP TABLE IF EXISTS `process_step_log`;

CREATE TABLE `process_step_log`
(
    `id`               bigint unsigned                         NOT NULL AUTO_INCREMENT,
    `tenant_id`        bigint unsigned                         NOT NULL,
    `process_id`       bigint unsigned                         NOT NULL,
    `step_id`          bigint unsigned                         NOT NULL,
    `step_label`       varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `executed_by_uid`  bigint unsigned                         NOT NULL,
    `executed_by_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `executed_at`      datetime                                NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_tenant_process` (`tenant_id`, `process_id`),
    KEY `idx_tenant_step` (`tenant_id`, `step_id`),
    KEY `idx_tenant_time` (`tenant_id`, `executed_at`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump process_term_assignments
# ------------------------------------------------------------

DROP TABLE IF EXISTS `process_term_assignments`;

CREATE TABLE `process_term_assignments`
(
    `id`         bigint NOT NULL AUTO_INCREMENT,
    `process_id` bigint NOT NULL,
    `term_id`    bigint NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_process_term` (`process_id`, `term_id`),
    KEY `term_id` (`term_id`),
    KEY `process_id` (`process_id`),
    CONSTRAINT `process_term_assignments_ibfk_1` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `process_term_assignments_ibfk_2` FOREIGN KEY (`term_id`) REFERENCES `tenant_tax_terms` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump processes
# ------------------------------------------------------------

DROP TABLE IF EXISTS `processes`;

CREATE TABLE `processes`
(
    `id`           bigint                                                            NOT NULL AUTO_INCREMENT,
    `tenant_id`    bigint                                                            NOT NULL,
    `employee_id`  bigint                                                            NOT NULL,
    `kind`         enum ('onboarding','offboarding') COLLATE utf8mb4_unicode_ci      NOT NULL,
    `status`       enum ('open','in_progress','archived') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
    `assignee_id`  bigint                                                                     DEFAULT NULL,
    `planned_date` date                                                                       DEFAULT NULL,
    `created_by`   bigint                                                            NOT NULL,
    `created_at`   datetime                                                          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `meta_json`    json                                                              NOT NULL DEFAULT (json_object()),
    PRIMARY KEY (`id`),
    KEY `tenant_id` (`tenant_id`),
    KEY `employee_id` (`employee_id`),
    KEY `created_by` (`created_by`),
    KEY `assignee_id` (`assignee_id`),
    CONSTRAINT `fk_process_assignee` FOREIGN KEY (`assignee_id`) REFERENCES `app_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `processes_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`),
    CONSTRAINT `processes_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`),
    CONSTRAINT `processes_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `app_users` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump role_permissions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `role_permissions`;

CREATE TABLE `role_permissions`
(
    `role_id` bigint                                  NOT NULL,
    `perm`    varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
    PRIMARY KEY (`role_id`, `perm`),
    KEY `fk_rp_perm` (`perm`),
    CONSTRAINT `fk_rp_perm` FOREIGN KEY (`perm`) REFERENCES `permissions` (`perm`) ON DELETE CASCADE,
    CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump roles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `roles`;

CREATE TABLE `roles`
(
    `id`        bigint                                  NOT NULL AUTO_INCREMENT,
    `tenant_id` bigint DEFAULT NULL,
    `name`      varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_role_tenant` (`tenant_id`, `name`),
    CONSTRAINT `fk_roles_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump system_accounts
# ------------------------------------------------------------

DROP TABLE IF EXISTS `system_accounts`;

CREATE TABLE `system_accounts`
(
    `id`          bigint                                                                    NOT NULL AUTO_INCREMENT,
    `employee_id` bigint                                                                    NOT NULL,
    `system_id`   bigint                                                                    NOT NULL,
    `username`    varchar(200) COLLATE utf8mb4_unicode_ci                                            DEFAULT NULL,
    `identifier`  varchar(200) COLLATE utf8mb4_unicode_ci                                            DEFAULT NULL,
    `roles_json`  json                                                                      NOT NULL DEFAULT (json_array()),
    `valid_from`  datetime                                                                           DEFAULT NULL,
    `valid_to`    datetime                                                                           DEFAULT NULL,
    `state`       enum ('pending','active','disabled','deleted') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
    PRIMARY KEY (`id`),
    UNIQUE KEY `employee_id` (`employee_id`, `system_id`),
    KEY `system_id` (`system_id`),
    CONSTRAINT `system_accounts_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`),
    CONSTRAINT `system_accounts_ibfk_2` FOREIGN KEY (`system_id`) REFERENCES `systems` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump system_roles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `system_roles`;

CREATE TABLE `system_roles`
(
    `id`           bigint                                  NOT NULL AUTO_INCREMENT,
    `system_id`    bigint                                  NOT NULL,
    `role_key`     varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `display_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `system_id` (`system_id`, `role_key`),
    CONSTRAINT `system_roles_ibfk_1` FOREIGN KEY (`system_id`) REFERENCES `systems` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump systems
# ------------------------------------------------------------

DROP TABLE IF EXISTS `systems`;

CREATE TABLE `systems`
(
    `id`                bigint                                                    NOT NULL AUTO_INCREMENT,
    `tenant_id`         bigint                                                    NOT NULL,
    `key_name`          varchar(50) COLLATE utf8mb4_unicode_ci                    NOT NULL,
    `display_name`      varchar(100) COLLATE utf8mb4_unicode_ci                   NOT NULL,
    `provisioning_type` enum ('manual','api','script') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
    `config_json`       json                                                      NOT NULL DEFAULT (json_object()),
    PRIMARY KEY (`id`),
    UNIQUE KEY `tenant_id` (`tenant_id`, `key_name`),
    CONSTRAINT `systems_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump task_status_history
# ------------------------------------------------------------

DROP TABLE IF EXISTS `task_status_history`;

CREATE TABLE `task_status_history`
(
    `id`          bigint                                          NOT NULL AUTO_INCREMENT,
    `task_id`     bigint                                          NOT NULL,
    `process_id`  bigint                                          NOT NULL,
    `from_status` enum ('open','done') COLLATE utf8mb4_unicode_ci NOT NULL,
    `to_status`   enum ('open','done') COLLATE utf8mb4_unicode_ci NOT NULL,
    `actor_id`    bigint                                  DEFAULT NULL,
    `actor_name`  varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `changed_at`  datetime                                        NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_task` (`task_id`),
    KEY `idx_proc` (`process_id`),
    KEY `idx_changed` (`changed_at`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tasks
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tasks`;

CREATE TABLE `tasks`
(
    `id`                    bigint                                                                                  NOT NULL AUTO_INCREMENT,
    `process_id`            bigint                                                                                  NOT NULL,
    `system_id`             bigint                                                                                           DEFAULT NULL,
    `parent_task_id`        bigint                                                                                           DEFAULT NULL,
    `title`                 varchar(200) COLLATE utf8mb4_unicode_ci                                                 NOT NULL,
    `description`           text COLLATE utf8mb4_unicode_ci,
    `kind`                  enum ('create','modify','delete','verify','document','todo') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'todo',
    `order_index`           int                                                                                     NOT NULL DEFAULT '0',
    `due_at`                datetime                                                                                         DEFAULT NULL,
    `status`                enum ('open','blocked','done') COLLATE utf8mb4_unicode_ci                               NOT NULL DEFAULT 'open',
    `last_checked_by_id`    bigint                                                                                           DEFAULT NULL,
    `last_checked_by_name`  varchar(200) COLLATE utf8mb4_unicode_ci                                                          DEFAULT NULL,
    `last_checked_at`       datetime                                                                                         DEFAULT NULL,
    `assignee_id`           bigint                                                                                           DEFAULT NULL,
    `result_json`           json                                                                                    NOT NULL DEFAULT (json_object()),
    `completed_at`          datetime                                                                                         DEFAULT NULL,
    `completed_by`          bigint                                                                                           DEFAULT NULL,
    `checklist_item_id`     bigint                                                                                           DEFAULT NULL,
    `checklist_template_id` bigint                                                                                           DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `system_id` (`system_id`),
    KEY `parent_task_id` (`parent_task_id`),
    KEY `assignee_id` (`assignee_id`),
    KEY `completed_by` (`completed_by`),
    KEY `process_id` (`process_id`, `status`, `order_index`),
    CONSTRAINT `tasks_ibfk_1` FOREIGN KEY (`process_id`) REFERENCES `processes` (`id`),
    CONSTRAINT `tasks_ibfk_2` FOREIGN KEY (`system_id`) REFERENCES `systems` (`id`),
    CONSTRAINT `tasks_ibfk_3` FOREIGN KEY (`parent_task_id`) REFERENCES `tasks` (`id`),
    CONSTRAINT `tasks_ibfk_4` FOREIGN KEY (`assignee_id`) REFERENCES `app_users` (`id`),
    CONSTRAINT `tasks_ibfk_5` FOREIGN KEY (`completed_by`) REFERENCES `app_users` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_auth_ad
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_auth_ad`;

CREATE TABLE `tenant_auth_ad`
(
    `id`              bigint                                                                 NOT NULL AUTO_INCREMENT,
    `tenant_id`       bigint                                                                 NOT NULL,
    `ldap_host`       varchar(255) COLLATE utf8mb4_unicode_ci                                NOT NULL,
    `ldap_port`       int                                                                    NOT NULL DEFAULT '636',
    `use_starttls`    tinyint(1)                                                             NOT NULL DEFAULT '0',
    `base_dn`         varchar(500) COLLATE utf8mb4_unicode_ci                                NOT NULL,
    `bind_dn`         varchar(500) COLLATE utf8mb4_unicode_ci                                NOT NULL,
    `bind_password`   varchar(500) COLLATE utf8mb4_unicode_ci                                NOT NULL,
    `login_attribute` enum ('sAMAccountName','userPrincipalName') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sAMAccountName',
    `admin_group_dn`  varchar(500) COLLATE utf8mb4_unicode_ci                                NOT NULL,
    `domain_suffix`   varchar(200) COLLATE utf8mb4_unicode_ci                                         DEFAULT NULL,
    `offboarding_lead_days` int DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `tenant_id` (`tenant_id`),
    CONSTRAINT `tenant_auth_ad_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Globale Auth-Provider, vom Superadmin definiert
DROP TABLE IF EXISTS `auth_providers`;
CREATE TABLE `auth_providers` (
                                  `id` bigint NOT NULL AUTO_INCREMENT,
                                  `provider_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
                                  `label` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
                                  `kind` enum('local','ldap','oidc','saml') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'local',
                                  `config_json` json NOT NULL DEFAULT (json_object()),
                                  `is_enabled_system` tinyint(1) NOT NULL DEFAULT '1',
                                  PRIMARY KEY (`id`),
                                  UNIQUE KEY `uq_provider_key` (`provider_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Zuordnung: welcher Tenant nutzt welchen der globalen Provider?
DROP TABLE IF EXISTS `tenant_auth_providers`;
CREATE TABLE `tenant_auth_providers` (
                                         `id` bigint NOT NULL AUTO_INCREMENT,
                                         `tenant_id` bigint NOT NULL,
                                         `provider_id` bigint NOT NULL,
                                         `is_enabled` tinyint(1) NOT NULL DEFAULT '1',
                                         `position` int NOT NULL DEFAULT '1',
                                         PRIMARY KEY (`id`),
                                         UNIQUE KEY `uq_tenant_provider` (`tenant_id`,`provider_id`),
                                         KEY `fk_tap_provider` (`provider_id`),
                                         CONSTRAINT `fk_tap_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
                                         CONSTRAINT `fk_tap_provider2` FOREIGN KEY (`provider_id`) REFERENCES `auth_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


# Tabellen-Dump tenant_credential_fields
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_credential_fields`;

CREATE TABLE `tenant_credential_fields`
(
    `id`           bigint                                                         NOT NULL AUTO_INCREMENT,
    `tenant_id`    bigint                                                         NOT NULL,
    `key_name`     varchar(100) COLLATE utf8mb4_unicode_ci                        NOT NULL,
    `label`        varchar(200) COLLATE utf8mb4_unicode_ci                        NOT NULL,
    `group_id`     bigint                                                                  DEFAULT NULL,
    `kind`         enum ('username','password','text') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'text',
    `order_index`  int                                                            NOT NULL DEFAULT '0',
    `is_active`    tinyint(1)                                                     NOT NULL DEFAULT '1',
    `readonly`     tinyint(1)                                                     NOT NULL DEFAULT '0',
    `generator_id` bigint                                                                  DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_key` (`tenant_id`, `key_name`),
    KEY `idx_tcf_group` (`group_id`),
    KEY `fk_tcf_generator` (`generator_id`),
    KEY `idx_tcf_group_order` (`group_id`, `order_index`),
    KEY `idx_tcf_tenant_active` (`tenant_id`, `is_active`),
    CONSTRAINT `fk_tcf_generator` FOREIGN KEY (`generator_id`) REFERENCES `tenant_generators` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tcf_group` FOREIGN KEY (`group_id`) REFERENCES `tenant_credential_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `tenant_credential_fields_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_credential_groups
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_credential_groups`;

CREATE TABLE `tenant_credential_groups`
(
    `id`          bigint                                  NOT NULL AUTO_INCREMENT,
    `tenant_id`   bigint                                  NOT NULL,
    `group_key`   varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `label`       varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `sort_order`  int                                     NOT NULL DEFAULT '10',
    `order_index` int                                     NOT NULL DEFAULT '100',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_group` (`tenant_id`, `group_key`),
    CONSTRAINT `tenant_credential_groups_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_generators
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_generators`;

CREATE TABLE `tenant_generators`
(
    `id`          bigint                                                                                                         NOT NULL AUTO_INCREMENT,
    `tenant_id`   bigint                                                                                                         NOT NULL,
    `gen_key`     varchar(100) COLLATE utf8mb4_unicode_ci                                                                        NOT NULL,
    `label`       varchar(200) COLLATE utf8mb4_unicode_ci                                                                        NOT NULL,
    `engine`      enum ('username_from_name','password_template','value_template','email_template') COLLATE utf8mb4_unicode_ci   NOT NULL DEFAULT 'username_from_name',
    `config`      json                                                                                                           NOT NULL,
    `description` text COLLATE utf8mb4_unicode_ci,
    `is_active`   tinyint(1)                                                                                                     NOT NULL DEFAULT '1',
    `order_index` int                                                                                                            NOT NULL DEFAULT '100',
    `updated_at`  timestamp                                                                                                      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_gen` (`tenant_id`, `gen_key`),
    CONSTRAINT `fk_tenant_generators_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_notification_channels
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_notification_channels`;

CREATE TABLE `tenant_notification_channels`
(
    `id`          bigint                                             NOT NULL AUTO_INCREMENT,
    `tenant_id`   bigint                                             NOT NULL,
    `kind`        enum ('mail','webhook') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'mail',
    `name`        varchar(200) COLLATE utf8mb4_unicode_ci            NOT NULL,
    `config_json` text COLLATE utf8mb4_unicode_ci,
    `is_active`   tinyint(1)                                         NOT NULL DEFAULT '1',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_notification_events
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_notification_events`;

CREATE TABLE `tenant_notification_events`
(
    `id`          bigint                                  NOT NULL AUTO_INCREMENT,
    `tenant_id`   bigint                                  NOT NULL,
    `event_key`   varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `label`       varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `description` text COLLATE utf8mb4_unicode_ci,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_event` (`tenant_id`, `event_key`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_notification_rules
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_notification_rules`;

CREATE TABLE `tenant_notification_rules`
(
    `id`         bigint     NOT NULL AUTO_INCREMENT,
    `tenant_id`  bigint     NOT NULL,
    `event_id`   bigint     NOT NULL,
    `channel_id` bigint     NOT NULL,
    `is_active`  tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (`id`),
    KEY `idx_rule_tenant` (`tenant_id`),
    KEY `idx_rule_evt` (`event_id`),
    KEY `idx_rule_chan` (`channel_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_notifications
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_notifications`;

CREATE TABLE `tenant_notifications`
(
    `id`              bigint                                 NOT NULL AUTO_INCREMENT,
    `tenant_id`       bigint                                 NOT NULL,
    `event_key`       varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
    `recipients_json` json                                   NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_event` (`tenant_id`, `event_key`),
    CONSTRAINT `fk_tenant_notifications_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_off_pdf_templates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_off_pdf_templates`;

CREATE TABLE `tenant_off_pdf_templates`
(
    `tenant_id`            bigint unsigned                         NOT NULL,
    `logo_path`            varchar(255) COLLATE utf8mb4_unicode_ci          DEFAULT NULL,
    `header_html`          mediumtext COLLATE utf8mb4_unicode_ci,
    `footer_html`          mediumtext COLLATE utf8mb4_unicode_ci,
    `back_html`            mediumtext COLLATE utf8mb4_unicode_ci,
    `tasks_title`          varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Erledigte Aufgaben',
    `date_format`          varchar(64) COLLATE utf8mb4_unicode_ci  NOT NULL DEFAULT '%d.%m.%Y %H:%i',
    `include_signature`    tinyint(1)                              NOT NULL DEFAULT '1',
    `signature_label`      varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Unterschrift:',
    `signature_date_label` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Datum:',
    `created_at`           timestamp                               NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           timestamp                               NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`tenant_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `tenant_password_policy`;

CREATE TABLE `tenant_password_policy` (
                                          tenant_id BIGINT NOT NULL,
                                          min_length INT NOT NULL DEFAULT 8,
                                          require_upper TINYINT(1) NOT NULL DEFAULT 1,
                                          require_lower TINYINT(1) NOT NULL DEFAULT 1,
                                          require_number TINYINT(1) NOT NULL DEFAULT 1,
                                          require_special TINYINT(1) NOT NULL DEFAULT 0,
                                          updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                          PRIMARY KEY (tenant_id),
                                          CONSTRAINT fk_policy_tenant FOREIGN KEY (tenant_id)
                                              REFERENCES tenants(id) ON DELETE CASCADE
);


# Tabellen-Dump tenant_pdf_templates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_pdf_templates`;

CREATE TABLE `tenant_pdf_templates`
(
    `tenant_id`       bigint   NOT NULL,
    `logo_path`       varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `table_rows_json` json     NOT NULL                       DEFAULT (json_array()),
    `header_html`     mediumtext COLLATE utf8mb4_unicode_ci,
    `footer_html`     mediumtext COLLATE utf8mb4_unicode_ci,
    `back_html`       longtext COLLATE utf8mb4_unicode_ci,
    `updated_at`      datetime NOT NULL                       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`tenant_id`),
    CONSTRAINT `tenant_pdf_templates_fk` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

# Tabellen-Dump tenant_auth_ad_role_map
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_auth_ad_role_map`;
CREATE TABLE tenant_auth_ad_role_map (
    id        BIGINT NOT NULL AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    role_id   BIGINT NOT NULL,
    group_dn  VARCHAR(500) NOT NULL,
    PRIMARY KEY (id),
    KEY tenant_id (tenant_id),
    KEY role_id (role_id),
    CONSTRAINT fk_ad_role_map_tenant
        FOREIGN KEY (tenant_id) REFERENCES tenants(id)
            ON DELETE CASCADE,
    CONSTRAINT fk_ad_role_map_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
            ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



# Tabellen-Dump tenant_roles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_roles`;

CREATE TABLE `tenant_roles`
(
    `id`        int          NOT NULL AUTO_INCREMENT,
    `tenant_id` int          NOT NULL,
    `role_key`  varchar(64)  NOT NULL,
    `label`     varchar(128) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_role` (`tenant_id`, `role_key`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;



# Tabellen-Dump tenant_settings
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_settings`;

CREATE TABLE `tenant_settings`
(
    `tenant_id`     bigint                                  NOT NULL,
    `setting_key`   varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `setting_value` json                                    NOT NULL,
    PRIMARY KEY (`tenant_id`, `setting_key`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_smtp
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_smtp`;

CREATE TABLE `tenant_smtp`
(
    `tenant_id`     bigint                                           NOT NULL,
    `host`          varchar(255) COLLATE utf8mb4_unicode_ci          NOT NULL,
    `port`          int                                              NOT NULL DEFAULT '587',
    `secure`        enum ('','tls','ssl') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'tls',
    `username`      varchar(320) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `password`      varchar(500) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `from_addr`     varchar(320) COLLATE utf8mb4_unicode_ci          NOT NULL,
    `from_name`     varchar(200) COLLATE utf8mb4_unicode_ci          NOT NULL,
    `reply_to_addr` varchar(320) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `reply_to_name` varchar(200) COLLATE utf8mb4_unicode_ci                   DEFAULT NULL,
    `updated_at`    datetime                                         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`tenant_id`),
    CONSTRAINT `tenant_smtp_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_tax_relations
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_tax_relations`;

CREATE TABLE `tenant_tax_relations`
(
    `id`                bigint                                  NOT NULL AUTO_INCREMENT,
    `tenant_id`         bigint                                  NOT NULL,
    `rel_key`           varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `label`             varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `left_taxonomy_id`  bigint                                  NOT NULL,
    `right_taxonomy_id` bigint                                  NOT NULL,
    `hide_left_single`  tinyint(1)                              NOT NULL DEFAULT '0',
    `hide_right_single` tinyint(1)                              NOT NULL DEFAULT '0',
    `is_active`         tinyint(1)                              NOT NULL DEFAULT '1',
    `order_index`       int                                     NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_relkey` (`tenant_id`, `rel_key`),
    KEY `left_taxonomy_id` (`left_taxonomy_id`),
    KEY `right_taxonomy_id` (`right_taxonomy_id`),
    KEY `tenant_id` (`tenant_id`, `is_active`, `order_index`),
    CONSTRAINT `tenant_tax_relations_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`),
    CONSTRAINT `tenant_tax_relations_ibfk_2` FOREIGN KEY (`left_taxonomy_id`) REFERENCES `tenant_taxonomies` (`id`),
    CONSTRAINT `tenant_tax_relations_ibfk_3` FOREIGN KEY (`right_taxonomy_id`) REFERENCES `tenant_taxonomies` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_tax_terms
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_tax_terms`;

CREATE TABLE `tenant_tax_terms`
(
    `id`          bigint                                  NOT NULL AUTO_INCREMENT,
    `taxonomy_id` bigint                                  NOT NULL,
    `term_key`    varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `label`       varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `is_active`   tinyint(1)                              NOT NULL DEFAULT '1',
    `order_index` int                                     NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tax_termkey` (`taxonomy_id`, `term_key`),
    KEY `taxonomy_id` (`taxonomy_id`, `is_active`, `order_index`),
    CONSTRAINT `tenant_tax_terms_ibfk_1` FOREIGN KEY (`taxonomy_id`) REFERENCES `tenant_taxonomies` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_taxonomies
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_taxonomies`;

CREATE TABLE `tenant_taxonomies`
(
    `id`          bigint                                             NOT NULL AUTO_INCREMENT,
    `tenant_id`   bigint                                             NOT NULL,
    `tax_key`     varchar(100) COLLATE utf8mb4_unicode_ci            NOT NULL,
    `label`       varchar(200) COLLATE utf8mb4_unicode_ci            NOT NULL,
    `ui_mode`     enum ('single','multi') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'single',
    `is_active`   tinyint(1)                                         NOT NULL DEFAULT '1',
    `order_index` int                                                NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_taxkey` (`tenant_id`, `tax_key`),
    CONSTRAINT `tenant_taxonomies_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump tenant_wordlist_blobs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_wordlist_blobs`;

CREATE TABLE `tenant_wordlist_blobs`
(
    `wordlist_id` bigint NOT NULL,
    `words_json`  json   NOT NULL,
    PRIMARY KEY (`wordlist_id`),
    CONSTRAINT `fk_wl_blob` FOREIGN KEY (`wordlist_id`) REFERENCES `tenant_wordlists` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;



# Tabellen-Dump tenant_wordlists
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenant_wordlists`;

CREATE TABLE `tenant_wordlists`
(
    `id`         bigint                 NOT NULL AUTO_INCREMENT,
    `tenant_id`  bigint                 NOT NULL,
    `list_key`   varchar(100)           NOT NULL,
    `label`      varchar(200)           NOT NULL,
    `language`   varchar(32)                     DEFAULT NULL,
    `source`     enum ('upload','seed') NOT NULL DEFAULT 'upload',
    `word_count` int                    NOT NULL DEFAULT '0',
    `updated_at` timestamp              NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_tenant_wordlist` (`tenant_id`, `list_key`),
    CONSTRAINT `fk_tenant_wordlists_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;



# Tabellen-Dump tenants
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tenants`;

CREATE TABLE `tenants`
(
    `id`            bigint                                  NOT NULL AUTO_INCREMENT,
    `name`          varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `code`          varchar(50) COLLATE utf8mb4_unicode_ci           DEFAULT NULL,
    `settings_json` json                                    NOT NULL DEFAULT (json_object()),
    PRIMARY KEY (`id`),
    UNIQUE KEY `code` (`code`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump user_prefs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_prefs`;

CREATE TABLE `user_prefs`
(
    `id`         int                                     NOT NULL AUTO_INCREMENT,
    `tenant_id`  int                                     NOT NULL,
    `user_id`    int                                     NOT NULL,
    `pref_key`   varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `value_json` json                                         DEFAULT NULL,
    `updated_at` timestamp                               NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_pref` (`tenant_id`, `user_id`, `pref_key`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump user_remember_tokens
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_remember_tokens`;

CREATE TABLE `user_remember_tokens`
(
    `id`           bigint                              NOT NULL AUTO_INCREMENT,
    `user_id`      bigint                              NOT NULL,
    `tenant_id`    bigint                              NOT NULL,
    `selector`     char(24) COLLATE utf8mb4_unicode_ci NOT NULL,
    `verifier_sha` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
    `user_agent`   char(64) COLLATE utf8mb4_unicode_ci          DEFAULT NULL,
    `ip_addr`      varbinary(16)                                DEFAULT NULL,
    `issued_at`    datetime                            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_used`    datetime                            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at`   datetime                            NOT NULL,
    `rotated_from` bigint                                       DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_selector` (`selector`),
    KEY `idx_user` (`user_id`),
    KEY `fk_rt_tenant` (`tenant_id`),
    CONSTRAINT `fk_rt_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rt_user` FOREIGN KEY (`user_id`) REFERENCES `app_users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump user_roles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_roles`;

CREATE TABLE `user_roles`
(
    `user_id` bigint NOT NULL,
    `role_id` bigint NOT NULL,
    PRIMARY KEY (`user_id`, `role_id`),
    KEY `fk_ur_role` (`role_id`),
    CONSTRAINT `fk_ur_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ur_user` FOREIGN KEY (`user_id`) REFERENCES `app_users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Tabellen-Dump user_settings
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_settings`;

CREATE TABLE `user_settings`
(
    `tenant_id`     bigint                                  NOT NULL,
    `user_id`       bigint                                  NOT NULL DEFAULT '0',
    `username`      varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
    `setting_key`   varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `setting_value` json                                    NOT NULL,
    PRIMARY KEY (`tenant_id`, `user_id`, `username`, `setting_key`),
    KEY `idx_user_settings_user` (`tenant_id`, `user_id`, `username`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;



# Dump of view v_tenant_off_pdf_templates_effective
# ------------------------------------------------------------

DROP TABLE IF EXISTS `v_tenant_off_pdf_templates_effective`;
DROP VIEW IF EXISTS `v_tenant_off_pdf_templates_effective`;

CREATE ALGORITHM = UNDEFINED DEFINER =`adam`@`%` SQL SECURITY DEFINER VIEW `v_tenant_off_pdf_templates_effective`
AS
SELECT `off`.`tenant_id`            AS `tenant_id`,
       coalesce(`off`.`logo_path`,
                `onb`.`logo_path`)  AS `effective_logo_path`,
       `off`.`header_html`          AS `header_html`,
       `off`.`footer_html`          AS `footer_html`,
       `off`.`back_html`            AS `back_html`,
       `off`.`tasks_title`          AS `tasks_title`,
       `off`.`date_format`          AS `date_format`,
       `off`.`include_signature`    AS `include_signature`,
       `off`.`signature_label`      AS `signature_label`,
       `off`.`signature_date_label` AS `signature_date_label`,
       `off`.`created_at`           AS `created_at`,
       `off`.`updated_at`           AS `updated_at`
FROM (`tenant_off_pdf_templates` `off`
         left join `tenant_pdf_templates` `onb` on ((`onb`.`tenant_id` = `off`.`tenant_id`)));

CREATE TABLE auth_throttle (
                               id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               username VARCHAR(150) NOT NULL,
                               tenant_id INT NOT NULL DEFAULT 0,
                               ip_addr VARCHAR(45) NOT NULL,
                               attempts INT NOT NULL DEFAULT 0,
                               last_attempt DATETIME NOT NULL,
                               locked_until DATETIME DEFAULT NULL,
                               PRIMARY KEY (id),
                               KEY idx_user_tenant_ip (username, tenant_id, ip_addr)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


/*!40111 SET SQL_NOTES = @OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE = @OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT = @OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS = @OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION = @OLD_COLLATION_CONNECTION */;

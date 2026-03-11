-- 20-seed.sql
-- Basis-Seed-Daten für eine frische NovoBoard/eOnBoard-Instanz.

-- 1. Rollen
-- superadmin  = globale Rolle ohne Mandant (tenant_id NULL)
-- admin       = ebenfalls global, aber später darf ein Tenant sich davon eine Kopie anlegen
INSERT INTO roles (id, tenant_id, name)
VALUES
    (1, NULL, 'superadmin'),
    (2, NULL, 'admin')
ON DUPLICATE KEY UPDATE
                     tenant_id = VALUES(tenant_id),
                     name      = VALUES(name);

-- 2. Permissions
INSERT INTO permissions (perm, descr) VALUES
                                          ('tenants.manage',        'Mandanten verwalten'),
                                          ('users.manage',          'Benutzer & Rollen verwalten'),
                                          ('templates.manage',      'Checklisten-Vorlagen verwalten'),
                                          ('process.create',        'Prozesse anlegen'),
                                          ('process.update',        'Prozesse bearbeiten'),
                                          ('process.delete',        'Prozesse löschen'),
                                          ('process.view',          'Prozesse ansehen'),
                                          ('archive.view',          'Archiv einsehen'),
                                          ('suggestions.manage',    'Offboarding-Vorschläge bearbeiten')
ON DUPLICATE KEY UPDATE
    descr = VALUES(descr);

-- 3. Rollenberechtigungen
INSERT INTO role_permissions (role_id, perm) VALUES
                                                 -- superadmin bekommt alles
                                                 (1, 'tenants.manage'),
                                                 (1, 'users.manage'),
                                                 (1, 'templates.manage'),
                                                 (1, 'process.create'),
                                                 (1, 'process.update'),
                                                 (1, 'process.delete'),
                                                 (1, 'process.view'),
                                                 (1, 'archive.view'),
                                                 (1, 'suggestions.manage'),

                                                 -- admin (globales Basis-Profil)
                                                 (2, 'users.manage'),
                                                 (2, 'process.create'),
                                                 (2, 'process.update'),
                                                 (2, 'process.delete'),
                                                 (2, 'process.view'),
                                                 (2, 'archive.view'),
                                                 (2, 'suggestions.manage')
ON DUPLICATE KEY UPDATE
    perm = VALUES(perm);

-- 4. Globale Auth-Provider anlegen (OHNE tenant_id!)
INSERT INTO auth_providers (provider_key, label, kind, config_json, is_enabled_system)
VALUES
    ('local', 'Lokale Benutzerkonten', 'local', JSON_OBJECT(), 1),
    ('ldap',  'LDAP / Active Directory', 'ldap', JSON_OBJECT(), 1)
ON DUPLICATE KEY UPDATE
                     label             = VALUES(label),
                     kind              = VALUES(kind),
                     config_json       = VALUES(config_json),
                     is_enabled_system = VALUES(is_enabled_system);

-- 5. Tenant-spezifische Notification-Events nur anlegen, wenn es Tenants gibt.
INSERT INTO tenant_notification_events (tenant_id, event_key, label, description)
SELECT t.id,
       'offboarding_suggestion' AS event_key,
       'LDAP-Scan: Offboarding-Vorschlag' AS label,
       'Erzeugt durch den periodischen LDAP-Scan, wenn ein Offboarding sinnvoll sein könnte.' AS description
FROM tenants t
WHERE NOT EXISTS (
        SELECT 1
        FROM tenant_notification_events e
        WHERE e.tenant_id = t.id
          AND e.event_key = 'offboarding_suggestion'
    );

-- Healthcheck
SELECT '✅ NovoBoard Schema ready (global auth providers)' AS status;
SELECT COUNT(*) AS users_in_app_users FROM app_users;
